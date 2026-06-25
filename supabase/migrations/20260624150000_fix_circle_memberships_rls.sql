-- Fix infinite recursion in circle_memberships RLS (Postgres 42P17).
-- The select policy queried circle_memberships from within its own policy check.

create or replace function public.user_circle_ids()
returns setof uuid
language sql
security definer
set search_path = public
stable
as $$
  select circle_id from public.circle_memberships where user_id = auth.uid();
$$;

grant execute on function public.user_circle_ids() to authenticated;

drop policy if exists circle_memberships_select on public.circle_memberships;

create policy circle_memberships_select on public.circle_memberships
  for select using (
    circle_id in (select public.user_circle_ids())
  );

drop policy if exists prayer_circles_select on public.prayer_circles;

create policy prayer_circles_select on public.prayer_circles
  for select using (
    id in (select public.user_circle_ids())
  );
