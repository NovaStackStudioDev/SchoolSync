-- DISPOSABLE LOCAL TEST DATABASE ONLY. This changes the test fixture's type.
-- Run the application schema and text workflows before this file.
\set ON_ERROR_STOP on
alter table public.timetables drop constraint if exists timetables_weekday_check;
alter table public.timetables alter column weekday type integer using public.school_weekday_number(weekday::text);
alter table public.timetables add constraint timetables_weekday_check check(weekday between 1 and 7);
select case when public.school_weekday_number('Sunday')=7
  and public.school_weekday_number('7')=7
  and public.school_weekday_number('0')=7 then 'PASS: numeric weekday mapping' else 'FAIL' end;
