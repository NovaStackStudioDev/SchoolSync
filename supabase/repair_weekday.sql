-- Repair legacy INTEGER weekdays without changing the column type or existing data.
-- Run once in your Supabase SQL Editor; restart the updated Flutter app.
begin;
create or replace function public.school_weekday_number(raw text) returns integer language plpgsql immutable strict set search_path=public,pg_temp as $$
declare n integer; cleaned text:=lower(trim(raw));
begin
  if cleaned ~ '^[0-7]$' then n:=cleaned::integer; return case when n=0 then 7 else n end; end if;
  n:=array_position(array['monday','tuesday','wednesday','thursday','friday','saturday','sunday'],cleaned);
  if n is null then raise exception 'Invalid school weekday: %. Expected Monday-Sunday or 1-7.',raw using errcode='22023'; end if;
  return n;
end $$;

create or replace function public.effective_timetable(sid uuid, target_date date) returns setof public.timetables language sql stable security definer set search_path=public,pg_temp as $$
  select * from public.timetables where school_id=sid and not is_archived and public.school_weekday_number(weekday::text)=extract(isodow from target_date)::int and valid_from<=target_date and (valid_to is null or valid_to>=target_date)
$$;

create or replace function public.save_timetable_slot(slot jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); tid uuid:=(slot->>'teacher_id')::uuid; cid uuid:=(slot->>'class_id')::uuid;
  pid uuid:=(slot->>'period_id')::uuid; subid uuid:=(slot->>'subject_id')::uuid; target_id uuid:=nullif(slot->>'id','')::uuid;
  day public.timetables.weekday%type; day_number integer; p public.periods; original public.timetables; tail_id uuid;
  starts date:=coalesce((slot->>'effective_date')::date,(now() at time zone 'Asia/Colombo')::date);
  ends date; once boolean:=coalesce((slot->>'date_only')::boolean,false); removing boolean:=coalesce((slot->>'remove')::boolean,false);
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(sid::text,0));
  if once then ends:=starts; end if;
  if target_id is not null then
    select * into original from public.timetables where id=target_id and school_id=sid and not is_archived for update;
    if original.id is null or starts<original.valid_from or starts>coalesce(original.valid_to,'infinity'::date) then raise exception 'Entry is not active on the effective date. Refresh the timetable.'; end if;
    if once and public.school_weekday_number(original.weekday::text)<>extract(isodow from starts)::int then raise exception 'Choose the date for this weekday'; end if;
    if not once then ends:=original.valid_to; end if;
    if exists(select 1 from public.replacement_assignments where timetable_id=original.id and status::text='assigned' and assignment_date>=starts and assignment_date<=coalesce(ends,'infinity'::date)) then raise exception 'Cancel affected cover assignments before changing this timetable'; end if;
    if original.valid_from<starts then
      update public.timetables set valid_to=starts-1 where id=original.id;
      if once and coalesce(original.valid_to,'infinity'::date)>starts then
        insert into public.timetables(school_id,teacher_id,class_id,subject_id,period_id,weekday,valid_from,valid_to,source_upload_id)
          values(sid,original.teacher_id,original.class_id,original.subject_id,original.period_id,original.weekday,starts+1,original.valid_to,original.source_upload_id) returning id into tail_id;
        update public.replacement_assignments set timetable_id=tail_id where timetable_id=original.id and assignment_date>starts;
      end if;
    elsif once and coalesce(original.valid_to,'infinity'::date)>starts then
      update public.timetables set valid_from=starts+1 where id=original.id;
    else
      update public.timetables set is_archived=true where id=original.id;
    end if;
  end if;
  if removing then
    if target_id is null then raise exception 'Choose an existing entry to remove'; end if;
    return;
  end if;
  day_number:=public.school_weekday_number(slot->>'weekday');
  if day_number is null then raise exception 'Invalid weekday'; end if;
  if pg_typeof(day)::text in ('smallint','integer','bigint') then day:=day_number::text;
  else day:=(array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'])[day_number]; end if;
  if once and day_number<>extract(isodow from starts)::int then raise exception 'Weekday must match the selected date'; end if;
  if not exists(select 1 from public.teachers t join public.profiles pr on pr.id=t.profile_id where t.id=tid and t.school_id=sid and pr.is_active)
    or not exists(select 1 from public.school_classes where id=cid and school_id=sid)
    or not exists(select 1 from public.subjects where id=subid and school_id=sid) then raise exception 'Teacher, class or subject is invalid'; end if;
  select * into p from public.periods where id=pid and school_id=sid;
  if p.id is null then raise exception 'Period not found'; end if;
  if exists(select 1 from public.timetables t join public.periods pp on pp.id=t.period_id where t.school_id=sid and not t.is_archived and public.school_weekday_number(t.weekday::text)=day_number
    and t.valid_from<=coalesce(ends,'infinity'::date) and coalesce(t.valid_to,'infinity'::date)>=starts
    and (t.teacher_id=tid or t.class_id=cid) and pp.start_time<p.end_time and pp.end_time>p.start_time) then raise exception 'Teacher or class has an overlapping timetable entry'; end if;
  if exists(select 1 from public.replacement_assignments r join public.timetables t on t.id=r.timetable_id join public.periods pp on pp.id=t.period_id
    where r.replacement_teacher_id=tid and r.status::text='assigned' and public.school_weekday_number(t.weekday::text)=day_number and r.assignment_date>=starts and r.assignment_date<=coalesce(ends,'infinity'::date)
    and pp.start_time<p.end_time and pp.end_time>p.start_time) then raise exception 'Teacher already has a cover assignment during this time'; end if;
  if slot->>'source_upload_id' is not null and not exists(select 1 from public.timetable_uploads where id=(slot->>'source_upload_id')::uuid and school_id=sid and teacher_id=tid) then raise exception 'Invalid timetable source file'; end if;
  insert into public.timetables(school_id,teacher_id,class_id,subject_id,period_id,weekday,valid_from,valid_to,source_upload_id)
    values(sid,tid,cid,subid,pid,day,starts,ends,(slot->>'source_upload_id')::uuid);
  insert into public.audit_logs(school_id,actor_id,action,details) values(sid,auth.uid(),'timetable_updated',coalesce(target_id::text,'new entry')||' from '||starts);
end $$;

create or replace function public.assign_replacement(target_slot uuid,cover_teacher uuid,target_date date) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); slot public.timetables; p public.periods; recipient uuid;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(sid::text,0));
  select * into slot from public.effective_timetable(sid,target_date) where id=target_slot;
  if slot.id is null or extract(isodow from target_date)::int<>public.school_weekday_number(slot.weekday::text) then raise exception 'Timetable date does not match'; end if;
  if not public.school_working_day(sid,target_date) then raise exception 'School is closed'; end if;
  if not exists(select 1 from public.attendance where teacher_id=slot.teacher_id and attendance_date=target_date and status::text in ('absent','leave')) then raise exception 'Original teacher is not marked absent or on leave'; end if;
  select t.profile_id into recipient from public.teachers t join public.profiles pr on pr.id=t.profile_id where t.id=cover_teacher and t.school_id=sid and pr.is_active;
  if recipient is null or cover_teacher=slot.teacher_id then raise exception 'Invalid replacement teacher'; end if;
  if not exists(select 1 from public.attendance where teacher_id=cover_teacher and attendance_date=target_date and status::text in ('present','late'))
    or exists(select 1 from public.leave_requests where teacher_id=cover_teacher and status::text='approved' and target_date between start_date and end_date) then raise exception 'Replacement teacher must be present and not on leave'; end if;
  select * into p from public.periods where id=slot.period_id;
  if not exists(select 1 from public.replacement_candidates(target_slot,target_date) where teacher_id=cover_teacher) then raise exception 'Replacement teacher is busy during this period'; end if;
  if exists(select 1 from public.replacement_assignments where timetable_id=slot.id and assignment_date=target_date and status::text='assigned') then raise exception 'This period already has a replacement'; end if;
  insert into public.replacement_assignments(school_id,absent_teacher_id,replacement_teacher_id,timetable_id,assignment_date,status) values(sid,slot.teacher_id,cover_teacher,slot.id,target_date,'assigned')
    on conflict(timetable_id,assignment_date) do update set replacement_teacher_id=excluded.replacement_teacher_id,status='assigned';
  insert into public.notifications(school_id,recipient_id,title,message,kind) values(sid,recipient,'Class Replacement Assigned','You have a cover assignment on '||target_date||', period '||p.period_number||'.','replacement');
  insert into public.audit_logs(school_id,actor_id,action,details) values(sid,auth.uid(),'replacement_assigned',slot.id||' -> '||cover_teacher);
