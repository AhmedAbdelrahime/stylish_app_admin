drop policy if exists "Storefront can view non-hidden products" on public.products;

create policy "Storefront can view non-hidden products"
on public.products
for select
to anon, authenticated
using (coalesce(status, 'active') <> 'hidden');
