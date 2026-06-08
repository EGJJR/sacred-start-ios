-- Prayer circles Phase 2

create table if not exists public.prayer_circles (
  id uuid primary key,
  name text not null,
  invite_code text not null unique,
  cover_palette_index int not null default 0,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.circle_memberships (
  id uuid primary key,
  circle_id uuid not null references public.prayer_circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_hue double precision not null default 0.5,
  joined_at timestamptz not null default now(),
  unique (circle_id, user_id)
);

create index if not exists idx_circle_memberships_user on public.circle_memberships(user_id);
create index if not exists idx_circle_memberships_circle on public.circle_memberships(circle_id);

create table if not exists public.circle_posts (
  id uuid primary key,
  circle_id uuid not null references public.prayer_circles(id) on delete cascade,
  author_membership_id uuid not null references public.circle_memberships(id) on delete cascade,
  author_name text not null,
  is_anonymous boolean not null default false,
  kind text not null check (kind in ('request', 'testimony', 'reminder')),
  text text not null,
  focus_tag text,
  source_note_id uuid,
  verse_reference text,
  praying_member_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists idx_circle_posts_circle_created on public.circle_posts(circle_id, created_at desc);

create table if not exists public.circle_encouragements (
  id uuid primary key,
  post_id uuid not null references public.circle_posts(id) on delete cascade,
  author_membership_id uuid not null references public.circle_memberships(id) on delete cascade,
  author_name text not null,
  text text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_circle_encouragements_post on public.circle_encouragements(post_id, created_at desc);

-- RLS
alter table public.prayer_circles enable row level security;
alter table public.circle_memberships enable row level security;
alter table public.circle_posts enable row level security;
alter table public.circle_encouragements enable row level security;

create policy prayer_circles_select on public.prayer_circles
  for select using (
    exists (
      select 1 from public.circle_memberships cm
      where cm.circle_id = prayer_circles.id and cm.user_id = auth.uid()
    )
  );

create policy prayer_circles_insert on public.prayer_circles
  for insert with check (created_by = auth.uid());

create policy circle_memberships_select on public.circle_memberships
  for select using (
    exists (
      select 1 from public.circle_memberships mine
      where mine.circle_id = circle_memberships.circle_id and mine.user_id = auth.uid()
    )
  );

create policy circle_memberships_insert on public.circle_memberships
  for insert with check (user_id = auth.uid());

create policy circle_posts_select on public.circle_posts
  for select using (
    exists (
      select 1 from public.circle_memberships cm
      where cm.circle_id = circle_posts.circle_id and cm.user_id = auth.uid()
    )
  );

create policy circle_posts_insert on public.circle_posts
  for insert with check (
    exists (
      select 1 from public.circle_memberships cm
      where cm.circle_id = circle_posts.circle_id
        and cm.user_id = auth.uid()
        and cm.id = circle_posts.author_membership_id
    )
  );

create policy circle_posts_update on public.circle_posts
  for update using (
    exists (
      select 1 from public.circle_memberships cm
      where cm.circle_id = circle_posts.circle_id and cm.user_id = auth.uid()
    )
  );

create policy circle_encouragements_select on public.circle_encouragements
  for select using (
    exists (
      select 1 from public.circle_posts p
      join public.circle_memberships cm on cm.circle_id = p.circle_id
      where p.id = circle_encouragements.post_id and cm.user_id = auth.uid()
    )
  );

create policy circle_encouragements_insert on public.circle_encouragements
  for insert with check (
    exists (
      select 1 from public.circle_posts p
      join public.circle_memberships cm on cm.circle_id = p.circle_id
      where p.id = circle_encouragements.post_id
        and cm.user_id = auth.uid()
        and cm.id = circle_encouragements.author_membership_id
    )
  );

-- Join by invite code (server lookup)
create or replace function public.join_prayer_circle(invite_code_param text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle_id uuid;
  v_user_id uuid := auth.uid();
  v_name text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id into v_circle_id
  from public.prayer_circles
  where upper(invite_code) = upper(trim(invite_code_param));

  if v_circle_id is null then
    return null;
  end if;

  select coalesce(display_name, 'Member') into v_name
  from public.profiles where id = v_user_id;

  insert into public.circle_memberships (id, circle_id, user_id, display_name, avatar_hue)
  values (gen_random_uuid(), v_circle_id, v_user_id, coalesce(v_name, 'Member'), random())
  on conflict (circle_id, user_id) do nothing;

  return v_circle_id;
end;
$$;

grant execute on function public.join_prayer_circle(text) to authenticated;

-- Realtime publication
alter publication supabase_realtime add table public.circle_posts;
alter publication supabase_realtime add table public.circle_encouragements;
alter publication supabase_realtime add table public.circle_memberships;
;
