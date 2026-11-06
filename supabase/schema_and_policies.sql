-- SchoolSync schema and server-side actions. Run in the Supabase SQL editor.
-- Preserves existing records. Creates no demo teachers, students, periods or classes.
begin;
create extension if not exists pgcrypto;

create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(), name text not null,
  timezone text not null default 'Asia/Colombo', attendance_cutoff time not null default '07:30'
);
alter table public.schools add column if not exists attendance_cutoff time not null default '07:30';
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  school_id uuid not null references public.schools(id), full_name text not null,
  role text not null check (role in ('principal','teacher')), is_active boolean not null default false
);
create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  employee_number text not null, phone text, unique(school_id,employee_number)
);
create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  name text not null, unique(school_id,name)
);
create table if not exists public.teacher_subjects (
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade, primary key(teacher_id,subject_id)
);
create table if not exists public.school_classes (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  name text not null, unique(school_id,name)
);
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  class_id uuid not null references public.school_classes(id), full_name text not null check (length(trim(full_name)) > 0),
  admission_number text not null check (length(trim(admission_number)) > 0), is_active boolean not null default true,
  unique(school_id,admission_number)
);
create table if not exists public.periods (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  period_number integer not null check(period_number > 0), start_time time not null, end_time time not null,
  check(end_time > start_time), unique(school_id,period_number)
);
create table if not exists public.timetables (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  teacher_id uuid not null references public.teachers(id), class_id uuid not null references public.school_classes(id),
  subject_id uuid not null references public.subjects(id), period_id uuid not null references public.periods(id),
  weekday text not null check(weekday in ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')),
  unique(teacher_id,weekday,period_id), unique(class_id,weekday,period_id)
);
create table if not exists public.school_calendar (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  calendar_date date not null, is_working_day boolean not null, description text, unique(school_id,calendar_date)
);
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  teacher_id uuid not null references public.teachers(id), attendance_date date not null,
  status text not null check(status in ('present','late','absent','leave','pending')), marked_at timestamptz,
  note text, unique(teacher_id,attendance_date)
);
create table if not exists public.student_attendance (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  class_id uuid not null references public.school_classes(id), student_id uuid not null references public.students(id),
  attendance_date date not null, status text not null check(status in ('present','absent','late')),
  marked_by uuid not null references public.profiles(id), marked_at timestamptz not null default now(), unique(student_id,attendance_date)
);
create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  teacher_id uuid not null references public.teachers(id), start_date date not null, end_date date not null,
  reason text not null, status text not null default 'pending' check(status in ('pending','approved','rejected')),
  rejection_reason text, reviewed_by uuid references public.profiles(id), reviewed_at timestamptz,
  created_at timestamptz not null default now(), check(end_date >= start_date)
);
create table if not exists public.replacement_assignments (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  absent_teacher_id uuid not null references public.teachers(id), replacement_teacher_id uuid not null references public.teachers(id),
  timetable_id uuid not null references public.timetables(id), assignment_date date not null,
  status text not null default 'assigned', unique(timetable_id,assignment_date)
);
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), school_id uuid references public.schools(id),
  recipient_id uuid references public.profiles(id), title text not null, message text not null,
  is_read boolean not null default false, kind text not null default 'general', created_at timestamptz not null default now()
);
alter table public.notifications add column if not exists school_id uuid references public.schools(id);
alter table public.notifications add column if not exists recipient_id uuid references public.profiles(id);
alter table public.notifications add column if not exists kind text not null default 'general';
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id),
  actor_id uuid references public.profiles(id), action text not null, details text, created_at timestamptz not null default now()
);

-- This is the real school configured in this application's existing branding.
insert into public.schools(name,timezone,attendance_cutoff)
select 'Kahatagasdigiliya Central College','Asia/Colombo','07:30'
where not exists(select 1 from public.schools where name='Kahatagasdigiliya Central College');

create or replace function public.current_school_id() returns uuid language sql stable security definer set search_path=public,pg_temp as $$
  select school_id from public.profiles where id=auth.uid() and is_active=true
