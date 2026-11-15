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
