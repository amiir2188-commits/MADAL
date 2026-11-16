-- GoGol: allow recipients to mark only their own incoming messages as read.
-- Safe for existing installations: does not alter or delete message rows.
-- Run this migration in the Supabase SQL Editor.

begin;

drop policy if exists "MADAL messages recipient mark read" on public.madal_messages;
create policy "MADAL messages recipient mark read"
on public.madal_messages
for update
to authenticated
using (auth.uid() = recipient_id)
with check (auth.uid() = recipient_id);

-- Limit authenticated users to changing read_at only; the app must not be
-- able to rewrite message bodies or participant IDs through this policy.
revoke update on table public.madal_messages from authenticated;
grant update (read_at) on table public.madal_messages to authenticated;

commit;