$$;
create or replace function public.is_principal() returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists(select 1 from public.profiles where id=auth.uid() and is_active=true and role::text='principal')
$$;
create or replace function public.my_teacher_id() returns uuid language sql stable security definer set search_path=public,pg_temp as $$
  select id from public.teachers where profile_id=auth.uid() and school_id=public.current_school_id()
$$;
create or replace function public.can_manage_class(target_class uuid) returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists(select 1 from public.school_classes c where c.id=target_class and c.school_id=public.current_school_id()
    and (public.is_principal() or exists(select 1 from public.timetables t where t.class_id=c.id and t.teacher_id=public.my_teacher_id())))
$$;
create or replace function public.school_working_day(sid uuid, day date) returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select coalesce((select is_working_day from public.school_calendar where school_id=sid and calendar_date=day), extract(isodow from day)<6)
$$;

-- Replace the previous permissive application policies. Existing data is retained.
do $$ declare t text; p record; begin
  foreach t in array array['schools','profiles','teachers','subjects','teacher_subjects','school_classes','students','periods','timetables','school_calendar','attendance','student_attendance','leave_requests','replacement_assignments','notifications','audit_logs'] loop
    execute format('alter table public.%I enable row level security', t);
    for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
      execute format('drop policy %I on public.%I',p.policyname,t);
    end loop;
    execute format('grant select on public.%I to authenticated',t);
  end loop;
end $$;
create policy schools_read on public.schools for select to authenticated using(id=public.current_school_id());
create policy schools_update on public.schools for update to authenticated using(id=public.current_school_id() and public.is_principal()) with check(id=public.current_school_id() and public.is_principal());
grant update(name,attendance_cutoff) on public.schools to authenticated;
create policy profiles_read on public.profiles for select to authenticated using(id=auth.uid() or school_id=public.current_school_id());
create policy teachers_read on public.teachers for select to authenticated using(school_id=public.current_school_id());
create policy subjects_read on public.subjects for select to authenticated using(school_id=public.current_school_id());
create policy teacher_subjects_read on public.teacher_subjects for select to authenticated using(exists(select 1 from public.teachers t where t.id=teacher_id and t.school_id=public.current_school_id()));
create policy classes_read on public.school_classes for select to authenticated using(school_id=public.current_school_id());
create policy students_read on public.students for select to authenticated using(school_id=public.current_school_id() and public.can_manage_class(class_id));
create policy periods_read on public.periods for select to authenticated using(school_id=public.current_school_id());
create policy timetable_read on public.timetables for select to authenticated using(school_id=public.current_school_id());
create policy calendar_read on public.school_calendar for select to authenticated using(school_id=public.current_school_id());
create policy attendance_read on public.attendance for select to authenticated using(school_id=public.current_school_id());
create policy student_attendance_read on public.student_attendance for select to authenticated using(school_id=public.current_school_id() and public.can_manage_class(class_id));
create policy leave_read on public.leave_requests for select to authenticated using(school_id=public.current_school_id() and (public.is_principal() or teacher_id=public.my_teacher_id()));
create policy replacements_read on public.replacement_assignments for select to authenticated using(school_id=public.current_school_id());
create policy notifications_read on public.notifications for select to authenticated using(school_id=public.current_school_id() and recipient_id=auth.uid());
create policy notifications_update on public.notifications for update to authenticated using(school_id=public.current_school_id() and recipient_id=auth.uid()) with check(school_id=public.current_school_id() and recipient_id=auth.uid());
grant update(is_read) on public.notifications to authenticated;
create policy audit_read on public.audit_logs for select to authenticated using(school_id=public.current_school_id() and public.is_principal());
do $$ declare t text; begin
  foreach t in array array['subjects','school_classes','students','periods','school_calendar'] loop
    execute format('create policy principal_insert on public.%I for insert to authenticated with check(school_id=public.current_school_id() and public.is_principal())',t);
    execute format('create policy principal_update on public.%I for update to authenticated using(school_id=public.current_school_id() and public.is_principal()) with check(school_id=public.current_school_id() and public.is_principal())',t);
    execute format('grant insert,update on public.%I to authenticated',t);
  end loop;
