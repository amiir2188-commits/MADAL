-- MADAL video view counts.
-- Run once in Supabase SQL Editor before using the new view counter.

alter table public.media_posts
  add column if not exists view_count bigint not null default 0;

create or replace function public.madal_record_post_view(p_post_id uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count bigint;
begin
  update public.media_posts
  set view_count = coalesce(view_count, 0) + 1
  where id = p_post_id
    and status = 'published'
    and (not coalesce(is_private, false) or auth.uid() = user_id)
  returning view_count into updated_count;

  return coalesce(updated_count, 0);
end;
$$;

revoke all on function public.madal_record_post_view(uuid) from public;
grant execute on function public.madal_record_post_view(uuid) to anon, authenticated;
