create or replace function public.get_best_sellers(limit_count int default 3)
returns setof public.food_items
language sql
security definer
set search_path = public
as $$
  select f.*
  from public.food_items f
  left join (
    select food_id, sum(quantity) as total_quantity
    from public.order_items
    group by food_id
  ) oi on oi.food_id = f.id::text
  where f.is_available = true
  order by coalesce(oi.total_quantity, 0) desc, f.created_at desc
  limit limit_count;
$$;

grant execute on function public.get_best_sellers(int) to anon, authenticated;
