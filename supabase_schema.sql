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


-- Public user directory for MADAL handles and direct messages.
create table if not exists public.madal_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default 'MADAL User',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.madal_profiles enable row level security;
drop policy if exists "MADAL profiles readable" on public.madal_profiles;
create policy "MADAL profiles readable" on public.madal_profiles for select to anon, authenticated using (true);
drop policy if exists "MADAL profile insert own" on public.madal_profiles;
create policy "MADAL profile insert own" on public.madal_profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "MADAL profile update own" on public.madal_profiles;
create policy "MADAL profile update own" on public.madal_profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create or replace function public.madal_create_profile()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  desired_username text;
begin
  desired_username := lower(coalesce(nullif(new.raw_user_meta_data->>'username',''), 'user_' || left(new.id::text,8)));
  insert into public.madal_profiles(id, username, display_name)
  values (
    new.id,
    desired_username,
    coalesce(nullif(new.raw_user_meta_data->>'display_name',''), 'MADAL User')
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        updated_at = now();
  return new;
end;
$$;
drop trigger if exists madal_auth_user_profile on auth.users;
create trigger madal_auth_user_profile
after insert on auth.users
for each row execute procedure public.madal_create_profile();

insert into public.madal_profiles(id, username, display_name)
select
  u.id,
  lower(coalesce(nullif(u.raw_user_meta_data->>'username',''), 'user_' || left(u.id::text,8))),
  coalesce(nullif(u.raw_user_meta_data->>'display_name',''), 'MADAL User')
from auth.users u
on conflict (id) do nothing;

-- Direct messages between two MADAL accounts.
create table if not exists public.madal_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint madal_no_self_message check (sender_id <> recipient_id)
);
alter table public.madal_messages enable row level security;
drop policy if exists "MADAL messages participants read" on public.madal_messages;
create policy "MADAL messages participants read" on public.madal_messages
for select to authenticated
using (auth.uid() = sender_id or auth.uid() = recipient_id);
drop policy if exists "MADAL messages sender insert" on public.madal_messages;
create policy "MADAL messages sender insert" on public.madal_messages
for insert to authenticated
with check (auth.uid() = sender_id and sender_id <> recipient_id);
drop policy if exists "MADAL messages recipient mark read" on public.madal_messages;
create index if not exists madal_messages_conversation_idx
on public.madal_messages(sender_id, recipient_id, created_at desc);
create index if not exists madal_messages_recipient_unread_idx
on public.madal_messages(recipient_id, read_at)
where read_at is null;


-- Enable realtime events for the feed and private messages when the default
-- Supabase realtime publication is available.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'media_posts'
    ) then
      alter publication supabase_realtime add table public.media_posts;
    end if;
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'madal_messages'
    ) then
      alter publication supabase_realtime add table public.madal_messages;
    end if;
  end if;
end
$$;
