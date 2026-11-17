-- GoGol LIVE gifts, wallet ledger and persistent live chat.
-- Wallets start at zero. This migration does not charge users or mint free coins.
begin;

create table if not exists public.madal_live_gift_catalog (
  code text primary key,
  title text not null,
  emoji text not null,
  coin_price integer not null check (coin_price > 0),
  is_active boolean not null default true,
  sort_order integer not null default 0
);
insert into public.madal_live_gift_catalog(code,title,emoji,coin_price,sort_order) values
 ('rose','Ubax','🌹',1,10),
 ('heart','Qalbi','❤️',5,20),
 ('coffee','Qaxwo','☕',10,30),
 ('crown','Taaj','👑',50,40),
 ('galaxy','Galaxy','🌌',100,50),
 ('lion','Libaax','🦁',500,60)
on conflict (code) do update set title=excluded.title,emoji=excluded.emoji,coin_price=excluded.coin_price,sort_order=excluded.sort_order;

alter table public.madal_live_gift_catalog enable row level security;
revoke all on public.madal_live_gift_catalog from anon, authenticated;
grant select on public.madal_live_gift_catalog to authenticated;
drop policy if exists "GoGol authenticated users read gift catalog" on public.madal_live_gift_catalog;
create policy "GoGol authenticated users read gift catalog" on public.madal_live_gift_catalog
 for select to authenticated using (is_active=true);

create table if not exists public.madal_live_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  coins bigint not null default 0 check (coins >= 0),
  diamonds bigint not null default 0 check (diamonds >= 0),
  updated_at timestamptz not null default now()
);
alter table public.madal_live_wallets enable row level security;
revoke all on public.madal_live_wallets from anon, authenticated;
grant select on public.madal_live_wallets to authenticated;
drop policy if exists "GoGol users read own live wallet" on public.madal_live_wallets;
create policy "GoGol users read own live wallet" on public.madal_live_wallets
 for select to authenticated using (auth.uid() = user_id);

create table if not exists public.madal_live_wallet_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_type text not null check (entry_type in ('gift_sent','gift_received','coin_purchase','admin_adjustment')),
  coin_delta bigint not null default 0,
  diamond_delta bigint not null default 0,
  reference_id uuid,
  note text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists madal_live_wallet_ledger_user_idx
 on public.madal_live_wallet_ledger(user_id,created_at desc);
alter table public.madal_live_wallet_ledger enable row level security;
revoke all on public.madal_live_wallet_ledger from anon, authenticated;
grant select on public.madal_live_wallet_ledger to authenticated;
drop policy if exists "GoGol users read own wallet ledger" on public.madal_live_wallet_ledger;
create policy "GoGol users read own wallet ledger" on public.madal_live_wallet_ledger
 for select to authenticated using (auth.uid() = user_id);

create table if not exists public.madal_live_gifts (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.madal_live_sessions(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  gift_code text not null references public.madal_live_gift_catalog(code),
  quantity integer not null check (quantity between 1 and 20),
  coin_cost bigint not null check (coin_cost > 0),
  created_at timestamptz not null default now()
);
create index if not exists madal_live_gifts_session_idx
 on public.madal_live_gifts(session_id,created_at desc);
alter table public.madal_live_gifts enable row level security;
revoke all on public.madal_live_gifts from anon, authenticated;
grant select on public.madal_live_gifts to authenticated;
drop policy if exists "GoGol live viewers see gifts in active room" on public.madal_live_gifts;
create policy "GoGol live viewers see gifts in active room" on public.madal_live_gifts
 for select to authenticated using (exists (
  select 1 from public.madal_live_sessions s
  where s.id=madal_live_gifts.session_id and s.status='live'
 ));

create table if not exists public.madal_live_comments (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.madal_live_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 300),
  created_at timestamptz not null default now()
);
create index if not exists madal_live_comments_session_idx
 on public.madal_live_comments(session_id,created_at desc);
alter table public.madal_live_comments enable row level security;
revoke all on public.madal_live_comments from anon, authenticated;
grant select,insert on public.madal_live_comments to authenticated;
drop policy if exists "GoGol viewers read active live chat" on public.madal_live_comments;
create policy "GoGol viewers read active live chat" on public.madal_live_comments
 for select to authenticated using (exists (
  select 1 from public.madal_live_sessions s where s.id=madal_live_comments.session_id and s.status='live'
 ));