end $$;

-- Validate relations even when records are written through the REST API.
create or replace function public.validate_student_class() returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
  if not exists(select 1 from public.school_classes where id=new.class_id and school_id=new.school_id) then raise exception 'Class belongs to a different school'; end if;
  return new;
end $$;
drop trigger if exists validate_student_class on public.students;
create trigger validate_student_class before insert or update on public.students for each row execute function public.validate_student_class();

-- Provisioning is idempotent and cannot create a principal. A principal activates new staff.
create or replace function public.provision_teacher() returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare u auth.users; sid uuid; tid uuid; subject_name text; subid uuid; emp text;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  if exists(select 1 from public.profiles where id=auth.uid()) then return; end if;
  select * into u from auth.users where id=auth.uid();
  if coalesce(u.raw_user_meta_data->>'role','') <> 'teacher' then return; end if;
  select id into sid from public.schools where name='Kahatagasdigiliya Central College' order by id limit 1;
  if sid is null then raise exception 'School is not configured'; end if;
  emp := coalesce(nullif(trim(u.raw_user_meta_data->>'employee_number'),''),'T-'||upper(left(u.id::text,8)));
  insert into public.profiles(id,school_id,full_name,role,is_active) values(u.id,sid,coalesce(nullif(trim(u.raw_user_meta_data->>'full_name'),''),'Teacher'),'teacher',false);
  insert into public.teachers(profile_id,school_id,employee_number,phone) values(u.id,sid,emp,u.raw_user_meta_data->>'phone') returning id into tid;
  if jsonb_typeof(u.raw_user_meta_data->'subjects')='array' then
    for subject_name in select jsonb_array_elements_text(u.raw_user_meta_data->'subjects') loop
      select id into subid from public.subjects where school_id=sid and name=subject_name limit 1;
      if subid is not null then insert into public.teacher_subjects values(tid,subid) on conflict do nothing; end if;
    end loop;
  end if;
end $$;

create or replace function public.update_my_profile(new_name text) returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if public.current_school_id() is null or length(trim(new_name))=0 then raise exception 'An active account and name are required'; end if;
  update public.profiles set full_name=trim(new_name) where id=auth.uid();
end $$;

create or replace function public.update_teacher(target_teacher uuid, teacher_values jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); t public.teachers; subject_name text; subid uuid;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  select * into t from public.teachers where id=target_teacher and school_id=sid for update;
  if t.id is null then raise exception 'Teacher not found'; end if;
  if length(trim(teacher_values->>'full_name'))=0 or length(trim(teacher_values->>'employee_number'))=0 then raise exception 'Name and employee number are required'; end if;
  update public.profiles set full_name=trim(teacher_values->>'full_name'),is_active=(teacher_values->>'is_active')::boolean where id=t.profile_id;
  update public.teachers set employee_number=trim(teacher_values->>'employee_number'),phone=teacher_values->>'phone' where id=t.id;
  delete from public.teacher_subjects where teacher_id=t.id;
  for subject_name in select distinct trim(value) from jsonb_array_elements_text(teacher_values->'subjects') where length(trim(value))>0 loop
    select id into subid from public.subjects where school_id=sid and name=subject_name limit 1;
    if subid is null then insert into public.subjects(school_id,name) values(sid,subject_name) returning id into subid; end if;
    insert into public.teacher_subjects(teacher_id,subject_id) values(t.id,subid);
  end loop;
end $$;

