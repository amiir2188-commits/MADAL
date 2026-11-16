-- GoGol LIVE sessions. Media transport is provided by LiveKit; credentials never reach the browser.
begin;

create table if not exists public.madal_live_sessions (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  room_name text not null unique,
  title text not null default 'GoGol LIVE' check (char_length(title) between 1 and 100),
  status text not null default 'live' check (status in ('live','ended')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create index if not exists madal_live_sessions_active_idx
  on public.madal_live_sessions (started_at desc) where status = 'live';
create index if not exists madal_live_sessions_host_idx
  on public.madal_live_sessions (host_id, started_at desc);

alter table public.madal_live_sessions enable row level security;

drop policy if exists "GoGol active LIVE sessions are public" on public.madal_live_sessions;
create policy "GoGol active LIVE sessions are public"
  on public.madal_live_sessions for select to anon, authenticated
  using (status = 'live');

drop policy if exists "GoGol hosts create own LIVE sessions" on public.madal_live_sessions;
create policy "GoGol hosts create own LIVE sessions"
  on public.madal_live_sessions for insert to authenticated
  with check (auth.uid() = host_id and status = 'live' and ended_at is null);

drop policy if exists "GoGol hosts end own LIVE sessions" on public.madal_live_sessions;
create policy "GoGol hosts end own LIVE sessions"
  on public.madal_live_sessions for update to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id and status = 'ended' and ended_at is not null);

commit;
