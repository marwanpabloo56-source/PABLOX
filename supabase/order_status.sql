-- Authenticated staff can advance an existing order only within their restaurant.
-- Run after schema.sql. No public order creation is enabled.
create or replace function public.advance_order_status(
  p_restaurant_id uuid,
  p_order_id uuid,
  p_next_status text
) returns public.orders
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.orders;
  v_role text;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required' using errcode='28000';
  end if;

  select m.role into v_role
  from public.restaurant_members m
  where m.restaurant_id=p_restaurant_id
    and m.user_id=(select auth.uid());

  if v_role is null then
    raise exception 'Not a member of this restaurant' using errcode='42501';
  end if;

  select * into v_order
  from public.orders
  where restaurant_id=p_restaurant_id and id=p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode='P0002';
  end if;

  if not (
    (v_order.status='new' and p_next_status='accepted') or
    (v_order.status='accepted' and p_next_status='preparing') or
    (v_order.status='preparing' and p_next_status='ready') or
    (v_order.status='ready' and p_next_status='completed') or
    (v_order.status in ('new','accepted','preparing') and p_next_status='cancelled' and v_role in ('owner','manager'))
  ) then
    raise exception 'Invalid status transition or insufficient role' using errcode='42501';
  end if;

  update public.orders set status=p_next_status
  where restaurant_id=p_restaurant_id and id=p_order_id
  returning * into v_order;

  return v_order;
end;
$$;
revoke all on function public.advance_order_status(uuid,uuid,text) from public;
grant execute on function public.advance_order_status(uuid,uuid,text) to authenticated;
