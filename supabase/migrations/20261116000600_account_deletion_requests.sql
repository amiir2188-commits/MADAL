-- GoGol account deletion requests.
-- Users can submit and read their own requests. Only trusted administrators
-- using the Supabase service role can review or update request status.
begin;
create table if not exists public.madal_account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  status text not null default 'pending'
    check (status in ('pending','in_review','completed','rejected')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  admin_note text
);
create unique index if not exists madal_account_deletion_one_pending_idx
  on public.madal_account_deletion_requests(user_id)
  where status = 'pending';
create index if not exists madal_account_deletion_user_requested_idx
  on public.madal_account_deletion_requests(user_id, requested_at desc);
alter table public.madal_account_deletion_requests enable row level security;
revoke all on table public.madal_account_deletion_requests from anon, authenticated;
grant select, insert on table public.madal_account_deletion_requests to authenticated;
drop policy if exists "GoGol users read own deletion requests" on public.madal_account_deletion_requests;
create policy "GoGol users read own deletion requests"
  on public.madal_account_deletion_requests for select to authenticated
  using (auth.uid() = user_id);
drop policy if exists "GoGol users submit own deletion requests" on public.madal_account_deletion_requests;
create policy "GoGol users submit own deletion requests"
  on public.madal_account_deletion_requests for insert to authenticated
  with check (auth.uid() = user_id and status = 'pending');
commit;
