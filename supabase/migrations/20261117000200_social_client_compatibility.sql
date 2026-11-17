-- GoGol social compatibility: ensure every table and column used by the
-- current client exists, with row-level security and private-post protection.
-- Legacy madal_follows/madal_shares tables are left untouched.
begin;

alter table public.media_posts
  add column if not exists is_private boolean not null default false;

alter table public.madal_profiles
  add column if not exists is_verified boolean not null default false;

-- Public follow graph. The client uses user_follows (not legacy madal_follows).
create table if not exists public.user_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint gogol_no_self_follow check (follower_id <> following_id)
);
alter table public.user_follows enable row level security;
revoke all on table public.user_follows from anon, authenticated;
grant select on table public.user_follows to anon, authenticated;
grant insert, delete on table public.user_follows to authenticated;
drop policy if exists "MADAL follows readable" on public.user_follows;
drop policy if exists "MADAL follow self" on public.user_follows;
drop policy if exists "MADAL unfollow self" on public.user_follows;
drop policy if exists "GoGol follows public read" on public.user_follows;
create policy "GoGol follows public read" on public.user_follows
  for select to anon, authenticated using (true);
drop policy if exists "GoGol follow own" on public.user_follows;
create policy "GoGol follow own" on public.user_follows
  for insert to authenticated
  with check (auth.uid() = follower_id and follower_id <> following_id);
drop policy if exists "GoGol unfollow own" on public.user_follows;
create policy "GoGol unfollow own" on public.user_follows
  for delete to authenticated using (auth.uid() = follower_id);
create index if not exists user_follows_following_idx
  on public.user_follows(following_id);

-- Reposts are public only when the source post is publicly visible.
create table if not exists public.media_reposts (
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.media_reposts enable row level security;
revoke all on table public.media_reposts from anon, authenticated;
grant select on table public.media_reposts to anon, authenticated;
grant insert, delete on table public.media_reposts to authenticated;
drop policy if exists "MADAL reposts readable" on public.media_reposts;
drop policy if exists "MADAL repost own" on public.media_reposts;
drop policy if exists "MADAL unrepost own" on public.media_reposts;
drop policy if exists "GoGol visible reposts read" on public.media_reposts;
create policy "GoGol visible reposts read" on public.media_reposts
  for select to anon, authenticated
  using (exists (
    select 1 from public.media_posts p
    where p.id = media_reposts.post_id
      and p.status = 'published'
      and (not p.is_private or p.user_id = auth.uid())
  ));
drop policy if exists "GoGol repost own visible post" on public.media_reposts;
create policy "GoGol repost own visible post" on public.media_reposts
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.media_posts p
      where p.id = media_reposts.post_id
        and p.status = 'published'
        and not p.is_private
    )
  );
drop policy if exists "GoGol unrepost own" on public.media_reposts;
create policy "GoGol unrepost own" on public.media_reposts
  for delete to authenticated using (auth.uid() = user_id);
create index if not exists media_reposts_user_created_idx
  on public.media_reposts(user_id, created_at desc);
create index if not exists media_reposts_post_idx
  on public.media_reposts(post_id);

-- Saved posts are private to the account that saved them.
create table if not exists public.media_favorites (
  post_id uuid not null references public.media_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.media_favorites enable row level security;
revoke all on table public.media_favorites from anon, authenticated;
grant select, insert, delete on table public.media_favorites to authenticated;
drop policy if exists "MADAL favorites own read" on public.media_favorites;
drop policy if exists "MADAL favorites own insert" on public.media_favorites;
drop policy if exists "MADAL favorites own delete" on public.media_favorites;
drop policy if exists "GoGol favorites own read" on public.media_favorites;
create policy "GoGol favorites own read" on public.media_favorites
  for select to authenticated using (auth.uid() = user_id);
drop policy if exists "GoGol favorites own insert" on public.media_favorites;
create policy "GoGol favorites own insert" on public.media_favorites
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.media_posts p
      where p.id = media_favorites.post_id
        and (p.status = 'published' or p.user_id = auth.uid())
        and (not p.is_private or p.user_id = auth.uid())
    )
  );
drop policy if exists "GoGol favorites own delete" on public.media_favorites;
create policy "GoGol favorites own delete" on public.media_favorites
  for delete to authenticated using (auth.uid() = user_id);
create index if not exists media_favorites_user_created_idx
  on public.media_favorites(user_id, created_at desc);

-- Keep likes and comments from leaking metadata about private posts.
drop policy if exists madal_likes_read on public.media_likes;
drop policy if exists madal_likes_add on public.media_likes;
drop policy if exists madal_likes_delete on public.media_likes;
drop policy if exists "MADAL likes readable" on public.media_likes;
create policy "MADAL likes readable" on public.media_likes
  for select to anon, authenticated
  using (exists (
    select 1 from public.media_posts p
    where p.id = media_likes.post_id
      and p.status = 'published'
      and (not p.is_private or p.user_id = auth.uid())
  ));
drop policy if exists "MADAL like own" on public.media_likes;
create policy "MADAL like own" on public.media_likes
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.media_posts p
      where p.id = media_likes.post_id
        and p.status = 'published'
        and not p.is_private
    )
  );

drop policy if exists "MADAL comments readable" on public.media_comments;
create policy "MADAL comments readable" on public.media_comments
  for select to anon, authenticated
  using (exists (
    select 1 from public.media_posts p
    where p.id = media_comments.post_id
      and p.status = 'published'
      and (not p.is_private or p.user_id = auth.uid())
  ));
drop policy if exists "MADAL comment own" on public.media_comments;
create policy "MADAL comment own" on public.media_comments
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.media_posts p
      where p.id = media_comments.post_id
        and p.status = 'published'
        and not p.is_private
    )
  );

-- Enforce private-post visibility in both the database and media storage.
grant update on table public.media_posts to authenticated;
drop policy if exists "MADAL owner update own media" on public.media_posts;
create policy "MADAL owner update own media" on public.media_posts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "MADAL read published" on public.media_posts;
create policy "MADAL read published" on public.media_posts
  for select to anon, authenticated
  using (
    (status = 'published' and (not is_private or auth.uid() = user_id))
    or auth.uid() = user_id
  );

drop policy if exists "MADAL play published" on storage.objects;
create policy "MADAL play published" on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'madal-media'
    and exists (
      select 1 from public.media_posts p
      where p.storage_path = storage.objects.name
        and p.status = 'published'
        and (not p.is_private or auth.uid() = p.user_id)
    )
  );

-- A normal signed-in user cannot assign or remove a verification badge.
create or replace function public.madal_protect_verified_flag()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is not null then
    if tg_op = 'INSERT' and new.is_verified then
      raise exception 'GoGol verification can only be assigned by an administrator';
    elsif tg_op = 'UPDATE' and new.is_verified is distinct from old.is_verified then
      raise exception 'GoGol verification can only be changed by an administrator';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists gogol_verified_flag_guard on public.madal_profiles;
create trigger gogol_verified_flag_guard
  before insert or update of is_verified on public.madal_profiles
  for each row execute function public.madal_protect_verified_flag();

commit;
