-- Account management: unique usernames, avatar URLs, profile RPCs, storage bucket.

alter table public.profiles
  add column if not exists username text,
  add column if not exists avatar_url text;

create unique index if not exists profiles_username_lower_unique
  on public.profiles (lower(username))
  where username is not null;

create or replace function public.is_valid_username(name text)
returns boolean
language sql
immutable
as $$
  select name is not null
    and char_length(trim(name)) between 2 and 30
    and position('@' in trim(name)) = 0
    and trim(name) ~ '^[[:alnum:]._ -]+$'
$$;

create or replace function public.is_username_available(desired_username text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized text := trim(desired_username);
begin
  if not public.is_valid_username(normalized) then
    return false;
  end if;

  return not exists (
    select 1
    from public.profiles p
    where p.username is not null
      and lower(p.username) = lower(normalized)
      and (auth.uid() is null or p.id <> auth.uid())
  );
end;
$$;

create or replace function public.ensure_profile()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id)
  values (auth.uid())
  on conflict (id) do nothing;
end;
$$;

create or replace function public.claim_username(desired_username text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized text := trim(desired_username);
  result public.profiles;
begin
  perform public.ensure_profile();

  if not public.is_valid_username(normalized) then
    raise exception 'invalid_username';
  end if;

  if not public.is_username_available(normalized) then
    raise exception 'username_taken' using errcode = '23505';
  end if;

  update public.profiles
  set username = normalized,
      updated_at = now()
  where id = auth.uid()
  returning * into result;

  update public.circle_memberships
  set display_name = normalized
  where user_id = auth.uid();

  return result;
end;
$$;

create or replace function public.update_profile_avatar(new_avatar_url text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.profiles;
begin
  perform public.ensure_profile();

  update public.profiles
  set avatar_url = nullif(trim(new_avatar_url), ''),
      updated_at = now()
  where id = auth.uid()
  returning * into result;

  return result;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1), 'Morning Seeker')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

grant execute on function public.is_username_available(text) to anon, authenticated;
grant execute on function public.ensure_profile() to authenticated;
grant execute on function public.claim_username(text) to authenticated;
grant execute on function public.update_profile_avatar(text) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Avatar images are publicly accessible" on storage.objects;
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users can upload their avatar" on storage.objects;
create policy "Users can upload their avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update their avatar" on storage.objects;
create policy "Users can update their avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete their avatar" on storage.objects;
create policy "Users can delete their avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
