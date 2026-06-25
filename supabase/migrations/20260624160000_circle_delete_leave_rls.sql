-- Allow circle creators to delete their circles and members to leave.

create policy prayer_circles_delete on public.prayer_circles
  for delete using (created_by = auth.uid());

create policy circle_memberships_delete on public.circle_memberships
  for delete using (user_id = auth.uid());
