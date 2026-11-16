-- MADAL: repair PostgreSQL privileges for likes.
-- Run this script in Supabase SQL Editor for the existing project.
-- Grants fix table-level permission errors; RLS policies still restrict rows.

grant usage on schema public to anon, authenticated;
grant select on table public.media_likes to anon, authenticated;
grant insert, delete on table public.media_likes to authenticated;

alter table public.media_likes enable row level security;

drop policy if exists madal_likes_add on public.media_likes;
create policy madal_likes_add
on public.media_likes
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.media_posts p
    where p.id = media_likes.post_id
      and p.status = 'published'
      and (not coalesce(p.is_private, false) or p.user_id = (select auth.uid()))
  )
);

drop policy if exists madal_likes_read on public.media_likes;
drop policy if exists "MADAL likes readable" on public.media_likes;
create policy "MADAL likes readable"
on public.media_likes
for select
to anon, authenticated
using (true);

drop policy if exists madal_likes_delete on public.media_likes;
drop policy if exists "MADAL unlike own" on public.media_likes;
create policy "MADAL unlike own"
on public.media_likes
for delete
to authenticated
using (user_id = (select auth.uid()));
