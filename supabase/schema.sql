-- PABLOX database foundation. Run only in a dedicated Supabase project.
create extension if not exists pgcrypto;
create table public.restaurants (
 id uuid primary key default gen_random_uuid(),
 name text not null check(length(trim(name)) between 2 and 120),
 created_at timestamptz not null default now()
);
create table public.restaurant_members (
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check(role in ('owner','manager','staff')),
 primary key (restaurant_id,user_id)
);
create table public.products (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null,
 price_piasters bigint not null check(price_piasters >= 0),
 active boolean not null default true,
 unique (restaurant_id,id)
);
create table public.orders (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 customer_name text not null,
 customer_phone text,
 status text not null default 'new' check(status in ('new','accepted','preparing','ready','completed','cancelled')),
 total_piasters bigint not null default 0 check(total_piasters >= 0),
 created_at timestamptz not null default now(),
 unique (restaurant_id,id)
);
create table public.order_items (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null,
 order_id uuid not null,
 product_id uuid,
 product_name text not null,
 quantity integer not null check(quantity > 0),
 unit_price_piasters bigint not null check(unit_price_piasters >= 0),
 foreign key (restaurant_id,order_id) references public.orders(restaurant_id,id) on delete cascade,
 foreign key (restaurant_id,product_id) references public.products(restaurant_id,id)
);
create index orders_restaurant_created_idx on public.orders(restaurant_id,created_at desc);
create index members_user_idx on public.restaurant_members(user_id);
create or replace function public.is_restaurant_member(rid uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.restaurant_members m where m.restaurant_id=rid and m.user_id=(select auth.uid())) $$;
revoke all on function public.is_restaurant_member(uuid) from public;
grant execute on function public.is_restaurant_member(uuid) to authenticated;
alter table public.restaurants enable row level security;
alter table public.restaurant_members enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
create policy restaurant_read on public.restaurants for select to authenticated using (public.is_restaurant_member(id));
create policy members_read on public.restaurant_members for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy products_read on public.products for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy orders_read on public.orders for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy items_read on public.order_items for select to authenticated using (public.is_restaurant_member(restaurant_id));
-- Deliberately no client INSERT/UPDATE/DELETE policies.
-- Writes must go through authenticated server endpoints that check roles,
-- compute prices server-side, and create orders/items atomically.
