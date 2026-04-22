create extension if not exists pgcrypto;

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id text not null,
  selected_size integer,
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists cart_items_user_product_size_idx
on public.cart_items (
  user_id,
  product_id,
  coalesce(selected_size, -1)
);

create index if not exists cart_items_user_id_idx
on public.cart_items (user_id);

create or replace function public.update_cart_items_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_cart_items_updated_at on public.cart_items;

create trigger set_cart_items_updated_at
before update on public.cart_items
for each row
execute function public.update_cart_items_updated_at();

alter table public.cart_items enable row level security;

drop policy if exists "Users can view their cart items" on public.cart_items;
create policy "Users can view their cart items"
on public.cart_items
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their cart items" on public.cart_items;
create policy "Users can insert their cart items"
on public.cart_items
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update their cart items" on public.cart_items;
create policy "Users can update their cart items"
on public.cart_items
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their cart items" on public.cart_items;
create policy "Users can delete their cart items"
on public.cart_items
for delete
using (auth.uid() = user_id);
