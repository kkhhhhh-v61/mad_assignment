alter table public.orders
  add column if not exists payment_type text,
  add column if not exists payment_status text,
  add column if not exists payment_method_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where c.conname = 'orders_payment_type_check'
      and n.nspname = 'public'
      and t.relname = 'orders'
  ) then
    alter table public.orders
      add constraint orders_payment_type_check
      check (payment_type is null or payment_type in ('COD', 'Card', 'PayPal'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where c.conname = 'orders_payment_status_check'
      and n.nspname = 'public'
      and t.relname = 'orders'
  ) then
    alter table public.orders
      add constraint orders_payment_status_check
      check (payment_status is null or payment_status in ('Pending', 'Completed', 'Failed'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where c.conname = 'orders_payment_fields_consistency_check'
      and n.nspname = 'public'
      and t.relname = 'orders'
  ) then
    alter table public.orders
      add constraint orders_payment_fields_consistency_check
      check (
        (payment_type is null and payment_status is null and payment_method_id is null)
        or (
          payment_type is not null
          and payment_status is not null
          and (
            (payment_type = 'Card' and payment_method_id is not null)
            or (payment_type in ('COD', 'PayPal') and payment_method_id is null)
          )
        )
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where c.conname = 'orders_payment_method_id_fkey'
      and n.nspname = 'public'
      and t.relname = 'orders'
  ) then
    alter table public.orders
      add constraint orders_payment_method_id_fkey
      foreign key (payment_method_id)
      references public.payment_methods(id)
      on delete restrict;
  end if;
end
$$;

create index if not exists orders_payment_method_idx
  on public.orders (payment_method_id)
  where payment_method_id is not null;

create or replace function public.create_order_with_payment(
  p_order_number text,
  p_payment_idempotency_key text,
  p_fulfilment_type text,
  p_branch_snapshot jsonb,
  p_delivery_address_snapshot jsonb,
  p_subtotal_sen integer,
  p_discount_sen integer,
  p_delivery_fee_sen integer,
  p_total_sen integer,
  p_items jsonb,
  p_payment_type text,
  p_payment_status text,
  p_payment_method_id uuid
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_order public.orders;
  v_order_id uuid;
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_payment_type is null or p_payment_type not in ('COD', 'Card', 'PayPal') then
    raise exception 'INVALID_PAYMENT_TYPE';
  end if;
  if p_payment_status is null or p_payment_status not in ('Pending', 'Completed', 'Failed') then
    raise exception 'INVALID_PAYMENT_STATUS';
  end if;
  if p_payment_type = 'Card' then
    if p_payment_method_id is null then
      raise exception 'CARD_PAYMENT_METHOD_REQUIRED';
    end if;
    if not exists (
      select 1
      from public.payment_methods pm
      where pm.id = p_payment_method_id
        and pm.user_id = v_actor
    ) then
      raise exception 'PAYMENT_METHOD_NOT_OWNED';
    end if;
  elsif p_payment_method_id is not null then
    raise exception 'PAYMENT_METHOD_FORBIDDEN';
  end if;

  select * into v_order
  from public.create_order_with_items(
    p_order_number,
    p_payment_idempotency_key,
    p_fulfilment_type,
    p_branch_snapshot,
    p_delivery_address_snapshot,
    p_subtotal_sen,
    p_discount_sen,
    p_delivery_fee_sen,
    p_total_sen,
    p_items
  );

  v_order_id := v_order.id;
  select o.* into v_order
  from public.orders o
  where o.id = v_order_id
  for update;

  if v_order.payment_type is not null
     or v_order.payment_status is not null
     or v_order.payment_method_id is not null then
    if v_order.payment_type is distinct from p_payment_type
       or v_order.payment_status is distinct from p_payment_status
       or v_order.payment_method_id is distinct from p_payment_method_id then
      raise exception 'PAYMENT_IDEMPOTENCY_CONFLICT';
    end if;
    return v_order;
  end if;

  update public.orders
  set payment_type = p_payment_type,
      payment_status = p_payment_status,
      payment_method_id = p_payment_method_id,
      updated_at = now()
  where id = v_order.id
  returning * into v_order;
  return v_order;
end;
$$;

revoke all on function public.create_order_with_payment(
  text,
  text,
  text,
  jsonb,
  jsonb,
  integer,
  integer,
  integer,
  integer,
  jsonb,
  text,
  text,
  uuid
) from public, anon, authenticated;

grant execute on function public.create_order_with_payment(
  text,
  text,
  text,
  jsonb,
  jsonb,
  integer,
  integer,
  integer,
  integer,
  jsonb,
  text,
  text,
  uuid
) to authenticated;
