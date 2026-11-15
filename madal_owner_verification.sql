-- MADAL official-owner verification.
-- Run this once in Supabase SQL Editor using the project owner/admin session.
-- The username was confirmed by the account owner in ChatGPT.
-- This does not expose any client-side way for users to grant themselves a badge.

do $$
declare
  changed_rows integer;
begin
  update public.madal_profiles
     set is_verified = true
   where lower(username) = 'suhayb01';

  get diagnostics changed_rows = row_count;

  if changed_rows <> 1 then
    raise exception 'Expected exactly one MADAL profile for @suhayb01; updated % rows. No badge was assigned.', changed_rows;
  end if;
end
$$;

-- Confirm the result:
select username, display_name, is_verified
from public.madal_profiles
where lower(username) = 'suhayb01';
