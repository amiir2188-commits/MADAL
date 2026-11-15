-- MADAL photo upload migration.
-- Run this once in Supabase SQL Editor before publishing photo posts.

alter table public.media_posts
  add column if not exists mime_type text;

alter table public.media_posts
  drop constraint if exists media_posts_media_type_check;

alter table public.media_posts
  add constraint media_posts_media_type_check
  check (media_type in ('video','image','qiso','podcast'));

update storage.buckets
set allowed_mime_types = array[
  'video/mp4','video/webm','video/quicktime',
  'image/jpeg','image/png','image/webp','image/gif',
  'audio/mpeg','audio/mp4','audio/wav','audio/ogg'
]
where id = 'madal-media';
