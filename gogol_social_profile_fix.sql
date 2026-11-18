-- GoGol 1.10.88: profile banner, comments/favorites access, and profile table grants.
-- Safe to run more than once in Supabase SQL Editor. Does not delete or rewrite user data.

-- PostgREST needs SQL table privileges in addition to RLS policies.
grant select on table public.madal_profiles to anon, authenticated;
grant insert, update on table public.madal_profiles to authenticated;

-- Profile banner metadata.
alter table public.madal_profiles
  add column if not exists profile_banner_url text;

-- Public banner images; each signed-in user can manage only their own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('madal-banners', 'madal-banners', true, 10485760,
        array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "GoGol banner images public read" on storage.objects;
create policy "GoGol banner images public read" on storage.objects
for select to anon, authenticated
using (bucket_id = 'madal-banners');

drop policy if exists "GoGol banner upload own folder" on storage.objects;
create policy "GoGol banner upload own folder" on storage.objects
for insert to authenticated
with check (bucket_id = 'madal-banners' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "GoGol banner update own folder" on storage.objects;
create policy "GoGol banner update own folder" on storage.objects
for update to authenticated
using (bucket_id = 'madal-banners' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'madal-banners' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "GoGol banner delete own folder" on storage.objects;
create policy "GoGol banner delete own folder" on storage.objects
for delete to authenticated
using (bucket_id = 'madal-banners' and (storage.foldername(name))[1] = auth.uid()::text);

-- Comments: public read on published posts, authenticated owner insert/delete.
grant select on table public.media_comments to anon, authenticated;
grant insert, delete on table public.media_comments to authenticated;
drop policy if exists "MADAL comments readable" on public.media_comments;
create policy "MADAL comments readable" on public.media_comments
for select to anon, authenticated
using (exists (
  select 1 from public.media_posts p
  where p.id = media_comments.post_id
    and (p.status = 'published' or p.user_id = auth.uid())
));
drop policy if exists "MADAL comment own" on public.media_comments;
create policy "MADAL comment own" on public.media_comments
for insert to authenticated
with check (
  auth.uid() = user_id
  and exists (select 1 from public.media_posts p where p.id = media_comments.post_id and p.status = 'published')
);
drop policy if exists "MADAL delete own comment" on public.media_comments;
create policy "MADAL delete own comment" on public.media_comments
for delete to authenticated using (auth.uid() = user_id);

-- Likes and follows also need SQL grants in addition to their RLS policies.
grant select on table public.media_likes to anon, authenticated;
grant insert, delete on table public.media_likes to authenticated;
grant select on table public.user_follows to anon, authenticated;
grant insert, delete on table public.user_follows to authenticated;
grant select on table public.media_reposts to anon, authenticated;
grant insert, delete on table public.media_reposts to authenticated;

-- Saved/Favorites table and owner-only access.
create table if not exists public.media_favorites (
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.media_favorites enable row level security;
grant select, insert, delete on table public.media_favorites to authenticated;
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
