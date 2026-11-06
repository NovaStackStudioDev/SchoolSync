-- Disposable database only. All source-file and timetable fixtures roll back.
\set ON_ERROR_STOP on
begin;
create function pg_temp.test_id(key text) returns uuid language sql as $$ select current_setting('test.'||key)::uuid $$;
create function pg_temp.must_fail(statement text, expected text) returns void language plpgsql as $$
begin
  begin execute statement;
  exception when others then if position(expected in sqlerrm)>0 then return; end if; raise; end;
  raise exception 'Expected failure: %',expected;
end $$;
do $$ declare k text; begin foreach k in array array['school','principal','absent_user','cover_user','absent','cover','class1','class2','class3','subject','period1','period2','upload'] loop
  perform set_config('test.'||k,gen_random_uuid()::text,true);
end loop; end $$;
select set_config('test.day',((now() at time zone 'Asia/Colombo')::date+7)::text,true);
insert into public.schools(id,name) values(pg_temp.test_id('school'),'Timetable test school');
insert into auth.users(id) values(pg_temp.test_id('principal')),(pg_temp.test_id('absent_user')),(pg_temp.test_id('cover_user'));
insert into public.profiles(id,school_id,full_name,role,is_active) values
(pg_temp.test_id('principal'),pg_temp.test_id('school'),'Principal fixture','principal',true),
(pg_temp.test_id('absent_user'),pg_temp.test_id('school'),'Absent fixture','teacher',true),
(pg_temp.test_id('cover_user'),pg_temp.test_id('school'),'Present fixture','teacher',true);
insert into public.teachers(id,school_id,profile_id,employee_number) values
(pg_temp.test_id('absent'),pg_temp.test_id('school'),pg_temp.test_id('absent_user'),'T1'),
(pg_temp.test_id('cover'),pg_temp.test_id('school'),pg_temp.test_id('cover_user'),'T2');
insert into public.school_classes(id,school_id,name) values(pg_temp.test_id('class1'),pg_temp.test_id('school'),'C1'),(pg_temp.test_id('class2'),pg_temp.test_id('school'),'C2'),(pg_temp.test_id('class3'),pg_temp.test_id('school'),'C3');
insert into public.subjects(id,school_id,name) values(pg_temp.test_id('subject'),pg_temp.test_id('school'),'Subject fixture');
insert into public.periods(id,school_id,period_number,start_time,end_time) values(pg_temp.test_id('period1'),pg_temp.test_id('school'),1,'08:00','08:50'),(pg_temp.test_id('period2'),pg_temp.test_id('school'),2,'09:00','09:50');
insert into public.school_calendar(school_id,calendar_date,is_working_day) values(pg_temp.test_id('school'),current_setting('test.day')::date,true);
insert into public.attendance(school_id,teacher_id,attendance_date,status) values(pg_temp.test_id('school'),pg_temp.test_id('absent'),current_setting('test.day')::date,'absent'),(pg_temp.test_id('school'),pg_temp.test_id('cover'),current_setting('test.day')::date,'present');
insert into public.timetables(school_id,teacher_id,class_id,subject_id,period_id,weekday) values
(pg_temp.test_id('school'),pg_temp.test_id('absent'),pg_temp.test_id('class1'),pg_temp.test_id('subject'),pg_temp.test_id('period1'),trim(to_char(current_setting('test.day')::date,'Day'))),
(pg_temp.test_id('school'),pg_temp.test_id('absent'),pg_temp.test_id('class2'),pg_temp.test_id('subject'),pg_temp.test_id('period2'),trim(to_char(current_setting('test.day')::date,'Day'))),
(pg_temp.test_id('school'),pg_temp.test_id('cover'),pg_temp.test_id('class3'),pg_temp.test_id('subject'),pg_temp.test_id('period2'),trim(to_char(current_setting('test.day')::date,'Day')));
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.principal'),true);
do $$ declare result jsonb; begin
  result:=public.auto_assign_replacements(current_setting('test.day')::date);
  if (result->>'assigned')::int<>1 or jsonb_array_length(result->'unfilled')<>1 then raise exception 'Auto assignment did not respect busy periods: %',result; end if;
  result:=public.auto_assign_replacements(current_setting('test.day')::date);
  if (result->>'assigned')::int<>0 then raise exception 'Auto assignment duplicated an existing cover'; end if;
end $$;
select pg_temp.must_fail($q$select public.save_timetable_slot(jsonb_build_object('id',(select timetable_id from public.replacement_assignments limit 1),'effective_date',current_setting('test.day'),'date_only',true,'remove',true))$q$,'Cancel affected');
select public.cancel_replacement((select id from public.replacement_assignments limit 1));
-- Single-day changes preserve earlier and subsequent weekly schedules.
select public.save_timetable_slot(jsonb_build_object('id',(select id from public.timetables where teacher_id=pg_temp.test_id('absent') and period_id=pg_temp.test_id('period1')),
  'teacher_id',pg_temp.test_id('absent'),'class_id',pg_temp.test_id('class3'),'subject_id',pg_temp.test_id('subject'),'period_id',pg_temp.test_id('period1'),
  'weekday',trim(to_char(current_setting('test.day')::date,'Day')),'effective_date',current_setting('test.day'),'date_only',true));
