-- MADAL profile enhancements: run once in Supabase SQL Editor.
alter table public.madal_profiles
  add column if not exists bio text not null default '',
  add column if not exists avatar_url text;

alter table public.madal_profiles
  drop constraint if exists madal_profiles_bio_length_check;
alter table public.madal_profiles
  add constraint madal_profiles_bio_length_check check (char_length(bio) <= 160);

-- Keep profile updates limited to the authenticated account.
drop policy if exists "MADAL profile update own" on public.madal_profiles;
create policy "MADAL profile update own" on public.madal_profiles
for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Allow an account owner to create their own profile if it was not created
-- by the auth trigger (for older accounts).
drop policy if exists "MADAL profile insert own" on public.madal_profiles;
create policy "MADAL profile insert own" on public.madal_profiles
for insert to authenticated
with check (auth.uid() = id);

-- Public profile-photo bucket. Each signed-in user can manage files only
-- inside their own UUID folder; everyone can view public profile pictures.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('madal-avatars', 'madal-avatars', true, 5242880,
        array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "MADAL avatar images public read" on storage.objects;
create policy "MADAL avatar images public read" on storage.objects
for select to anon, authenticated
using (bucket_id = 'madal-avatars');

drop policy if exists "MADAL avatar upload own folder" on storage.objects;
create policy "MADAL avatar upload own folder" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'madal-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "MADAL avatar update own folder" on storage.objects;
create policy "MADAL avatar update own folder" on storage.objects
for update to authenticated
using (
  bucket_id = 'madal-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'madal-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "MADAL avatar delete own folder" on storage.objects;
create policy "MADAL avatar delete own folder" on storage.objects
for delete to authenticated
using (
  bucket_id = 'madal-avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
