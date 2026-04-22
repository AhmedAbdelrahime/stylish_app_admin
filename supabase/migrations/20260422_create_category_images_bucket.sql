insert into storage.buckets (id, name, public)
values ('category-images', 'category-images', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Public can view category images" on storage.objects;
create policy "Public can view category images"
on storage.objects
for select
using (bucket_id = 'category-images');

drop policy if exists "Authenticated users can upload category images" on storage.objects;
create policy "Authenticated users can upload category images"
on storage.objects
for insert
with check (
  bucket_id = 'category-images'
  and auth.role() = 'authenticated'
);

drop policy if exists "Authenticated users can update category images" on storage.objects;
create policy "Authenticated users can update category images"
on storage.objects
for update
using (
  bucket_id = 'category-images'
  and auth.role() = 'authenticated'
)
with check (
  bucket_id = 'category-images'
  and auth.role() = 'authenticated'
);

drop policy if exists "Authenticated users can delete category images" on storage.objects;
create policy "Authenticated users can delete category images"
on storage.objects
for delete
using (
  bucket_id = 'category-images'
  and auth.role() = 'authenticated'
);
