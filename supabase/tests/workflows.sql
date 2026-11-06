-- Run after the schema in a disposable local database. All fixtures roll back.
\set ON_ERROR_STOP on
begin;
create function pg_temp.expect_error(statement text, expected text) returns void language plpgsql as $$
begin
  begin execute statement;
  exception when others then
    if position(expected in sqlerrm)>0 then return; end if;
    raise exception 'Unexpected error: % (expected %)',sqlerrm,expected;
  end;
  raise exception 'Expected an error containing: %',expected;
end $$;
insert into public.schools(id,name) values('10000000-0000-0000-0000-000000000001','Test school'),('10000000-0000-0000-0000-000000000002','Other test school');
insert into auth.users(id) select ('20000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,4) n;
insert into public.profiles(id,school_id,full_name,role,is_active) values
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Principal fixture','principal',true),
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','Teacher fixture','teacher',true),
('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','Cover fixture','teacher',true),
('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002','Other principal','principal',true);
insert into public.teachers(id,school_id,profile_id,employee_number) values
('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','T-1'),
('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000003','T-2');
insert into public.school_classes(id,school_id,name) values
('40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Test class'),
('40000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Private other class');
insert into public.students(id,school_id,class_id,full_name,admission_number) values
('50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Student fixture','S-1');
insert into public.subjects(id,school_id,name) values('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Test subject');
insert into public.periods(id,school_id,period_number,start_time,end_time) values
('70000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',1,'08:00','08:50'),
('70000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001',2,'08:30','09:20');
select set_config('test.day',((now() at time zone 'Asia/Colombo')::date+7)::text,true);
insert into public.school_calendar(school_id,calendar_date,is_working_day,description) values
('10000000-0000-0000-0000-000000000001',current_setting('test.day')::date,true,'Test working day'),
('10000000-0000-0000-0000-000000000001',current_setting('test.day')::date+1,false,'Test holiday'),
('10000000-0000-0000-0000-000000000001',(now() at time zone 'Asia/Colombo')::date,true,'Test check-in day');

set local role authenticated;
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000001';
do $$ begin
  if (select count(*) from public.school_classes)<>1 then raise exception 'Cross-school class leak'; end if;
  if has_function_privilege('authenticated','public.create_teacher_record(uuid,uuid,jsonb)','EXECUTE') then raise exception 'Privileged provisioning exposed'; end if;
end $$;
select public.save_timetable_slot(jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'teacher_id','30000000-0000-0000-0000-000000000001','class_id','40000000-0000-0000-0000-000000000001','subject_id','60000000-0000-0000-0000-000000000001','period_id','70000000-0000-0000-0000-000000000001'));
select pg_temp.expect_error($q$select public.save_timetable_slot(jsonb_build_object('weekday',trim(to_char(current_setting('test.day')::date,'Day')),'teacher_id','30000000-0000-0000-0000-000000000002','class_id','40000000-0000-0000-0000-000000000001','subject_id','60000000-0000-0000-0000-000000000001','period_id','70000000-0000-0000-0000-000000000002'))$q$,'overlapping');

set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000002';
select public.check_in();
select pg_temp.expect_error($q$select public.check_in()$q$,'already recorded');
do $$ begin
  if not exists(select 1 from public.attendance where teacher_id=public.my_teacher_id() and attendance_date=(now() at time zone 'Asia/Colombo')::date and status::text in ('present','late')) then raise exception 'Server-time check-in did not persist'; end if;
end $$;
select public.save_student_attendance('40000000-0000-0000-0000-000000000001',(now() at time zone 'Asia/Colombo')::date,'[{"student_id":"50000000-0000-0000-0000-000000000001","status":"present"}]');
select pg_temp.expect_error($q$select public.save_student_attendance('40000000-0000-0000-0000-000000000002',current_date,'[{"student_id":"50000000-0000-0000-0000-000000000001","status":"present"}]')$q$,'Class access denied');
select pg_temp.expect_error($q$select public.set_teacher_attendance('30000000-0000-0000-0000-000000000001',current_date,'present')$q$,'Principal access required');
select public.request_leave(current_setting('test.day')::date,current_setting('test.day')::date+1,'Test leave');
select pg_temp.expect_error($q$select public.request_leave(current_setting('test.day')::date,current_setting('test.day')::date,'Overlap')$q$,'overlapping');
select pg_temp.expect_error($q$select public.review_leave((select id from public.leave_requests limit 1),true,'')$q$,'Principal access required');

set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000001';
select public.review_leave((select id from public.leave_requests limit 1),true,'');
do $$ begin
  if (select count(*) from public.attendance where status='leave')<>1 then raise exception 'Leave should mark only configured working days'; end if;
end $$;
select pg_temp.expect_error($q$select public.review_leave((select id from public.leave_requests limit 1),true,'')$q$,'already reviewed');
select pg_temp.expect_error($q$select public.assign_replacement((select id from public.timetables limit 1),'30000000-0000-0000-0000-000000000002',current_setting('test.day')::date)$q$,'must be present');
reset role;
insert into public.attendance(school_id,teacher_id,attendance_date,status) values('10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002',current_setting('test.day')::date,'present');
set local role authenticated;
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000001';
select public.assign_replacement((select id from public.timetables limit 1),'30000000-0000-0000-0000-000000000002',current_setting('test.day')::date);
select pg_temp.expect_error($q$select public.assign_replacement((select id from public.timetables limit 1),'30000000-0000-0000-0000-000000000002',current_setting('test.day')::date)$q$,'busy');
select public.send_announcement('Test announcement','Fixture message');
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000003';
do $$ begin
  if (select count(*) from public.notifications where kind='replacement')<>1 then raise exception 'Cover teacher notification missing'; end if;
  if exists(select 1 from public.notifications where recipient_id<>auth.uid()) then raise exception 'Notification recipient leak'; end if;
  if (select count(*) from public.notifications where kind='announcement')<>1 then raise exception 'Announcement missing'; end if;
end $$;
update public.notifications set is_read=true;
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000004';
do $$ begin
  if exists(select 1 from public.students) or exists(select 1 from public.leave_requests) or exists(select 1 from public.replacement_assignments) then raise exception 'Cross-school data leak'; end if;
end $$;
reset role;
-- Self-registration cannot grant principal privileges or bypass activation.
insert into auth.users(id,raw_user_meta_data) values
('20000000-0000-0000-0000-000000000005','{"role":"teacher","full_name":"Pending fixture","employee_number":"PENDING-TEST","school_id":"10000000-0000-0000-0000-000000000002"}'),
('20000000-0000-0000-0000-000000000006','{"role":"principal","full_name":"Untrusted metadata"}');
set local role authenticated;
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000005';
select public.provision_teacher();
select public.provision_teacher();
do $$ begin
  if (select count(*) from public.profiles where id=auth.uid() and role::text='teacher' and is_active=false)<>1 then raise exception 'Self-registration should await activation'; end if;
  if public.current_school_id() is not null or public.is_principal() then raise exception 'Pending staff have school privileges'; end if;
end $$;
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000006';
select public.provision_teacher();
do $$ begin
  if exists(select 1 from public.profiles where id=auth.uid()) then raise exception 'Principal created from untrusted metadata'; end if;
end $$;
reset role;
rollback;
\echo 'PASS: RLS isolation, role enforcement, timetable overlap, student attendance, leave review, eligible replacements and private notifications.'
