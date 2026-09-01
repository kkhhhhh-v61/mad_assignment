do $$
declare
  target_name text;
begin
  foreach target_name in array array[
    'public.orders',
    'public.order_items',
    'public.order_status_history',
    'public.rider_locations'
  ] loop
    if to_regclass(target_name) is not null then
      raise exception 'Refusing to modify existing table %.', target_name;
    end if;
  end loop;
end
$$;

do $$
begin
  if to_regprocedure('public.create_order_with_items(text,text,text,jsonb,jsonb,integer,integer,integer,integer,jsonb)') is not null
     or to_regprocedure('public.transition_order_status(uuid,text,text)') is not null
     or to_regprocedure('public.update_rider_location(uuid,double precision,double precision,double precision,timestamptz)') is not null
     or to_regprocedure('public.complete_delivery(uuid,text,text)') is not null then
    raise exception 'Refusing to modify an existing order lifecycle RPC.';
  end if;
end
$$;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  payment_idempotency_key text not null unique,
  customer_id uuid not null references auth.users(id),
  rider_id uuid references auth.users(id),
  fulfilment_type text not null,
  status text not null default 'placed',
  branch_snapshot jsonb not null,
  delivery_address_snapshot jsonb,
  subtotal_sen integer not null,
  discount_sen integer not null default 0,
  delivery_fee_sen integer not null default 0,
  total_sen integer not null,
  proof_photo_path text,
  delivery_comments text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint orders_fulfilment_type_check check (fulfilment_type in ('delivery', 'pickup')),
  constraint orders_status_check check (status in ('placed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'collected', 'cancelled')),
  constraint orders_money_non_negative_check check (subtotal_sen >= 0 and discount_sen >= 0 and delivery_fee_sen >= 0 and total_sen >= 0),
  constraint orders_delivery_address_check check ((fulfilment_type = 'delivery' and delivery_address_snapshot is not null) or (fulfilment_type = 'pickup' and delivery_address_snapshot is null)),
  constraint orders_total_check check (total_sen = subtotal_sen - discount_sen + delivery_fee_sen)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  food_id text not null,
  name text not null,
  quantity integer not null,
  unit_price_sen integer not null,
  selected_options jsonb not null default '{}'::jsonb,
  line_total_sen integer not null,
  is_state_special boolean not null default false,
  special_state_code text,
  constraint order_items_quantity_check check (quantity > 0),
  constraint order_items_money_check check (unit_price_sen >= 0 and line_total_sen >= 0),
  constraint order_items_line_total_check check (line_total_sen::bigint = quantity::bigint * unit_price_sen::bigint),
  constraint order_items_special_state_check check ((is_state_special and special_state_code is not null and length(trim(special_state_code)) > 0) or (not is_state_special and special_state_code is null))
);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  from_status text,
  to_status text not null,
  actor_id uuid not null references auth.users(id),
  actor_role text not null,
  created_at timestamptz not null default now(),
  constraint order_status_history_from_check check (from_status is null or from_status in ('placed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'collected', 'cancelled')),
  constraint order_status_history_to_check check (to_status in ('placed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'collected', 'cancelled')),
  constraint order_status_history_actor_role_check check (actor_role in ('customer', 'rider', 'admin', 'system'))
);

create table public.rider_locations (
  order_id uuid primary key references public.orders(id),
  rider_id uuid not null references auth.users(id),
  latitude double precision not null,
  longitude double precision not null,
  accuracy_metres double precision not null,
  recorded_at timestamptz not null default now(),
  constraint rider_locations_latitude_check check (latitude between -90 and 90),
  constraint rider_locations_longitude_check check (longitude between -180 and 180),
  constraint rider_locations_accuracy_check check (accuracy_metres >= 0)
);

create index orders_customer_created_idx on public.orders (customer_id, created_at desc);
create index orders_rider_status_created_idx on public.orders (rider_id, status, created_at desc);
create index orders_status_created_idx on public.orders (status, created_at desc);
create index order_items_order_idx on public.order_items (order_id);
create index order_status_history_order_created_idx on public.order_status_history (order_id, created_at);
create index rider_locations_rider_idx on public.rider_locations (rider_id);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.rider_locations enable row level security;

revoke all on table public.orders, public.order_items, public.order_status_history, public.rider_locations from public, anon, authenticated;
grant select on table public.orders, public.order_items, public.order_status_history, public.rider_locations to authenticated;

create policy orders_select_scoped on public.orders
  for select
  to authenticated
  using (
    customer_id = (select auth.uid())
    or rider_id = (select auth.uid())
    or exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    )
  );

create policy order_items_select_scoped on public.order_items
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      where o.id = order_items.order_id
        and (
          o.customer_id = (select auth.uid())
          or o.rider_id = (select auth.uid())
          or exists (
            select 1
            from public.profiles p
            where p.id = (select auth.uid()) and p.role = 'admin'
          )
        )
    )
  );

create policy order_status_history_select_scoped on public.order_status_history
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      where o.id = order_status_history.order_id
        and (
          o.customer_id = (select auth.uid())
          or o.rider_id = (select auth.uid())
          or exists (
            select 1
            from public.profiles p
            where p.id = (select auth.uid()) and p.role = 'admin'
          )
        )
    )
  );

