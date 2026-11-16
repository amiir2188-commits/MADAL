-- GoGol 1.10.13 compatibility and upload support.
-- Safe schema-only migration: no existing posts or messages are deleted.
begin;

-- The app supports image posts as well as video, qiso and podcast records.
alter table public.media_posts
  drop constraint if exists media_posts_media_type_check;
alter table public.media_posts
  add constraint media_posts_media_type_check
  check (media_type in ('video','image','qiso','podcast'));

-- Keep the database limit aligned with the 4,000-character message composer.
alter table public.madal_messages
  drop constraint if exists madal_messages_body_check;
alter table public.madal_messages
  add constraint madal_messages_body_check
  check (char_length(body) between 1 and 4000);

-- Keep the private media bucket's upload policy aligned with supported formats.
update storage.buckets
set file_size_limit = 262144000,
    allowed_mime_types = array[
      'video/mp4','video/webm','video/quicktime',
      'image/jpeg','image/png','image/webp','image/gif',
      'audio/mpeg','audio/mp4','audio/wav','audio/ogg'
    ]
where id = 'madal-media';

commit;
