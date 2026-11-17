-- GoGol: keep sign-up working when a requested username is already taken.
-- Existing profile rows and usernames are not changed by this migration.
begin;

create or replace function public.madal_create_profile()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  desired_username text;
  candidate_username text;
  suffix text;
  attempt integer;
  safe_display_name text;
begin
  desired_username := lower(regexp_replace(
    coalesce(
      nullif(btrim(new.raw_user_meta_data->>'username'), ''),
      'user_' || left(replace(new.id::text, '-', ''), 8)
    ),
    '[^a-z0-9_]', '', 'g'
  ));
  desired_username := left(desired_username, 24);

  if char_length(desired_username) < 3 then
    desired_username := 'user_' || left(replace(new.id::text, '-', ''), 8);
  end if;

  safe_display_name := coalesce(
    nullif(btrim(new.raw_user_meta_data->>'display_name'), ''),
    'GoGol User'
  );

  -- Retry with a stable UUID-derived suffix if another account owns the name.
  -- Catching unique_violation also handles two sign-ups racing for the same name.
  for attempt in 1..100 loop
    if attempt = 1 then
      candidate_username := desired_username;
    else
      suffix := left(replace(new.id::text, '-', ''), 8) || attempt::text;
      candidate_username := left(desired_username, 24 - char_length(suffix) - 1)
        || '_' || suffix;
    end if;

    begin
      insert into public.madal_profiles(id, username, display_name)
      values (new.id, candidate_username, safe_display_name)
      on conflict (id) do update
        set display_name = excluded.display_name,
            updated_at = now();
      return new;
    exception
      when unique_violation then
        if attempt = 100 then
          raise;
        end if;
    end;
  end loop;

  return new;
end;
$$;

commit;