create policy rider_locations_select_scoped on public.rider_locations
  for select
  to authenticated
  using (
    rider_id = (select auth.uid())
    or exists (
      select 1
      from public.orders o
      where o.id = rider_locations.order_id
        and (
          o.customer_id = (select auth.uid())
          or exists (
            select 1
            from public.profiles p
            where p.id = (select auth.uid()) and p.role = 'admin'
          )
        )
    )
  );

create or replace function public.create_order_with_items(
  p_order_number text,
  p_payment_idempotency_key text,
  p_fulfilment_type text,
  p_branch_snapshot jsonb,
  p_delivery_address_snapshot jsonb,
  p_subtotal_sen integer,
  p_discount_sen integer,
  p_delivery_fee_sen integer,
  p_total_sen integer,
  p_items jsonb
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_role text;
  v_existing public.orders;
  v_order public.orders;
  v_item jsonb;
  v_food_id text;
  v_name text;
  v_quantity integer;
  v_unit_price_sen integer;
  v_line_total_sen integer;
  v_selected_options jsonb;
  v_is_state_special boolean;
  v_special_state_code text;
  v_item_total bigint := 0;
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  select p.role::text into v_role from public.profiles p where p.id = v_actor;
  if v_role is distinct from 'customer' then
    raise exception 'CUSTOMER_ROLE_REQUIRED';
  end if;
  if nullif(trim(p_order_number), '') is null or nullif(trim(p_payment_idempotency_key), '') is null then
    raise exception 'ORDER_IDENTITY_REQUIRED';
  end if;
  if p_fulfilment_type is null or p_fulfilment_type not in ('delivery', 'pickup') then
    raise exception 'INVALID_FULFILMENT_TYPE';
  end if;
  if p_branch_snapshot is null or jsonb_typeof(p_branch_snapshot) <> 'object' then
    raise exception 'INVALID_BRANCH_SNAPSHOT';
  end if;
  if p_fulfilment_type = 'delivery' and (p_delivery_address_snapshot is null or jsonb_typeof(p_delivery_address_snapshot) <> 'object') then
    raise exception 'DELIVERY_ADDRESS_REQUIRED';
  end if;
  if p_fulfilment_type = 'pickup' and p_delivery_address_snapshot is not null then
    raise exception 'PICKUP_ADDRESS_FORBIDDEN';
  end if;
  if p_subtotal_sen is null or p_discount_sen is null or p_delivery_fee_sen is null or p_total_sen is null then
    raise exception 'MONEY_REQUIRED';
  end if;
  if p_subtotal_sen < 0 or p_discount_sen < 0 or p_delivery_fee_sen < 0 or p_total_sen < 0 then
    raise exception 'NEGATIVE_MONEY';
  end if;
  if p_total_sen <> p_subtotal_sen - p_discount_sen + p_delivery_fee_sen then
    raise exception 'TOTAL_MISMATCH';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'ITEMS_REQUIRED';
  end if;

  select * into v_existing
  from public.orders
  where payment_idempotency_key = p_payment_idempotency_key;
  if found then
    if v_existing.customer_id <> v_actor
       or v_existing.order_number <> trim(p_order_number)
       or v_existing.fulfilment_type <> p_fulfilment_type
       or v_existing.branch_snapshot <> p_branch_snapshot
       or v_existing.delivery_address_snapshot is distinct from p_delivery_address_snapshot
       or v_existing.subtotal_sen <> p_subtotal_sen
       or v_existing.discount_sen <> p_discount_sen
       or v_existing.delivery_fee_sen <> p_delivery_fee_sen
       or v_existing.total_sen <> p_total_sen then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing;
  end if;

  insert into public.orders (
    order_number,
    payment_idempotency_key,
    customer_id,
    fulfilment_type,
    status,
    branch_snapshot,
    delivery_address_snapshot,
    subtotal_sen,
    discount_sen,
    delivery_fee_sen,
    total_sen
  )
  values (
    trim(p_order_number),
    trim(p_payment_idempotency_key),
    v_actor,
    p_fulfilment_type,
    'placed',
    p_branch_snapshot,
    p_delivery_address_snapshot,
    p_subtotal_sen,
    p_discount_sen,
    p_delivery_fee_sen,
    p_total_sen
  )
  on conflict (payment_idempotency_key) do nothing
  returning * into v_order;

  if not found then
    select * into v_existing
    from public.orders
    where payment_idempotency_key = p_payment_idempotency_key;
    if v_existing.customer_id <> v_actor
       or v_existing.order_number <> trim(p_order_number)
       or v_existing.fulfilment_type <> p_fulfilment_type
       or v_existing.branch_snapshot <> p_branch_snapshot
       or v_existing.delivery_address_snapshot is distinct from p_delivery_address_snapshot
       or v_existing.subtotal_sen <> p_subtotal_sen
       or v_existing.discount_sen <> p_discount_sen
       or v_existing.delivery_fee_sen <> p_delivery_fee_sen
       or v_existing.total_sen <> p_total_sen then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing;
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'INVALID_ITEM';
    end if;
    v_food_id := nullif(trim(v_item->>'food_id'), '');
    v_name := nullif(trim(v_item->>'name'), '');
    v_quantity := (v_item->>'quantity')::integer;
    v_unit_price_sen := (v_item->>'unit_price_sen')::integer;
    v_line_total_sen := (v_item->>'line_total_sen')::integer;
    v_selected_options := coalesce(v_item->'selected_options', '{}'::jsonb);
    v_is_state_special := coalesce((v_item->>'is_state_special')::boolean, false);
    v_special_state_code := nullif(trim(v_item->>'special_state_code'), '');
    if v_food_id is null or v_name is null or v_quantity is null or v_quantity <= 0 or v_unit_price_sen is null or v_unit_price_sen < 0 or v_line_total_sen is null or v_line_total_sen < 0 then
      raise exception 'INVALID_ITEM';
    end if;
    if jsonb_typeof(v_selected_options) <> 'object' or v_line_total_sen::bigint <> v_quantity::bigint * v_unit_price_sen::bigint then
      raise exception 'INVALID_ITEM_TOTAL';
    end if;
    if v_is_state_special and v_special_state_code is null then
      raise exception 'SPECIAL_STATE_REQUIRED';
    end if;
    if not v_is_state_special and v_special_state_code is not null then
      raise exception 'SPECIAL_STATE_FORBIDDEN';
    end if;
    insert into public.order_items (
      order_id,
      food_id,
      name,
      quantity,
      unit_price_sen,
      selected_options,
      line_total_sen,
      is_state_special,
      special_state_code
    )
    values (
      v_order.id,
      v_food_id,
      v_name,
      v_quantity,
      v_unit_price_sen,
      v_selected_options,
      v_line_total_sen,
      v_is_state_special,
      v_special_state_code
    );
    v_item_total := v_item_total + v_line_total_sen;
  end loop;
  if v_item_total <> p_subtotal_sen::bigint then
    raise exception 'SUBTOTAL_MISMATCH';
  end if;
  insert into public.order_status_history (order_id, from_status, to_status, actor_id, actor_role)
  values (v_order.id, null, 'placed', v_actor, 'customer');
  return v_order;
end;
$$;

create or replace function public.transition_order_status(
  p_order_id uuid,
  p_expected_status text,
  p_next_status text
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
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  select p.role::text into v_role from public.profiles p where p.id = v_actor;
  if p_next_status not in ('placed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'collected', 'cancelled') then
    raise exception 'INVALID_NEXT_STATUS';
  end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'ORDER_NOT_FOUND';
  end if;
  if v_order.status <> p_expected_status then
    raise exception 'EXPECTED_STATUS_MISMATCH';
  end if;
  if not (
    (v_role = 'customer' and v_order.customer_id = v_actor and v_order.status = 'placed' and p_next_status = 'cancelled')
    or (v_role = 'customer' and v_order.customer_id = v_actor and v_order.fulfilment_type = 'pickup' and v_order.status = 'ready' and p_next_status = 'collected')
    or (v_role = 'rider' and v_order.rider_id = v_actor and v_order.fulfilment_type = 'delivery' and v_order.status = 'ready' and p_next_status = 'picked_up')
    or (v_role = 'rider' and v_order.rider_id = v_actor and v_order.fulfilment_type = 'delivery' and v_order.status = 'picked_up' and p_next_status = 'delivering')
    or (v_role = 'admin' and v_order.status = 'placed' and p_next_status = 'preparing')
    or (v_role = 'admin' and v_order.status = 'preparing' and p_next_status = 'ready')
    or (v_role = 'admin' and v_order.fulfilment_type = 'pickup' and v_order.status = 'ready' and p_next_status = 'collected')
  ) then
    raise exception 'TRANSITION_FORBIDDEN';
  end if;
  update public.orders
  set status = p_next_status, updated_at = now()
  where id = v_order.id
  returning * into v_order;
  insert into public.order_status_history (order_id, from_status, to_status, actor_id, actor_role)
  values (v_order.id, p_expected_status, p_next_status, v_actor, v_role);
  return v_order;
end;
$$;

create or replace function public.update_rider_location(
  p_order_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy_metres double precision,
  p_recorded_at timestamptz default null
)
returns public.rider_locations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_role text;
  v_order public.orders;
  v_location public.rider_locations;
  v_existing_rider uuid;
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  select p.role::text into v_role from public.profiles p where p.id = v_actor;
  if v_role is distinct from 'rider' then
    raise exception 'RIDER_ROLE_REQUIRED';
  end if;
  if p_latitude is null or p_longitude is null or p_accuracy_metres is null or p_latitude < -90 or p_latitude > 90 or p_longitude < -180 or p_longitude > 180 or p_accuracy_metres < 0 then
    raise exception 'INVALID_LOCATION';
  end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.rider_id <> v_actor or v_order.status not in ('picked_up', 'delivering') then
    raise exception 'LOCATION_NOT_ALLOWED';
  end if;
  select rider_id into v_existing_rider from public.rider_locations where order_id = p_order_id;
  if found and v_existing_rider <> v_actor then
    raise exception 'LOCATION_OWNER_CONFLICT';
  end if;
  insert into public.rider_locations (order_id, rider_id, latitude, longitude, accuracy_metres, recorded_at)
  values (p_order_id, v_actor, p_latitude, p_longitude, p_accuracy_metres, coalesce(p_recorded_at, now()))
  on conflict (order_id) do update
    set latitude = excluded.latitude,
        longitude = excluded.longitude,
        accuracy_metres = excluded.accuracy_metres,
        recorded_at = excluded.recorded_at
  returning * into v_location;
  return v_location;
end;
$$;

create or replace function public.complete_delivery(
  p_order_id uuid,
  p_proof_photo_path text,
  p_delivery_comments text default null
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
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  select p.role::text into v_role from public.profiles p where p.id = v_actor;
  if v_role is distinct from 'rider' then
    raise exception 'RIDER_ROLE_REQUIRED';
  end if;
  if p_proof_photo_path is null or p_proof_photo_path !~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}\.jpg$' or split_part(p_proof_photo_path, '/', 1) <> p_order_id::text then
    raise exception 'INVALID_PROOF_PATH';
  end if;
  if p_delivery_comments is not null and char_length(p_delivery_comments) > 500 then
    raise exception 'COMMENTS_TOO_LONG';
  end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.rider_id <> v_actor or v_order.status <> 'delivering' then
    raise exception 'COMPLETION_NOT_ALLOWED';
  end if;
  update public.orders
  set status = 'delivered',
      proof_photo_path = trim(p_proof_photo_path),
      delivery_comments = nullif(trim(p_delivery_comments), ''),
      completed_at = now(),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;
  insert into public.order_status_history (order_id, from_status, to_status, actor_id, actor_role)
  values (v_order.id, 'delivering', 'delivered', v_actor, 'rider');
  delete from public.rider_locations where order_id = v_order.id;
  return v_order;
end;
$$;

revoke all on function public.create_order_with_items(text,text,text,jsonb,jsonb,integer,integer,integer,integer,jsonb) from public, anon, authenticated;
revoke all on function public.transition_order_status(uuid,text,text) from public, anon, authenticated;
revoke all on function public.update_rider_location(uuid,double precision,double precision,double precision,timestamptz) from public, anon, authenticated;
revoke all on function public.complete_delivery(uuid,text,text) from public, anon, authenticated;
grant execute on function public.create_order_with_items(text,text,text,jsonb,jsonb,integer,integer,integer,integer,jsonb) to authenticated;
grant execute on function public.transition_order_status(uuid,text,text) to authenticated;
grant execute on function public.update_rider_location(uuid,double precision,double precision,double precision,timestamptz) to authenticated;
grant execute on function public.complete_delivery(uuid,text,text) to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'orders') then
      alter publication supabase_realtime add table public.orders;
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'rider_locations') then
      alter publication supabase_realtime add table public.rider_locations;
    end if;
  end if;
end
$$;
