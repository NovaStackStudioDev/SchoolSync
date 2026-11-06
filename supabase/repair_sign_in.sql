-- Run this file in the SAME Supabase project's SQL Editor to repair PGRST202 at sign-in.
-- Existing accounts and activation status are preserved. For all new features use schema_and_policies.sql.
begin;
create or replace function public.provision_teacher() returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare u auth.users; sid uuid; tid uuid; subject_name text; subid uuid; emp text;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  select school_id into sid from public.profiles where id=auth.uid() and role::text='teacher';
  if sid is null and exists(select 1 from public.profiles where id=auth.uid()) then return; end if;
  select * into u from auth.users where id=auth.uid();
  if sid is null then
    if coalesce(u.raw_user_meta_data->>'role','') <> 'teacher' then return; end if;
    select id into sid from public.schools where name='Kahatagasdigiliya Central College' order by id limit 1;
  end if;
  if sid is null then raise exception 'School is not configured'; end if;
  emp := coalesce(nullif(trim(u.raw_user_meta_data->>'employee_number'),''),'T-'||upper(left(u.id::text,8)));
  insert into public.profiles(id,school_id,full_name,role,is_active) values(u.id,sid,coalesce(nullif(trim(u.raw_user_meta_data->>'full_name'),''),'Teacher'),'teacher',false) on conflict(id) do nothing;
  select id into tid from public.teachers where profile_id=u.id;
  if tid is null then insert into public.teachers(profile_id,school_id,employee_number,phone) values(u.id,sid,emp,u.raw_user_meta_data->>'phone') returning id into tid; end if;
  if jsonb_typeof(u.raw_user_meta_data->'subjects')='array' then
    for subject_name in select jsonb_array_elements_text(u.raw_user_meta_data->'subjects') loop
      select id into subid from public.subjects where school_id=sid and name=subject_name limit 1;
      if subid is not null then insert into public.teacher_subjects(teacher_id,subject_id) values(tid,subid) on conflict do nothing; end if;
    end loop;
  end if;
end $$;


revoke all on function public.provision_teacher() from public,anon;
grant execute on function public.provision_teacher() to authenticated,service_role;
notify pgrst, 'reload schema';
commit;
