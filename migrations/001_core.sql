-- Core tables shared by the split engine.

create table if not exists kv (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- The live coin. Filled by the launch listener when the deploy wallet creates it.
create table if not exists token_state (
  id int primary key default 1 check (id = 1),
  mint text not null,
  decimals int not null,
  create_sig text,
  detected_at timestamptz not null default now()
);

create table if not exists snapshots (
  id bigserial primary key,
  taken_at timestamptz not null default now(),
  token_price_usd double precision,
  sol_usd double precision,
  holder_count int not null default 0
);

create table if not exists snapshot_balances (
  snapshot_id bigint not null references snapshots(id) on delete cascade,
  wallet text not null,
  amount numeric(39, 0) not null,
  primary key (snapshot_id, wallet)
);

-- Money coming in: creator fee claims (or terminal fees moved in for zero).
create table if not exists inflows (
  id bigserial primary key,
  at timestamptz not null default now(),
  kind text not null,
  lamports bigint not null,
  move_lamports bigint not null default 0,
  signature text,
  last_valid_height bigint,
  move_signature text,
  move_valid_height bigint,
  status text not null default 'planned',
  split_id bigint,
  meta jsonb,
  error text
);
create index if not exists inflows_status on inflows (status);

create table if not exists splits (
  id bigserial primary key,
  at timestamptz not null default now(),
  snapshot_id bigint references snapshots(id) on delete set null,
  prev_snapshot_id bigint,
  source_lamports bigint not null default 0,
  holder_share_lamports bigint not null default 0,
  carry_in bigint not null default 0,
  costs_recovered bigint not null default 0,
  pool_lamports bigint not null default 0,
  allocated_lamports bigint not null default 0,
  carry_out bigint not null default 0,
  eligible_count int not null default 0,
  eligible_tokens numeric(39, 0) not null default 0,
  min_raw numeric(39, 0),
  token_price_usd double precision,
  sol_usd double precision,
  note text
);

create table if not exists split_shares (
  split_id bigint not null references splits(id) on delete cascade,
  wallet text not null,
  balance numeric(39, 0) not null,
  lamports bigint not null,
  primary key (split_id, wallet)
);
create index if not exists split_shares_wallet on split_shares (wallet);

create table if not exists accounts (
  wallet text primary key,
  owed_lamports bigint not null default 0 check (owed_lamports >= 0),
  earned_lamports bigint not null default 0,
  paid_lamports bigint not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists payouts (
  id bigserial primary key,
  wallet text not null,
  route text not null,
  dest text not null,
  lamports bigint not null,
  cost_lamports bigint not null default 0,
  out_amount text,
  out_symbol text,
  signature text,
  last_valid_height bigint,
  status text not null default 'planned',
  not_before timestamptz not null default now(),
  deposit_address text,
  deposit_memo text,
  correlation_id text,
  out_tx text,
  error text,
  batch_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists payouts_status on payouts (status);
create index if not exists payouts_wallet on payouts (wallet);

-- Network and route costs the treasury paid, recovered from later pools when DEDUCT_COSTS is on.
create table if not exists costs (
  id bigserial primary key,
  at timestamptz not null default now(),
  kind text not null,
  lamports bigint not null,
  signature text,
  recovered boolean not null default false
);

create table if not exists nonces (
  nonce text primary key,
  wallet text not null,
  purpose text not null,
  expires_at timestamptz not null,
  used_at timestamptz
);

create table if not exists sessions (
  token_hash text primary key,
  wallet text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create table if not exists preferences (
  wallet text primary key,
  route text not null,
  dest text,
  signed_message text not null,
  signature text not null,
  updated_at timestamptz not null default now()
);