end $$;

create or replace function public.publish_teacher_timetable(upload_id uuid,entries jsonb,effective_date date,date_only boolean) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); u public.timetable_uploads; s record; e jsonb;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(sid::text,0));
  select * into u from public.timetable_uploads where id=upload_id and school_id=sid for update;
  if u.id is null then raise exception 'Source file not found'; end if;
  if effective_date is null or jsonb_typeof(entries)<>'array' or jsonb_array_length(entries)=0 or jsonb_array_length(entries)>100 then raise exception 'Confirm 1 to 100 periods before publishing'; end if;
  if not date_only then
    for s in select * from public.timetables where teacher_id=u.teacher_id and school_id=sid and not is_archived and valid_from>effective_date loop
      perform public.save_timetable_slot(jsonb_build_object('id',s.id,'effective_date',s.valid_from,'date_only',false,'remove',true));
    end loop;
  end if;
  -- A publish replaces this teacher's active timetable only, in one transaction.
  for s in select * from public.timetables where school_id=sid and teacher_id=u.teacher_id and not is_archived
      and valid_from<=effective_date and coalesce(valid_to,'infinity'::date)>=effective_date
      and (not date_only or public.school_weekday_number(weekday::text)=extract(isodow from effective_date)::int) loop
    perform public.save_timetable_slot(jsonb_build_object('id',s.id,'effective_date',effective_date,'date_only',date_only,'remove',true));
  end loop;
  for e in select * from jsonb_array_elements(entries) loop
    perform public.save_timetable_slot(jsonb_build_object('weekday',e->>'weekday','class_id',e->>'class_id','subject_id',e->>'subject_id','period_id',e->>'period_id',
      'teacher_id',u.teacher_id,'effective_date',effective_date,'date_only',date_only,'source_upload_id',u.id));
  end loop;
  update public.timetable_uploads set status='published',proposed_entries=entries,effective_date=publish_teacher_timetable.effective_date,date_only=publish_teacher_timetable.date_only where id=u.id;
