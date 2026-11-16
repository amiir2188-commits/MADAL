-- Prevent one account from opening multiple simultaneous GoGol LIVE rooms.
begin;

create unique index if not exists madal_live_sessions_one_active_per_host_idx
  on public.madal_live_sessions (host_id)
  where status = 'live';

create index if not exists madal_live_sessions_heartbeat_idx
  on public.madal_live_sessions (last_heartbeat_at)
  where status = 'live';

commit;
