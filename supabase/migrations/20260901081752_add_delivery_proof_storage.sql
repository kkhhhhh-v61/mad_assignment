do $$
begin
  if exists (
    select 1
    from storage.buckets
    where id = 'delivery-proofs'
  ) then
    raise exception 'Refusing to modify existing delivery-proofs bucket.';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'delivery_proofs_insert_assigned_rider',
        'delivery_proofs_select_authorized',
        'delivery_proofs_delete_assigned_rider'
      )
  ) then
    raise exception 'Refusing to modify existing delivery proof policy.';
  end if;
end
$$;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'delivery-proofs',
  'delivery-proofs',
  false,
  5242880,
  array['image/jpeg']::text[]
);

create policy delivery_proofs_insert_assigned_rider
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'delivery-proofs'
  and name ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}\.jpg$'
  and exists (
    select 1
    from public.orders o
    where o.id::text = split_part(name, '/', 1)
      and o.rider_id = (select auth.uid())
      and o.status in ('picked_up', 'delivering')
  )
);

create policy delivery_proofs_select_authorized
on storage.objects
for select
to authenticated
using (
  bucket_id = 'delivery-proofs'
  and exists (
    select 1
    from public.orders o
    where o.id::text = split_part(name, '/', 1)
      and (
        o.customer_id = (select auth.uid())
        or o.rider_id = (select auth.uid())
        or exists (
          select 1
          from public.profiles p
          where p.id = (select auth.uid())
            and p.role = 'admin'
        )
      )
  )
);

create policy delivery_proofs_delete_assigned_rider
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'delivery-proofs'
  and exists (
    select 1
    from public.orders o
    where o.id::text = split_part(name, '/', 1)
      and o.rider_id = (select auth.uid())
      and o.status in ('picked_up', 'delivering')
  )
);