-- Called only from the privileged Edge Function after caller authorization.
create or replace function public.create_teacher_record(user_id uuid, sid uuid, teacher_values jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare tid uuid; subject_name text; subid uuid;
begin
  insert into public.profiles(id,school_id,full_name,role,is_active) values(user_id,sid,teacher_values->>'full_name','teacher',true);
  insert into public.teachers(school_id,profile_id,employee_number,phone) values(sid,user_id,teacher_values->>'employee_number',teacher_values->>'phone') returning id into tid;
  for subject_name in select distinct trim(value) from jsonb_array_elements_text(teacher_values->'subjects') where length(trim(value))>0 loop
    select id into subid from public.subjects where school_id=sid and name=subject_name limit 1;
    if subid is null then insert into public.subjects(school_id,name) values(sid,subject_name) returning id into subid; end if;
    insert into public.teacher_subjects(teacher_id,subject_id) values(tid,subid);
  end loop;
end $$;

create or replace function public.check_in() returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); tid uuid:=public.my_teacher_id(); local_now timestamp; cutoff time; st public.attendance.status%type;
begin
  if tid is null then raise exception 'Active teacher account required'; end if;
  select now() at time zone timezone,attendance_cutoff into local_now,cutoff from public.schools where id=sid;
  if not public.school_working_day(sid,local_now::date) then raise exception 'School is closed on this date'; end if;
  if exists(select 1 from public.leave_requests where teacher_id=tid and status::text='approved' and local_now::date between start_date and end_date) then raise exception 'You are on approved leave'; end if;
  st := case when local_now::time<=cutoff then 'present' else 'late' end;
  insert into public.attendance(school_id,teacher_id,attendance_date,status,marked_at)
    values(sid,tid,local_now::date,st,now()) on conflict(teacher_id,attendance_date) do nothing;
  if not found then raise exception 'Attendance is already recorded'; end if;
end $$;

create or replace function public.set_teacher_attendance(target_teacher uuid,target_date date,new_status text) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); st public.attendance.status%type;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  if new_status not in ('present','late','absent','leave') then raise exception 'Invalid attendance status'; end if;
  if target_date>(now() at time zone 'Asia/Colombo')::date then raise exception 'Cannot mark future attendance'; end if;
  if not exists(select 1 from public.teachers where id=target_teacher and school_id=sid) then raise exception 'Teacher not found'; end if;
  st := new_status;
  insert into public.attendance(school_id,teacher_id,attendance_date,status,marked_at) values(sid,target_teacher,target_date,st,now())
    on conflict(teacher_id,attendance_date) do update set status=excluded.status,marked_at=excluded.marked_at;
  insert into public.audit_logs(school_id,actor_id,action,details) values(sid,auth.uid(),'attendance_updated',target_teacher||' '||target_date||' '||new_status);
end $$;

create or replace function public.save_student_attendance(target_class uuid,target_date date,marks jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); m jsonb;
begin
  if not public.can_manage_class(target_class) then raise exception 'Class access denied'; end if;
  if target_date>(now() at time zone 'Asia/Colombo')::date then raise exception 'Cannot mark future attendance'; end if;
  if jsonb_typeof(marks)<>'array' or jsonb_array_length(marks)=0 then raise exception 'No attendance marks'; end if;
  for m in select * from jsonb_array_elements(marks) loop
    if (m->>'status') not in ('present','absent','late') then raise exception 'Invalid status'; end if;
    if not exists(select 1 from public.students where id=(m->>'student_id')::uuid and school_id=sid and class_id=target_class and is_active) then raise exception 'Student is not active in this class'; end if;
    insert into public.student_attendance(school_id,class_id,student_id,attendance_date,status,marked_by,marked_at)
      values(sid,target_class,(m->>'student_id')::uuid,target_date,m->>'status',auth.uid(),now())
      on conflict(student_id,attendance_date) do update set class_id=excluded.class_id,status=excluded.status,marked_by=excluded.marked_by,marked_at=now();
  end loop;
end $$;

create or replace function public.request_leave(start_day date,end_day date,leave_reason text) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); tid uuid:=public.my_teacher_id();
begin
  if tid is null then raise exception 'Active teacher account required'; end if;
  if end_day<start_day or start_day<(now() at time zone 'Asia/Colombo')::date or length(trim(leave_reason))=0 then raise exception 'Valid future dates and a reason are required'; end if;
  perform 1 from public.teachers where id=tid for update;
  if exists(select 1 from public.leave_requests where teacher_id=tid and status::text in ('pending','approved') and start_date<=end_day and end_date>=start_day) then raise exception 'An overlapping leave request already exists'; end if;
  insert into public.leave_requests(school_id,teacher_id,start_date,end_date,reason,status) values(sid,tid,start_day,end_day,trim(leave_reason),'pending');
  insert into public.notifications(school_id,recipient_id,title,message,kind)
    select sid,id,'New Leave Request',(select full_name from public.profiles where id=auth.uid())||' requested leave for '||start_day||' to '||end_day,'leave' from public.profiles where school_id=sid and role::text='principal' and is_active;
