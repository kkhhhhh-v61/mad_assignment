-- DoorDish rider assignment: additive branch mapping, assignment audit, and
-- server-authoritative availability/assignment operations.
-- Existing tables, rows, order-creation functions, and lifecycle functions are
-- preserved.  Assignment is deliberately exposed only through RPCs.

do $$
begin
  if to_regclass('public.rider_branch_assignments') is not null
     or to_regclass('public.order_assignment_history') is not null
     or to_regprocedure('public.assign_order_rider(uuid,uuid)') is not null
     or to_regprocedure('public.set_rider_availability(text)') is not null then
    raise exception 'Refusing to modify an existing rider-assignment object.';
  end if;
end
$$;

create table public.rider_branch_assignments (
  rider_id uuid primary key references public.riders(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete restrict,
  assigned_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_assignment_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  rider_id uuid not null references public.riders(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  assigned_by uuid not null references auth.users(id) on delete restrict,
  order_status text not null,
  created_at timestamptz not null default now(),
  constraint order_assignment_history_status_check
    check (order_status in ('placed', 'preparing', 'ready', 'picked_up', 'delivering'))
);

create index rider_branch_assignments_branch_idx
  on public.rider_branch_assignments (branch_id, rider_id);

create index order_assignment_history_order_created_idx
  on public.order_assignment_history (order_id, created_at desc);

alter table public.rider_branch_assignments enable row level security;
alter table public.order_assignment_history enable row level security;

revoke all on table public.rider_branch_assignments, public.order_assignment_history
  from public, anon, authenticated;

grant select, insert, update, delete
  on table public.rider_branch_assignments to authenticated;
grant select on table public.order_assignment_history to authenticated;

create policy rider_branch_assignments_select_scoped
  on public.rider_branch_assignments
  for select
  to authenticated
  using (
    rider_id = (select auth.uid())
    or exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and p.role = 'admin'
    )
  );

create policy rider_branch_assignments_admin_insert
  on public.rider_branch_assignments
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

create policy rider_branch_assignments_admin_update
  on public.rider_branch_assignments
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

create policy rider_branch_assignments_admin_delete
  on public.rider_branch_assignments
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

create policy order_assignment_history_select_scoped
  on public.order_assignment_history
  for select
  to authenticated
  using (
    rider_id = (select auth.uid())
    or exists (
      select 1
      from public.orders o
      where o.id = order_assignment_history.order_id
        and o.customer_id = (select auth.uid())
    )
    or exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and p.role = 'admin'
    )
  );

-- Keep the availability flag and the order lifecycle consistent.  The rider
-- can choose only Online/Offline; On Delivery is assigned by the server.
create or replace function public.set_rider_availability(
  p_status text
)
returns public.riders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_role text;
  v_rider public.riders;
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select p.role::text
    into v_role
  from public.profiles p
  where p.id = v_actor;

  if v_role is distinct from 'rider' then
    raise exception 'RIDER_ROLE_REQUIRED';
  end if;

  if p_status is null or p_status not in ('Online', 'Offline') then
    raise exception 'INVALID_RIDER_AVAILABILITY';
  end if;

  if p_status = 'Offline'
     and exists (
       select 1
       from public.orders o
       where o.rider_id = v_actor
         and o.status in ('ready', 'picked_up', 'delivering')
     ) then
    raise exception 'ACTIVE_DELIVERY_REQUIRED';
  end if;

  update public.riders
  set status = p_status
  where id = v_actor
  returning * into v_rider;

  if not found then
    raise exception 'RIDER_NOT_FOUND';
  end if;

  return v_rider;
end;
$$;

