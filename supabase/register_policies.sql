-- Run once in the Supabase SQL editor if teacher registration
-- fails with a row-level security error.
-- Kahatagasdigiliya Central College

insert into public.schools (name, timezone)
select 'Kahatagasdigiliya Central College', 'Asia/Colombo'
where not exists (
  select 1 from public.schools
  where name = 'Kahatagasdigiliya Central College'
);

alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.teachers enable row level security;
alter table public.subjects enable row level security;
alter table public.teacher_subjects enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'schools_read') then
    create policy schools_read on public.schools for select to anon, authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'schools_insert_auth') then
    create policy schools_insert_auth on public.schools for insert to authenticated with check (true);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'profiles_read') then
    create policy profiles_read on public.profiles for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'profiles_insert_own') then
    create policy profiles_insert_own on public.profiles
      for insert to authenticated with check (id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'teachers_read') then
    create policy teachers_read on public.teachers for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'teachers_insert_own') then
    create policy teachers_insert_own on public.teachers
      for insert to authenticated with check (profile_id = auth.uid());
  end if;

  if not exists (select 1 from pg_policies where policyname = 'subjects_read') then
    create policy subjects_read on public.subjects for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'subjects_insert_auth') then
    create policy subjects_insert_auth on public.subjects
      for insert to authenticated with check (true);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'teacher_subjects_read') then
    create policy teacher_subjects_read on public.teacher_subjects
      for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'teacher_subjects_insert_own') then
    create policy teacher_subjects_insert_own on public.teacher_subjects
      for insert to authenticated
      with check (
        exists (
          select 1 from public.teachers t
          where t.id = teacher_id and t.profile_id = auth.uid()
        )
      );
  end if;
end $$;
