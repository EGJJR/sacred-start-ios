-- Circle reflection challenges

create table if not exists public.circle_challenges (
  id uuid primary key,
  circle_id uuid not null references public.prayer_circles(id) on delete cascade,
  title text not null,
  prompt text not null,
  verse_reference text,
  kind text not null check (kind in ('gratitude', 'scripture')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists idx_circle_challenges_circle on public.circle_challenges(circle_id, ends_at desc);

alter table public.circle_posts
  add column if not exists challenge_id uuid references public.circle_challenges(id) on delete set null;

alter table public.circle_posts drop constraint if exists circle_posts_kind_check;
alter table public.circle_posts add constraint circle_posts_kind_check
  check (kind in ('request', 'testimony', 'reminder', 'reflection'));

alter table public.circle_challenges enable row level security;

create policy circle_challenges_select on public.circle_challenges
  for select using (
    exists (
      select 1 from public.circle_memberships cm
      where cm.circle_id = circle_challenges.circle_id and cm.user_id = auth.uid()
    )
  );

create policy circle_challenges_insert on public.circle_challenges
  for insert with check (
    exists (
      select 1 from public.circle_memberships cm
      where cm.circle_id = circle_challenges.circle_id
        and cm.user_id = auth.uid()
    )
    and created_by = auth.uid()
  );

alter publication supabase_realtime add table public.circle_challenges;