-- Admin assignment is atomic and deterministic.  A null p_rider_id selects
-- the first eligible same-branch Online rider with no active delivery.  The
-- current schema has no idle-rider GPS presence table, so the stable rider
-- creation/id order is the documented fallback until such a source is added.
create or replace function public.assign_order_rider(
  p_order_id uuid,
  p_rider_id uuid default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_role text;
  v_order public.orders;
  v_rider public.riders;
  v_branch_id uuid;
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_order_id is null then
    raise exception 'ORDER_ID_REQUIRED';
  end if;

  select p.role::text
    into v_role
  from public.profiles p
  where p.id = v_actor;

  if v_role is distinct from 'admin' then
    raise exception 'ADMIN_ROLE_REQUIRED';
  end if;

  select *
    into v_order
  from public.orders o
  where o.id = p_order_id
  for update;

  if not found then
    raise exception 'ORDER_NOT_FOUND';
  end if;
  if v_order.fulfilment_type <> 'delivery' then
    raise exception 'DELIVERY_ORDER_REQUIRED';
  end if;
  if v_order.status <> 'ready' then
    raise exception 'ORDER_NOT_READY';
  end if;
  if v_order.rider_id is not null then
    raise exception 'ORDER_ALREADY_ASSIGNED';
  end if;

  begin
    v_branch_id := nullif(trim(v_order.branch_snapshot ->> 'branch_id'), '')::uuid;
  exception
    when invalid_text_representation then
      raise exception 'BRANCH_ASSIGNMENT_REQUIRED';
  end;
  if v_branch_id is null then
    raise exception 'BRANCH_ASSIGNMENT_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.branches b
    where b.id = v_branch_id
      and b.is_active = true
  ) then
    raise exception 'BRANCH_NOT_FOUND_OR_INACTIVE';
  end if;

  if p_rider_id is null then
    select r.*
      into v_rider
    from public.riders r
    join public.rider_branch_assignments rb
      on rb.rider_id = r.id
     and rb.branch_id = v_branch_id
    where r.is_active = true
      and r.status = 'Online'
      and not exists (
        select 1
        from public.orders active_order
        where active_order.rider_id = r.id
          and active_order.status in ('ready', 'picked_up', 'delivering')
      )
    order by r.created_at, r.id
    limit 1
    for update of r skip locked;
  else
    select r.*
      into v_rider
    from public.riders r
    join public.rider_branch_assignments rb
      on rb.rider_id = r.id
     and rb.branch_id = v_branch_id
    where r.id = p_rider_id
      and r.is_active = true
      and r.status = 'Online'
    for update of r;

    if found and exists (
      select 1
      from public.orders active_order
      where active_order.rider_id = v_rider.id
        and active_order.status in ('ready', 'picked_up', 'delivering')
    ) then
      raise exception 'RIDER_ALREADY_ON_DELIVERY';
    end if;
  end if;

  if not found then
    raise exception 'NO_ELIGIBLE_RIDER';
  end if;

  update public.orders
  set rider_id = v_rider.id,
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update public.riders
  set status = 'On Delivery'
  where id = v_rider.id;

  insert into public.order_assignment_history (
    order_id,
    rider_id,
    branch_id,
    assigned_by,
    order_status
  )
  values (
    v_order.id,
    v_rider.id,
    v_branch_id,
    v_actor,
    v_order.status
  );

  return v_order;
end;
$$;

-- The existing lifecycle functions remain untouched.  This private trigger
-- keeps status consistent when a new assignment is made or completed through
-- those existing functions.
create schema if not exists private;

create or replace function private.sync_rider_assignment_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.rider_id is not null
     and new.status in ('ready', 'picked_up', 'delivering') then
    update public.riders
    set status = 'On Delivery'
    where id = new.rider_id;
  elsif old.rider_id is not null
        and new.status in ('delivered', 'collected', 'cancelled')
        and not exists (
          select 1
          from public.orders active_order
          where active_order.rider_id = old.rider_id
            and active_order.status in ('ready', 'picked_up', 'delivering')
        ) then
    update public.riders
    set status = 'Online'
    where id = old.rider_id
      and status = 'On Delivery';
  end if;
  return new;
end;
$$;

create trigger orders_sync_rider_assignment_status
after update of rider_id, status on public.orders
for each row
execute function private.sync_rider_assignment_status();

revoke all on function public.set_rider_availability(text)
  from public, anon, authenticated;
revoke all on function public.assign_order_rider(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.set_rider_availability(text) to authenticated;
grant execute on function public.assign_order_rider(uuid, uuid) to authenticated;
