-- GoGol safety controls: user blocks and user-submitted moderation reports.
-- Apply this migration in the Supabase SQL Editor before enabling these controls in production.
create table if not exists public.madal_user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_user_id),
  constraint madal_user_blocks_no_self check (blocker_id <> blocked_user_id)
);

alter table public.madal_user_blocks enable row level security;
revoke all on table public.madal_user_blocks from anon, authenticated;
grant select, insert, delete on table public.madal_user_blocks to authenticated;

drop policy if exists "GoGol users read own blocks" on public.madal_user_blocks;
create policy "GoGol users read own blocks"
  on public.madal_user_blocks for select to authenticated
  using (auth.uid() = blocker_id);

drop policy if exists "GoGol users create own blocks" on public.madal_user_blocks;
create policy "GoGol users create own blocks"
  on public.madal_user_blocks for insert to authenticated
  with check (auth.uid() = blocker_id and blocker_id <> blocked_user_id);

drop policy if exists "GoGol users remove own blocks" on public.madal_user_blocks;
create policy "GoGol users remove own blocks"
  on public.madal_user_blocks for delete to authenticated
  using (auth.uid() = blocker_id);

create index if not exists madal_user_blocks_blocked_idx
  on public.madal_user_blocks(blocked_user_id);

create table if not exists public.madal_moderation_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid references auth.users(id) on delete set null,
  post_id uuid references public.media_posts(id) on delete set null,
  reason text not null check (reason in ('spam','harassment','hate','violence','nudity','misinformation','other')),
  created_at timestamptz not null default now(),
  constraint madal_moderation_reports_target_required
    check (reported_user_id is not null or post_id is not null),
  constraint madal_moderation_reports_not_self
    check (reported_user_id is null or reported_user_id <> reporter_id)
);

alter table public.madal_moderation_reports enable row level security;
revoke all on table public.madal_moderation_reports from anon, authenticated;
grant select, insert on table public.madal_moderation_reports to authenticated;

drop policy if exists "GoGol users read own reports" on public.madal_moderation_reports;
create policy "GoGol users read own reports"
  on public.madal_moderation_reports for select to authenticated
  using (auth.uid() = reporter_id);

drop policy if exists "GoGol users submit reports" on public.madal_moderation_reports;
create policy "GoGol users submit reports"
  on public.madal_moderation_reports for insert to authenticated
  with check (auth.uid() = reporter_id);

create index if not exists madal_moderation_reports_created_idx
  on public.madal_moderation_reports(created_at desc);
create index if not exists madal_moderation_reports_post_idx
  on public.madal_moderation_reports(post_id) where post_id is not null;