end $$;

create or replace function public.review_leave(request_id uuid,approve_request boolean,review_reason text default '') returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); r public.leave_requests; day date; recipient uuid;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  select * into r from public.leave_requests where id=request_id and school_id=sid for update;
  if r.id is null or r.status::text<>'pending' then raise exception 'Request is missing or already reviewed'; end if;
  if not approve_request and length(trim(review_reason))=0 then raise exception 'Rejection reason required'; end if;
  if approve_request then
    update public.leave_requests set status='approved',rejection_reason=null,reviewed_by=auth.uid(),reviewed_at=now() where id=r.id;
    day:=r.start_date;
    while day<=r.end_date loop
      if public.school_working_day(sid,day) then
        insert into public.attendance(school_id,teacher_id,attendance_date,status,note,marked_at) values(sid,r.teacher_id,day,'leave','Approved leave: '||r.reason,now())
          on conflict(teacher_id,attendance_date) do update set status='leave',note=excluded.note,marked_at=now();
      end if;
      day:=day+1;
    end loop;
  else
    update public.leave_requests set status='rejected',rejection_reason=trim(review_reason),reviewed_by=auth.uid(),reviewed_at=now() where id=r.id;
  end if;
  select profile_id into recipient from public.teachers where id=r.teacher_id;
  insert into public.notifications(school_id,recipient_id,title,message,kind) values(sid,recipient,case when approve_request then 'Leave Approved' else 'Leave Rejected' end,
    'Leave for '||r.start_date||' to '||r.end_date||case when approve_request then ' was approved.' else ': '||review_reason end,'leave');
  insert into public.audit_logs(school_id,actor_id,action,details) values(sid,auth.uid(),'leave_reviewed',r.id::text);
end $$;

create or replace function public.save_timetable_slot(slot jsonb) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); tid uuid:=(slot->>'teacher_id')::uuid; cid uuid:=(slot->>'class_id')::uuid;
  pid uuid:=(slot->>'period_id')::uuid; subid uuid:=(slot->>'subject_id')::uuid; target_id uuid:=nullif(slot->>'id','')::uuid; day public.timetables.weekday%type:=slot->>'weekday'; p public.periods;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(sid::text,0));
  if day not in ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') then raise exception 'Invalid weekday'; end if;
  if not exists(select 1 from public.teachers t join public.profiles pr on pr.id=t.profile_id where t.id=tid and t.school_id=sid and pr.is_active)
    or not exists(select 1 from public.school_classes where id=cid and school_id=sid)
    or not exists(select 1 from public.subjects where id=subid and school_id=sid) then raise exception 'Teacher, class or subject is invalid'; end if;
  select * into p from public.periods where id=pid and school_id=sid;
  if p.id is null then raise exception 'Period not found'; end if;
  if exists(select 1 from public.timetables t join public.periods pp on pp.id=t.period_id where t.school_id=sid and t.weekday=day and (target_id is null or t.id<>target_id)
    and (t.teacher_id=tid or t.class_id=cid) and pp.start_time<p.end_time and pp.end_time>p.start_time) then raise exception 'Teacher or class has an overlapping timetable entry'; end if;
  if target_id is null then
    insert into public.timetables(school_id,teacher_id,class_id,subject_id,period_id,weekday) values(sid,tid,cid,subid,pid,day);
  else
    update public.timetables set teacher_id=tid,class_id=cid,subject_id=subid,period_id=pid,weekday=day where id=target_id and school_id=sid;
    if not found then raise exception 'Timetable entry not found'; end if;
  end if;
end $$;