reset role;
do $$ declare d date:=current_setting('test.day')::date; begin
  if not exists(select 1 from public.effective_timetable(pg_temp.test_id('school'),d-7) where teacher_id=pg_temp.test_id('absent') and period_id=pg_temp.test_id('period1') and class_id=pg_temp.test_id('class1')) then raise exception 'Previous timetable was lost'; end if;
  if not exists(select 1 from public.effective_timetable(pg_temp.test_id('school'),d) where teacher_id=pg_temp.test_id('absent') and period_id=pg_temp.test_id('period1') and class_id=pg_temp.test_id('class3')) then raise exception 'Single-day revision missing'; end if;
  if not exists(select 1 from public.effective_timetable(pg_temp.test_id('school'),d+7) where teacher_id=pg_temp.test_id('absent') and period_id=pg_temp.test_id('period1') and class_id=pg_temp.test_id('class1')) then raise exception 'Weekly timetable did not resume'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.principal'),true);
insert into storage.objects(bucket_id,name) values('timetable-files',current_setting('test.school')||'/'||current_setting('test.absent')||'/fixture.pdf');
insert into public.timetable_uploads(id,school_id,teacher_id,uploaded_by,file_name,storage_path,mime_type) values(pg_temp.test_id('upload'),pg_temp.test_id('school'),pg_temp.test_id('absent'),pg_temp.test_id('principal'),'fixture.pdf',current_setting('test.school')||'/'||current_setting('test.absent')||'/fixture.pdf','application/pdf');
select set_config('request.jwt.claim.sub',current_setting('test.absent_user'),true);
select public.submit_timetable_document(pg_temp.test_id('upload'),jsonb_build_array(jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'class_id',pg_temp.test_id('class1'),'subject_id',pg_temp.test_id('subject'),'period_id',pg_temp.test_id('period1'),'id','ffffffff-ffff-ffff-ffff-ffffffffffff')),current_setting('test.day')::date,true);
do $$ begin
  if (select submitted_at from public.timetable_uploads where id=pg_temp.test_id('upload')) is null then raise exception 'Teacher submission was not saved'; end if;
end $$;
select pg_temp.must_fail($q$select public.publish_teacher_timetable(pg_temp.test_id('upload'),'[]'::jsonb,current_setting('test.day')::date,true)$q$,'Principal access required');
select set_config('request.jwt.claim.sub',current_setting('test.principal'),true);
-- Conflicting file entries roll back the whole publish and retain the old schedule.
select pg_temp.must_fail($q$select public.publish_teacher_timetable(pg_temp.test_id('upload'),jsonb_build_array(
  jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'class_id',pg_temp.test_id('class1'),'subject_id',pg_temp.test_id('subject'),'period_id',pg_temp.test_id('period1')),
  jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'class_id',pg_temp.test_id('class2'),'subject_id',pg_temp.test_id('subject'),'period_id',pg_temp.test_id('period1'))),current_setting('test.day')::date,true)$q$,'overlapping');
do $$ begin if (select status from public.timetable_uploads where id=pg_temp.test_id('upload'))<>'draft' then raise exception 'Failed upload was published'; end if; end $$;
select public.publish_teacher_timetable(pg_temp.test_id('upload'),jsonb_build_array(jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'class_id',pg_temp.test_id('class1'),'subject_id',pg_temp.test_id('subject'),'period_id',pg_temp.test_id('period1'))),current_setting('test.day')::date,true);
do $$ begin
  if (select status from public.timetable_uploads where id=pg_temp.test_id('upload'))<>'published' then raise exception 'Confirmed source was not published'; end if;
end $$;
-- A later weekly upload can replace previous daily revisions without rewriting history.
select public.publish_teacher_timetable(pg_temp.test_id('upload'),jsonb_build_array(jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'class_id',pg_temp.test_id('class2'),'subject_id',pg_temp.test_id('subject'),'period_id',pg_temp.test_id('period1'))),current_setting('test.day')::date,false);
reset role;
do $$ begin
  if not exists(select 1 from public.effective_timetable(pg_temp.test_id('school'),current_setting('test.day')::date+7) where teacher_id=pg_temp.test_id('absent') and class_id=pg_temp.test_id('class2') and period_id=pg_temp.test_id('period1')) then raise exception 'Weekly re-upload did not take effect'; end if;
  if not exists(select 1 from public.effective_timetable(pg_temp.test_id('school'),current_setting('test.day')::date-7) where teacher_id=pg_temp.test_id('absent') and class_id=pg_temp.test_id('class1') and period_id=pg_temp.test_id('period1')) then raise exception 'Weekly re-upload rewrote history'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.cover_user'),true);
do $$ begin if exists(select 1 from public.timetable_uploads) or exists(select 1 from storage.objects) then raise exception 'Teacher can read another teacher source document'; end if; end $$;
select pg_temp.must_fail($q$insert into public.timetable_uploads(school_id,teacher_id,uploaded_by,file_name,storage_path,mime_type) values(pg_temp.test_id('school'),pg_temp.test_id('cover'),pg_temp.test_id('cover_user'),'spoof.pdf',current_setting('test.school')||'/'||current_setting('test.absent')||'/fixture.pdf','application/pdf')$q$,'row-level security');
select pg_temp.must_fail($q$select public.auto_assign_replacements(current_setting('test.day')::date)$q$,'Principal access required');
select set_config('request.jwt.claim.sub',current_setting('test.absent_user'),true);
do $$ begin if (select count(*) from public.timetable_uploads)<>1 or (select count(*) from storage.objects)<>1 then raise exception 'Teacher cannot read their own uploaded timetable'; end if; end $$;
reset role;
rollback;
\echo 'PASS: Auto/manual covers, busy-period exclusion, repeat safety, daily revisions, atomic Photo/PDF publishing and private file access.'
