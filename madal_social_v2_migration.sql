-- MADAL social v2: reposts, favorites, private posts and verified profiles.
-- Run once in Supabase SQL Editor after the existing social_migration.sql.

alter table public.media_posts
  add column if not exists is_private boolean not null default false;

alter table public.madal_profiles
  add column if not exists is_verified boolean not null default false;

create table if not exists public.media_reposts (
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.media_reposts enable row level security;
drop policy if exists "MADAL reposts readable" on public.media_reposts;
create policy "MADAL reposts readable" on public.media_reposts
  for select to anon, authenticated using (true);
drop policy if exists "MADAL repost own" on public.media_reposts;
create policy "MADAL repost own" on public.media_reposts
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "MADAL unrepost own" on public.media_reposts;
create policy "MADAL unrepost own" on public.media_reposts
  for delete to authenticated using (auth.uid() = user_id);
create index if not exists media_reposts_user_created_idx
  on public.media_reposts(user_id, created_at desc);
create index if not exists media_reposts_post_idx on public.media_reposts(post_id);

create table if not exists public.media_favorites (
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.media_favorites enable row level security;
drop policy if exists "MADAL favorites own read" on public.media_favorites;
create policy "MADAL favorites own read" on public.media_favorites
  for select to authenticated using (auth.uid() = user_id);
drop policy if exists "MADAL favorites own insert" on public.media_favorites;
create policy "MADAL favorites own insert" on public.media_favorites
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "MADAL favorites own delete" on public.media_favorites;
create policy "MADAL favorites own delete" on public.media_favorites
  for delete to authenticated using (auth.uid() = user_id);
create index if not exists media_favorites_user_created_idx
  on public.media_favorites(user_id, created_at desc);

drop policy if exists "MADAL owner update own media" on public.media_posts;
create policy "MADAL owner update own media" on public.media_posts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Verification is assigned only by the MADAL administrator, never by a normal user.
-- Set is_verified=true for the confirmed official MADAL owner profile after confirming its username.

-- Enforce private visibility at the database and media-storage layers.
drop policy if exists "MADAL read published" on public.media_posts;
create policy "MADAL read published" on public.media_posts
  for select to anon, authenticated
  using ((status = 'published' and (not is_private or auth.uid() = user_id))
         or auth.uid() = user_id);

drop policy if exists "MADAL play published" on storage.objects;
create policy "MADAL play published" on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'madal-media'
    and exists (
      select 1 from public.media_posts p
      where p.storage_path = storage.objects.name
        and p.status = 'published'
        and (not p.is_private or auth.uid() = p.user_id)
    )
  );

-- Prevent normal users from granting themselves the MADAL verification badge.
create or replace function public.madal_protect_verified_flag()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.uid() is not null and new.is_verified is distinct from old.is_verified then
    raise exception 'MADAL verification can only be changed by an administrator';
  end if;
  return new;
end;
$$;
drop trigger if exists madal_verified_flag_guard on public.madal_profiles;
create trigger madal_verified_flag_guard
before update of is_verified on public.madal_profiles
for each row execute function public.madal_protect_verified_flag();
