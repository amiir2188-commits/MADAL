-- MADAL Supabase setup. Run in SQL Editor.
create table if not exists public.media_posts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(char_length(title) between 1 and 140),
 description text default '',
 media_type text not null check(media_type in ('qiso','podcast')),
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
