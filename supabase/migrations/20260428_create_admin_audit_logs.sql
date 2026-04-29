create extension if not exists pgcrypto;

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid null references public.profiles (id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_admin_audit_logs_created_at
on public.admin_audit_logs using btree (created_at desc);

create index if not exists idx_admin_audit_logs_entity_type
on public.admin_audit_logs using btree (entity_type);

create index if not exists idx_admin_audit_logs_admin_user_id
on public.admin_audit_logs using btree (admin_user_id);

alter table public.admin_audit_logs enable row level security;

drop policy if exists "Admins can view admin audit logs" on public.admin_audit_logs;
create policy "Admins can view admin audit logs"
on public.admin_audit_logs
for select
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and lower(coalesce(profiles.role, '')) = 'admin'
  )
);

drop policy if exists "Admins can insert admin audit logs" on public.admin_audit_logs;
create policy "Admins can insert admin audit logs"
on public.admin_audit_logs
for insert
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and lower(coalesce(profiles.role, '')) = 'admin'
  )
  and (admin_user_id is null or admin_user_id = auth.uid())
);

drop policy if exists "Admins can update admin audit logs" on public.admin_audit_logs;
create policy "Admins can update admin audit logs"
on public.admin_audit_logs
for update
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and lower(coalesce(profiles.role, '')) = 'admin'
  )
)
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and lower(coalesce(profiles.role, '')) = 'admin'
  )
);

drop policy if exists "Admins can delete admin audit logs" on public.admin_audit_logs;
create policy "Admins can delete admin audit logs"
on public.admin_audit_logs
for delete
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and lower(coalesce(profiles.role, '')) = 'admin'
  )
);
