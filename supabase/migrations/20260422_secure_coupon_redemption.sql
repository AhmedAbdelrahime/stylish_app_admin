drop policy if exists "Authenticated users can update coupons" on public.coupons;

create or replace function public.redeem_coupon_usage(coupon_id_input uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  current_used_count integer;
  current_usage_limit integer;
  coupon_is_active boolean;
  coupon_starts_at timestamptz;
  coupon_expires_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select
    used_count,
    usage_limit,
    is_active,
    starts_at,
    expires_at
  into
    current_used_count,
    current_usage_limit,
    coupon_is_active,
    coupon_starts_at,
    coupon_expires_at
  from public.coupons
  where id = coupon_id_input
  for update;

  if not found then
    raise exception 'Coupon not found';
  end if;

  if coupon_is_active is distinct from true then
    raise exception 'This coupon is not active';
  end if;

  if coupon_starts_at is not null
     and timezone('utc', now()) < coupon_starts_at then
    raise exception 'This coupon is not active yet';
  end if;

  if coupon_expires_at is not null
     and timezone('utc', now()) > coupon_expires_at then
    raise exception 'This coupon has expired';
  end if;

  if current_usage_limit is not null
     and current_used_count >= current_usage_limit then
    raise exception 'This coupon has reached its usage limit';
  end if;

  update public.coupons
  set used_count = used_count + 1
  where id = coupon_id_input
  returning used_count into current_used_count;

  return current_used_count;
end;
$$;

revoke all on function public.redeem_coupon_usage(uuid) from public;
grant execute on function public.redeem_coupon_usage(uuid) to authenticated;
