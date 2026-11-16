-- GoGol Stories: short-lived photo/video updates.
-- Apply after migrations 001-007. Stories expire automatically after 24 hours.
begin;

create table if not exists public.madal_stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null check (mime_type in ('image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime')),
  caption text not null default '' check (char_length(caption) <= 160),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  constraint madal_story_expiry_window check (expires_at > created_at and expires_at <= created_at + interval '24 hours'),
  constraint madal_story_owner_path check ((storage_path like user_id::text || '/stories/%'))
);

create index if not exists madal_stories_active_idx
  on public.madal_stories (expires_at desc, created_at desc);
create index if not exists madal_stories_user_active_idx
  on public.madal_stories (user_id, expires_at desc, created_at desc);

alter table public.madal_stories enable row level security;

drop policy if exists "GoGol active stories readable" on public.madal_stories;
create policy "GoGol active stories readable"
  on public.madal_stories for select to anon, authenticated
  using (expires_at > now());

drop policy if exists "GoGol users create own stories" on public.madal_stories;
create policy "GoGol users create own stories"
  on public.madal_stories for insert to authenticated
  with check (
    auth.uid() = user_id
    and expires_at > now()
    and expires_at <= now() + interval '24 hours'
    and storage_path like auth.uid()::text || '/stories/%'
  );

drop policy if exists "GoGol users delete own stories" on public.madal_stories;
create policy "GoGol users delete own stories"
  on public.madal_stories for delete to authenticated
  using (auth.uid() = user_id);

-- The existing private media bucket already restricts uploads to a user's folder.
-- Allow signed reads only while the corresponding story is active.
drop policy if exists "GoGol read active story media" on storage.objects;
create policy "GoGol read active story media"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'madal-media'
    and exists (
      select 1 from public.madal_stories s
      where s.storage_path = storage.objects.name
        and s.expires_at > now()
    )
  );

commit;
