-- MADAL Supabase setup. Run in SQL Editor.
create table if not exists public.media_posts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(char_length(title) between 1 and 140),
 description text default '',
 media_type text not null check(media_type in ('video','qiso','podcast')),
 storage_path text not null unique,
 download_allowed boolean not null default false,
 status text not null default 'published' check(status in ('published','hidden')),
 created_at timestamptz not null default now()
);
alter table public.media_posts enable row level security;
drop policy if exists "MADAL read published" on public.media_posts;
create policy "MADAL read published" on public.media_posts for select using(status='published' or auth.uid()=user_id);
drop policy if exists "MADAL insert own" on public.media_posts;
create policy "MADAL insert own" on public.media_posts for insert to authenticated with check(auth.uid()=user_id);
drop policy if exists "MADAL update own" on public.media_posts;
create policy "MADAL update own" on public.media_posts for update to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "MADAL delete own" on public.media_posts;
create policy "MADAL delete own" on public.media_posts for delete to authenticated using(auth.uid()=user_id);
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('madal-media','madal-media',false,262144000,array['video/mp4','video/webm','video/quicktime','audio/mpeg','audio/mp4','audio/wav','audio/ogg'])
on conflict(id) do update set public=false,file_size_limit=262144000;
drop policy if exists "MADAL upload own folder" on storage.objects;
create policy "MADAL upload own folder" on storage.objects for insert to authenticated with check(bucket_id='madal-media' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "MADAL play published" on storage.objects;
create policy "MADAL play published" on storage.objects for select to anon, authenticated using(bucket_id='madal-media' and exists(select 1 from public.media_posts p where p.storage_path=storage.objects.name and (p.status='published' or p.user_id=auth.uid())));
drop policy if exists "MADAL delete own files" on storage.objects;
create policy "MADAL delete own files" on storage.objects for delete to authenticated using(bucket_id='madal-media' and (storage.foldername(name))[1]=auth.uid()::text);


-- Migration for an existing MADAL database: enable video-only uploads.
alter table public.media_posts drop constraint if exists media_posts_media_type_check;
alter table public.media_posts add constraint media_posts_media_type_check check (media_type in ('video','qiso','podcast'));


-- MADAL social features migration: likes, comments, and follows.
-- Run once in Supabase SQL Editor for the existing MADAL project.

create table if not exists public.media_likes (
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.media_likes enable row level security;
drop policy if exists "MADAL likes readable" on public.media_likes;
create policy "MADAL likes readable" on public.media_likes for select to anon, authenticated using (true);
drop policy if exists "MADAL like own" on public.media_likes;
create policy "MADAL like own" on public.media_likes for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "MADAL unlike own" on public.media_likes;
create policy "MADAL unlike own" on public.media_likes for delete to authenticated using (auth.uid() = user_id);
create index if not exists media_likes_post_id_idx on public.media_likes(post_id);

create table if not exists public.media_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
alter table public.media_comments enable row level security;
drop policy if exists "MADAL comments readable" on public.media_comments;
create policy "MADAL comments readable" on public.media_comments for select to anon, authenticated using (true);
drop policy if exists "MADAL comment own" on public.media_comments;
create policy "MADAL comment own" on public.media_comments for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "MADAL delete own comment" on public.media_comments;
create policy "MADAL delete own comment" on public.media_comments for delete to authenticated using (auth.uid() = user_id);
create index if not exists media_comments_post_created_idx on public.media_comments(post_id, created_at desc);

create table if not exists public.user_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint madal_no_self_follow check (follower_id <> following_id)
);
alter table public.user_follows enable row level security;
drop policy if exists "MADAL follows readable" on public.user_follows;
create policy "MADAL follows readable" on public.user_follows for select to anon, authenticated using (true);
drop policy if exists "MADAL follow self" on public.user_follows;
create policy "MADAL follow self" on public.user_follows for insert to authenticated with check (auth.uid() = follower_id and follower_id <> following_id);
drop policy if exists "MADAL unfollow self" on public.user_follows;
create policy "MADAL unfollow self" on public.user_follows for delete to authenticated using (auth.uid() = follower_id);
create index if not exists user_follows_following_idx on public.user_follows(following_id);
