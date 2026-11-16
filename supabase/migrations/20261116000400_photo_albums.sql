-- GoGol photo albums: group up to 10 photo posts under one album ID.
-- Apply in Supabase SQL Editor before using multi-photo album uploads.
begin;
alter table public.media_posts
  add column if not exists album_id uuid;
create index if not exists media_posts_album_id_created_idx
  on public.media_posts(album_id, created_at, id)
  where album_id is not null;
comment on column public.media_posts.album_id is
  'Shared UUID grouping multiple photo posts into one GoGol photo album.';
commit;
