create extension if not exists pgcrypto;

create table if not exists public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists wishlist_items_user_product_idx
on public.wishlist_items (user_id, product_id);

create index if not exists wishlist_items_user_id_idx
on public.wishlist_items (user_id);

create or replace function public.update_wishlist_items_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_wishlist_items_updated_at on public.wishlist_items;

create trigger set_wishlist_items_updated_at
before update on public.wishlist_items
for each row
execute function public.update_wishlist_items_updated_at();

alter table public.wishlist_items enable row level security;

drop policy if exists "Users can view their wishlist items" on public.wishlist_items;
create policy "Users can view their wishlist items"
on public.wishlist_items
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their wishlist items" on public.wishlist_items;
create policy "Users can insert their wishlist items"
on public.wishlist_items
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their wishlist items" on public.wishlist_items;
create policy "Users can delete their wishlist items"
on public.wishlist_items
for delete
using (auth.uid() = user_id);

drop policy if exists "Users can update their wishlist items" on public.wishlist_items;
create policy "Users can update their wishlist items"
on public.wishlist_items
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
