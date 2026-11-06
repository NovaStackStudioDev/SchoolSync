-- SchoolSync Complete Database Policies and Seeder
-- Kahatagasdigiliya Central College
-- Run this in the Supabase SQL Editor to enable full functionality for all modules.

-- 1. Ensure school exists
insert into public.schools (name, timezone, attendance_cutoff)
select 'Kahatagasdigiliya Central College', 'Asia/Colombo', '07:30:00'
where not exists (
  select 1 from public.schools
  where name = 'Kahatagasdigiliya Central College'
);

-- 2. Enable RLS on all tables
alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.teachers enable row level security;
alter table public.subjects enable row level security;
alter table public.teacher_subjects enable row level security;
alter table public.school_classes enable row level security;
alter table public.periods enable row level security;
alter table public.timetables enable row level security;
alter table public.school_calendar enable row level security;
alter table public.attendance enable row level security;
alter table public.leave_requests enable row level security;
alter table public.replacement_assignments enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

-- 3. Setup policies
do $$
begin
  -- Schools
  if not exists (select 1 from pg_policies where policyname = 'schools_read') then
    create policy schools_read on public.schools for select to anon, authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'schools_insert_auth') then
    create policy schools_insert_auth on public.schools for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'schools_update_auth') then
    create policy schools_update_auth on public.schools for update to authenticated using (true);
  end if;

  -- Profiles
  if not exists (select 1 from pg_policies where policyname = 'profiles_read') then
    create policy profiles_read on public.profiles for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'profiles_insert_auth') then
    create policy profiles_insert_auth on public.profiles for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'profiles_update_auth') then
    create policy profiles_update_auth on public.profiles for update to authenticated using (true);
  end if;

  -- Teachers
  if not exists (select 1 from pg_policies where policyname = 'teachers_read') then
    create policy teachers_read on public.teachers for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'teachers_insert_auth') then
    create policy teachers_insert_auth on public.teachers for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'teachers_update_auth') then
    create policy teachers_update_auth on public.teachers for update to authenticated using (true);
  end if;

  -- Subjects
  if not exists (select 1 from pg_policies where policyname = 'subjects_read') then
    create policy subjects_read on public.subjects for select to anon, authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'subjects_insert_auth') then
    create policy subjects_insert_auth on public.subjects for insert to authenticated with check (true);
  end if;

  -- Teacher Subjects
  if not exists (select 1 from pg_policies where policyname = 'teacher_subjects_read') then
    create policy teacher_subjects_read on public.teacher_subjects for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'teacher_subjects_insert_auth') then
    create policy teacher_subjects_insert_auth on public.teacher_subjects for insert to authenticated with check (true);
  end if;

  -- School Classes
  if not exists (select 1 from pg_policies where policyname = 'school_classes_read') then
    create policy school_classes_read on public.school_classes for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'school_classes_insert_auth') then
    create policy school_classes_insert_auth on public.school_classes for insert to authenticated with check (true);
  end if;

  -- Periods
  if not exists (select 1 from pg_policies where policyname = 'periods_read') then
    create policy periods_read on public.periods for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'periods_insert_auth') then
    create policy periods_insert_auth on public.periods for insert to authenticated with check (true);
  end if;

  -- Timetables
  if not exists (select 1 from pg_policies where policyname = 'timetables_read') then
    create policy timetables_read on public.timetables for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'timetables_insert_auth') then
    create policy timetables_insert_auth on public.timetables for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'timetables_update_auth') then
    create policy timetables_update_auth on public.timetables for update to authenticated using (true);
  end if;

  -- School Calendar
  if not exists (select 1 from pg_policies where policyname = 'school_calendar_read') then
    create policy school_calendar_read on public.school_calendar for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'school_calendar_insert_auth') then
    create policy school_calendar_insert_auth on public.school_calendar for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'school_calendar_update_auth') then
    create policy school_calendar_update_auth on public.school_calendar for update to authenticated using (true);
  end if;

  -- Attendance
  if not exists (select 1 from pg_policies where policyname = 'attendance_read') then
    create policy attendance_read on public.attendance for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'attendance_insert_auth') then
    create policy attendance_insert_auth on public.attendance for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'attendance_update_auth') then
    create policy attendance_update_auth on public.attendance for update to authenticated using (true);
  end if;

  -- Leave Requests
  if not exists (select 1 from pg_policies where policyname = 'leave_requests_read') then
    create policy leave_requests_read on public.leave_requests for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'leave_requests_insert_auth') then
    create policy leave_requests_insert_auth on public.leave_requests for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'leave_requests_update_auth') then
    create policy leave_requests_update_auth on public.leave_requests for update to authenticated using (true);
  end if;

  -- Replacement Assignments
  if not exists (select 1 from pg_policies where policyname = 'replacements_read') then
    create policy replacements_read on public.replacement_assignments for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'replacements_insert_auth') then
    create policy replacements_insert_auth on public.replacement_assignments for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'replacements_update_auth') then
    create policy replacements_update_auth on public.replacement_assignments for update to authenticated using (true);
  end if;

  -- Notifications
  if not exists (select 1 from pg_policies where policyname = 'notifications_read') then
    create policy notifications_read on public.notifications for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'notifications_insert_auth') then
    create policy notifications_insert_auth on public.notifications for insert to authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'notifications_update_auth') then
    create policy notifications_update_auth on public.notifications for update to authenticated using (true);
  end if;

  -- Audit Logs
  if not exists (select 1 from pg_policies where policyname = 'audit_logs_read') then
    create policy audit_logs_read on public.audit_logs for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'audit_logs_insert_auth') then
    create policy audit_logs_insert_auth on public.audit_logs for insert to authenticated with check (true);
  end if;
end $$;

-- 4. Initial Seed for School Classes and Periods (if school exists)
do $$
declare
  sid uuid;
begin
  select id into sid from public.schools where name = 'Kahatagasdigiliya Central College' limit 1;
  if sid is not null then
    -- Periods (1 through 8)
    if not exists (select 1 from public.periods where school_id = sid) then
      insert into public.periods (school_id, period_number, start_time, end_time) values
        (sid, 1, '07:40', '08:20'),
        (sid, 2, '08:20', '09:00'),
        (sid, 3, '09:00', '09:40'),
        (sid, 4, '10:00', '10:40'),
        (sid, 5, '10:40', '11:20'),
        (sid, 6, '11:20', '12:00'),
        (sid, 7, '12:40', '13:20'),
        (sid, 8, '13:20', '14:00');
    end if;

    -- Standard Classes
    if not exists (select 1 from public.school_classes where school_id = sid) then
      insert into public.school_classes (school_id, name) values
        (sid, 'Grade 6-A'), (sid, 'Grade 6-B'),
        (sid, 'Grade 7-A'), (sid, 'Grade 7-B'),
        (sid, 'Grade 8-A'), (sid, 'Grade 8-B'),
        (sid, 'Grade 9-A'), (sid, 'Grade 9-B'), (sid, 'Grade 9-C'),
        (sid, 'Grade 10-A'), (sid, 'Grade 10-B'),
        (sid, 'Grade 11-A'), (sid, 'Grade 11-B'),
        (sid, 'Grade 12-Science'), (sid, 'Grade 12-Commerce'), (sid, 'Grade 12-Arts'),
        (sid, 'Grade 13-Science'), (sid, 'Grade 13-Commerce'), (sid, 'Grade 13-Arts');
    end if;
  end if;
end $$;

