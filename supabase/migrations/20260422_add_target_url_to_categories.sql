alter table if exists public.categories
add column if not exists target_url text;
