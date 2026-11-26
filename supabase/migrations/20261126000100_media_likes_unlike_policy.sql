-- GoGol: restore the ability for authenticated users to unlike their own posts.
-- This is additive and does not delete or modify existing rows.
begin;

grant usage on schema public to authenticated;
grant select on table public.media_likes to anon, authenticated;
grant insert, delete on table public.media_likes to authenticated;

drop policy if exists "GoGol unlike own" on public.media_likes;
create policy "GoGol unlike own"
  on public.media_likes
  for delete
  to authenticated
  using (auth.uid() = user_id);

commit;