drop policy if exists "GoGol users write own active live chat" on public.madal_live_comments;
create policy "GoGol users write own active live chat" on public.madal_live_comments
 for insert to authenticated with check (
  auth.uid()=user_id and exists (
   select 1 from public.madal_live_sessions s where s.id=madal_live_comments.session_id and s.status='live'
  )
 );


create or replace function public.madal_get_live_wallet()
returns table(coins bigint, diamonds bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $
begin
 if auth.uid() is null then raise exception 'Fadlan gal akoonkaaga.'; end if;
 insert into public.madal_live_wallets(user_id) values(auth.uid()) on conflict(user_id) do nothing;
 return query select w.coins,w.diamonds from public.madal_live_wallets w where w.user_id=auth.uid();
end;
$;
revoke all on function public.madal_get_live_wallet() from public, anon;
grant execute on function public.madal_get_live_wallet() to authenticated;

create or replace function public.madal_send_live_gift(
 p_session_id uuid,
 p_gift_code text,
 p_quantity integer default 1
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
 v_sender uuid := auth.uid();
 v_receiver uuid;
 v_price integer;
 v_total bigint;
 v_gift public.madal_live_gifts%rowtype;
 v_balance bigint;
begin
 if v_sender is null then raise exception 'Fadlan gal akoonkaaga.'; end if;
 if p_quantity is null or p_quantity < 1 or p_quantity > 20 then
  raise exception 'Tirada hadiyadda waa inay u dhexaysaa 1 ilaa 20.';
 end if;
 select host_id into v_receiver from public.madal_live_sessions
  where id=p_session_id and status='live' and last_heartbeat_at > now()-interval '3 minutes'
  for update;
 if v_receiver is null then raise exception 'LIVE-kan hadda ma socdo.'; end if;
 if v_receiver=v_sender then raise exception 'Naftaada hadiyad uma diri kartid.'; end if;
 select coin_price into v_price from public.madal_live_gift_catalog
  where code=p_gift_code and is_active=true;
 if v_price is null then raise exception 'Hadiyaddan lama heli karo.'; end if;
 v_total := v_price::bigint * p_quantity;
 insert into public.madal_live_wallets(user_id) values(v_sender),(v_receiver)
  on conflict(user_id) do nothing;
 select coins into v_balance from public.madal_live_wallets where user_id=v_sender for update;
 if v_balance < v_total then raise exception 'Coins kugu filan ma jiraan. Fadlan ku shubo wallet-ka.'; end if;
 update public.madal_live_wallets set coins=coins-v_total,updated_at=now() where user_id=v_sender;
 update public.madal_live_wallets set diamonds=diamonds+v_total,updated_at=now() where user_id=v_receiver;
 insert into public.madal_live_gifts(session_id,sender_id,receiver_id,gift_code,quantity,coin_cost)
 values(p_session_id,v_sender,v_receiver,p_gift_code,p_quantity,v_total) returning * into v_gift;
 insert into public.madal_live_wallet_ledger(user_id,entry_type,coin_delta,reference_id,note)
 values(v_sender,'gift_sent',-v_total,v_gift.id,p_gift_code);
 insert into public.madal_live_wallet_ledger(user_id,entry_type,diamond_delta,reference_id,note)
 values(v_receiver,'gift_received',v_total,v_gift.id,p_gift_code);
 return jsonb_build_object('gift_id',v_gift.id,'coins_spent',v_total,'gift_code',p_gift_code,'quantity',p_quantity);
end;
$$;
revoke all on function public.madal_send_live_gift(uuid,text,integer) from public, anon;
grant execute on function public.madal_send_live_gift(uuid,text,integer) to authenticated;

do $$
begin
 if exists (select 1 from pg_publication where pubname='supabase_realtime') then
  begin alter publication supabase_realtime add table public.madal_live_comments; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.madal_live_gifts; exception when duplicate_object then null; end;
 end if;
end $$;

commit;