create or replace function public.assign_replacement(target_slot uuid,cover_teacher uuid,target_date date) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id(); slot public.timetables; p public.periods; recipient uuid;
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(sid::text,0));
  select * into slot from public.timetables where id=target_slot and school_id=sid;
  if slot.id is null or trim(to_char(target_date,'Day'))<>slot.weekday::text then raise exception 'Timetable date does not match'; end if;
  if not public.school_working_day(sid,target_date) then raise exception 'School is closed'; end if;
  if not exists(select 1 from public.attendance where teacher_id=slot.teacher_id and attendance_date=target_date and status::text in ('absent','leave')) then raise exception 'Original teacher is not marked absent or on leave'; end if;
  select t.profile_id into recipient from public.teachers t join public.profiles pr on pr.id=t.profile_id where t.id=cover_teacher and t.school_id=sid and pr.is_active;
  if recipient is null or cover_teacher=slot.teacher_id then raise exception 'Invalid replacement teacher'; end if;
  if not exists(select 1 from public.attendance where teacher_id=cover_teacher and attendance_date=target_date and status::text in ('present','late'))
    or exists(select 1 from public.leave_requests where teacher_id=cover_teacher and status::text='approved' and target_date between start_date and end_date) then raise exception 'Replacement teacher must be present and not on leave'; end if;
  select * into p from public.periods where id=slot.period_id;
  if exists(select 1 from public.timetables t join public.periods pp on pp.id=t.period_id where t.teacher_id=cover_teacher and t.weekday=slot.weekday and pp.start_time<p.end_time and pp.end_time>p.start_time)
    or exists(select 1 from public.replacement_assignments r join public.timetables t on t.id=r.timetable_id join public.periods pp on pp.id=t.period_id where r.replacement_teacher_id=cover_teacher and r.assignment_date=target_date and pp.start_time<p.end_time and pp.end_time>p.start_time) then raise exception 'Replacement teacher is busy during this period'; end if;
  insert into public.replacement_assignments(school_id,absent_teacher_id,replacement_teacher_id,timetable_id,assignment_date,status) values(sid,slot.teacher_id,cover_teacher,slot.id,target_date,'assigned');
  insert into public.notifications(school_id,recipient_id,title,message,kind) values(sid,recipient,'Class Replacement Assigned','You have a cover assignment on '||target_date||', period '||p.period_number||'.','replacement');
  insert into public.audit_logs(school_id,actor_id,action,details) values(sid,auth.uid(),'replacement_assigned',slot.id||' -> '||cover_teacher);
end $$;

create or replace function public.send_announcement(announcement_title text,announcement_body text) returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare sid uuid:=public.current_school_id();
begin
  if not public.is_principal() then raise exception 'Principal access required'; end if;
  if length(trim(announcement_title))=0 or length(trim(announcement_body))=0 then raise exception 'Title and message are required'; end if;
  insert into public.notifications(school_id,recipient_id,title,message,kind) select sid,id,trim(announcement_title),trim(announcement_body),'announcement' from public.profiles where school_id=sid and is_active;
end $$;

-- Restrict function execution, including privileged helper entry points.
do $$ declare f record; begin
  for f in select p.oid::regprocedure signature,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in
    ('current_school_id','is_principal','my_teacher_id','can_manage_class','school_working_day','validate_student_class','provision_teacher','update_my_profile','update_teacher','create_teacher_record','check_in','set_teacher_attendance','save_student_attendance','request_leave','review_leave','save_timetable_slot','assign_replacement','send_announcement') loop
    execute format('revoke all on function %s from public,anon,authenticated',f.signature);
    execute format('grant execute on function %s to service_role',f.signature);
    if f.proname not in ('create_teacher_record','school_working_day','validate_student_class') then
      execute format('grant execute on function %s to authenticated',f.signature);
    end if;
  end loop;
end $$;
create index if not exists students_class_idx on public.students(school_id,class_id);
create index if not exists attendance_day_idx on public.attendance(school_id,attendance_date);
create index if not exists notification_recipient_idx on public.notifications(recipient_id,created_at desc);
commit;