end $$;

create or replace function public.submit_timetable_document(upload_id uuid,entries jsonb,effective_date date,date_only boolean) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); u public.timetable_uploads; e jsonb;
begin
  select * into u from public.timetable_uploads where id=upload_id and school_id=sid for update;
  if u.id is null or (not public.is_principal() and u.teacher_id is distinct from public.my_teacher_id()) then raise exception 'Timetable access denied'; end if;
  if u.status='published' then raise exception 'Choose a revised Photo/PDF to submit a new version'; end if;
  if effective_date is null or jsonb_typeof(entries)<>'array' or jsonb_array_length(entries)=0 or jsonb_array_length(entries)>100 then raise exception 'Confirm 1 to 100 periods'; end if;
  for e in select * from jsonb_array_elements(entries) loop
    if not exists(select 1 from public.school_classes where id=(e->>'class_id')::uuid and school_id=sid)
      or not exists(select 1 from public.subjects where id=(e->>'subject_id')::uuid and school_id=sid)
      or not exists(select 1 from public.periods where id=(e->>'period_id')::uuid and school_id=sid) then raise exception 'Invalid class, subject or period'; end if;
    if public.school_weekday_number(e->>'weekday') is null or (date_only and public.school_weekday_number(e->>'weekday')<>extract(isodow from effective_date)::int) then raise exception 'Check the timetable weekday and effective date'; end if;
  end loop;
  update public.timetable_uploads set proposed_entries=entries,effective_date=submit_timetable_document.effective_date,date_only=submit_timetable_document.date_only,submitted_at=now() where id=u.id;
  insert into public.notifications(school_id,recipient_id,title,message,kind) select sid,id,'Timetable Submitted','A teacher submitted an updated timetable for review.','timetable' from public.profiles where school_id=sid and role::text='principal' and is_active;
end $$;

do $$ declare f record; begin
  for f in select p.oid::regprocedure signature,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('school_weekday_number','effective_timetable','save_timetable_slot','assign_replacement','publish_teacher_timetable','submit_timetable_document') loop
    execute format('revoke all on function %s from public,anon,authenticated',f.signature);
    execute format('grant execute on function %s to service_role',f.signature);
    if f.proname<>'effective_timetable' then execute format('grant execute on function %s to authenticated',f.signature); end if;
  end loop;
end $$;
notify pgrst, 'reload schema';
commit;
