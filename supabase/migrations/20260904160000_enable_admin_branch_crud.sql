revoke insert, update, delete, truncate, references, trigger
on table public.branches
from public, anon;

grant insert, update, delete
on table public.branches
to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'branches'
      and policyname = 'branches_admin_select'
  ) then
    create policy branches_admin_select on public.branches
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.profiles p
          where p.id = (select auth.uid())
            and p.role = 'admin'
        )
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'branches'
      and policyname = 'branches_admin_insert'
  ) then
    create policy branches_admin_insert on public.branches
      for insert
      to authenticated
      with check (
        exists (
          select 1
          from public.profiles p
          where p.id = (select auth.uid())
            and p.role = 'admin'
        )
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'branches'
      and policyname = 'branches_admin_update'
  ) then
    create policy branches_admin_update on public.branches
      for update
      to authenticated
      using (
        exists (
          select 1
          from public.profiles p
          where p.id = (select auth.uid())
            and p.role = 'admin'
        )
      )
      with check (
        exists (
          select 1
          from public.profiles p
          where p.id = (select auth.uid())
            and p.role = 'admin'
        )
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'branches'
      and policyname = 'branches_admin_delete'
  ) then
    create policy branches_admin_delete on public.branches
      for delete
      to authenticated
      using (
        exists (
          select 1
          from public.profiles p
          where p.id = (select auth.uid())
            and p.role = 'admin'
        )
      );
  end if;
end
$$;
