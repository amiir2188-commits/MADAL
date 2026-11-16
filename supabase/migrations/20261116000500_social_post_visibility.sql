-- GoGol: prevent likes and comments from exposing or targeting hidden posts.
-- Safe to apply to an existing database; no rows are deleted or rewritten.
begin;

drop policy if exists "MADAL likes readable" on public.media_likes;
create policy "MADAL likes readable" on public.media_likes
for select to anon, authenticated
using (exists (
  select 1 from public.media_posts p
  where p.id = media_likes.post_id
    and (p.status = 'published' or p.user_id = auth.uid())
));

drop policy if exists "MADAL like own" on public.media_likes;
create policy "MADAL like own" on public.media_likes
for insert to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.media_posts p
    where p.id = media_likes.post_id and p.status = 'published'
  )
);

drop policy if exists "MADAL comments readable" on public.media_comments;
create policy "MADAL comments readable" on public.media_comments
for select to anon, authenticated
using (exists (
  select 1 from public.media_posts p
  where p.id = media_comments.post_id
    and (p.status = 'published' or p.user_id = auth.uid())
));

drop policy if exists "MADAL comment own" on public.media_comments;
create policy "MADAL comment own" on public.media_comments
for insert to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.media_posts p
    where p.id = media_comments.post_id and p.status = 'published'
  )
);

commit;
