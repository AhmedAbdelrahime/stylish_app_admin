create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.orders (
  id uuid not null default gen_random_uuid(),
  user_id uuid null,
  status text not null default 'pending'::text,
  payment_status text not null default 'pending'::text,
  delivery_status text not null default 'pending'::text,
  subtotal numeric(10, 2) not null default 0,
  shipping_fee numeric(10, 2) not null default 0,
  discount_amount numeric(10, 2) not null default 0,
  total_amount numeric(10, 2) not null default 0,
  currency text not null default 'USD'::text,
  shipping_address text null,
  notes text null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint orders_pkey primary key (id),
  constraint orders_user_id_fkey foreign key (user_id) references public.profiles (id) on delete set null,
  constraint orders_delivery_status_check check (
    delivery_status = any (
      array[
        'pending'::text,
        'packed'::text,
        'shipped'::text,
        'delivered'::text
      ]
    )
  ),
  constraint orders_payment_status_check check (
    payment_status = any (
      array[
        'pending'::text,
        'paid'::text,
        'refunded'::text,
        'failed'::text
      ]
    )
  ),
  constraint orders_status_check check (
    status = any (
      array[
        'pending'::text,
        'processing'::text,
        'completed'::text,
        'cancelled'::text
      ]
    )
  )
);

create index if not exists idx_orders_user_id
on public.orders using btree (user_id);

create index if not exists idx_orders_status
on public.orders using btree (status);

create index if not exists idx_orders_payment_status
on public.orders using btree (payment_status);

create index if not exists idx_orders_delivery_status
on public.orders using btree (delivery_status);

create index if not exists idx_orders_created_at
on public.orders using btree (created_at desc);

drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

create table if not exists public.order_items (
  id uuid not null default gen_random_uuid(),
  order_id uuid not null,
  product_id uuid null,
  product_name text not null,
  product_title text null,
  product_image_url text null,
  unit_price numeric(10, 2) not null default 0,
  quantity integer not null default 1,
  selected_size integer null,
  created_at timestamp with time zone not null default now(),
  constraint order_items_pkey primary key (id),
  constraint order_items_order_id_fkey foreign key (order_id) references public.orders (id) on delete cascade,
  constraint order_items_product_id_fkey foreign key (product_id) references public.products (id) on delete set null,
  constraint order_items_quantity_check check ((quantity > 0))
);

create index if not exists idx_order_items_order_id
on public.order_items using btree (order_id);

create index if not exists idx_order_items_product_id
on public.order_items using btree (product_id);

create table if not exists public.offers (
  id uuid not null default gen_random_uuid(),
  image_url text not null,
  title text null,
  created_at timestamp with time zone null default now(),
  constraint offers_pkey primary key (id)
);

create table if not exists public.coupons (
  id uuid not null default gen_random_uuid(),
  code text not null,
  description text null,
  discount_type text not null default 'percent'::text,
  discount_value numeric(10, 2) not null default 0,
  min_order_amount numeric(10, 2) not null default 0,
  max_discount_amount numeric(10, 2) null,
  usage_limit integer null,
  used_count integer not null default 0,
  is_active boolean not null default true,
  starts_at timestamp with time zone null,
  expires_at timestamp with time zone null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint coupons_pkey primary key (id),
  constraint coupons_code_key unique (code),
  constraint coupons_discount_type_check check (
    discount_type = any (array['percent'::text, 'fixed'::text])
  )
);

drop trigger if exists trg_coupons_updated_at on public.coupons;
create trigger trg_coupons_updated_at
before update on public.coupons
for each row
execute function public.set_updated_at();

create table if not exists public.categories (
  id uuid not null default gen_random_uuid(),
  name text not null,
  image_url text null,
  created_at timestamp with time zone null default now(),
  is_visible boolean not null default true,
  sort_order integer not null default 0,
  updated_at timestamp with time zone not null default now(),
  constraint categories_pkey primary key (id)
);

create index if not exists idx_categories_sort_order
on public.categories using btree (sort_order);

create index if not exists idx_categories_is_visible
on public.categories using btree (is_visible);

drop trigger if exists trg_categories_updated_at on public.categories;
create trigger trg_categories_updated_at
before update on public.categories
for each row
execute function public.set_updated_at();

create table if not exists public.banners (
  id uuid not null default gen_random_uuid(),
  title text not null,
  subtitle text null,
  image_url text not null,
  target_type text not null default 'url'::text,
  target_value text null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  constraint banners_pkey primary key (id),
  constraint banners_target_type_check check (
    target_type = any (
      array[
        'url'::text,
        'product'::text,
        'category'::text,
        'offer'::text
      ]
    )
  )
);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.coupons enable row level security;

drop policy if exists "Users can view their orders" on public.orders;
create policy "Users can view their orders"
on public.orders
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their orders" on public.orders;
create policy "Users can insert their orders"
on public.orders
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update their orders" on public.orders;
create policy "Users can update their orders"
on public.orders
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their orders" on public.orders;
create policy "Users can delete their orders"
on public.orders
for delete
using (auth.uid() = user_id);

drop policy if exists "Users can view their order items" on public.order_items;
create policy "Users can view their order items"
on public.order_items
for select
using (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
);

drop policy if exists "Users can insert their order items" on public.order_items;
create policy "Users can insert their order items"
on public.order_items
for insert
with check (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
);

drop policy if exists "Users can update their order items" on public.order_items;
create policy "Users can update their order items"
on public.order_items
for update
using (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
);

drop policy if exists "Users can delete their order items" on public.order_items;
create policy "Users can delete their order items"
on public.order_items
for delete
using (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and orders.user_id = auth.uid()
  )
);

drop policy if exists "Authenticated users can view coupons" on public.coupons;
create policy "Authenticated users can view coupons"
on public.coupons
for select
using (auth.role() = 'authenticated');

drop policy if exists "Authenticated users can update coupons" on public.coupons;
create policy "Authenticated users can update coupons"
on public.coupons
for update
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Public can view avatars" on storage.objects;
create policy "Public can view avatars"
on storage.objects
for select
using (bucket_id = 'avatars');

drop policy if exists "Authenticated users can upload avatars" on storage.objects;
create policy "Authenticated users can upload avatars"
on storage.objects
for insert
with check (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
);

drop policy if exists "Authenticated users can update avatars" on storage.objects;
create policy "Authenticated users can update avatars"
on storage.objects
for update
using (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
)
with check (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
);

drop policy if exists "Authenticated users can delete avatars" on storage.objects;
create policy "Authenticated users can delete avatars"
on storage.objects
for delete
using (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
);
