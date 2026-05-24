create extension if not exists "pgcrypto";

create table if not exists invite_codes (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  created_by  uuid references auth.users(id),
  used_by     uuid references auth.users(id),
  used_at     timestamptz,
  expires_at  timestamptz not null default (now() + interval '30 days'),
  revoked     boolean not null default false,
  created_at  timestamptz not null default now()
);

insert into invite_codes (code, expires_at)
values ('TRIPPLAN2026', now() + interval '365 days')
on conflict (code) do nothing;

create table if not exists profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  name           text not null default '',
  home_town      text,
  vehicle_name   text,
  vehicle_type   text check (vehicle_type in ('car','campervan','motorhome','motorcycle')),
  is_admin       boolean not null default false,
  setup_complete boolean not null default false,
  created_at     timestamptz not null default now()
);

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

create table if not exists user_settings (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  claude_api_key text,
  distance_unit  text not null default 'metric' check (distance_unit in ('metric','imperial')),
  currency       text not null default 'GBP',
  updated_at     timestamptz not null default now()
);

create table if not exists trips (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  status      text not null default 'draft'
                check (status in ('draft','generating','ready','error')),
  start_date  date,
  end_date    date,
  is_shared   boolean not null default false,
  intake_form jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists idx_trips_owner_id on trips(owner_id);
create index if not exists idx_trips_is_shared on trips(is_shared) where is_shared = true;

create table if not exists trip_data (
  trip_id    uuid primary key references trips(id) on delete cascade,
  data       jsonb not null,
  version    integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table profiles      enable row level security;
alter table user_settings enable row level security;
alter table trips         enable row level security;
alter table trip_data     enable row level security;
alter table invite_codes  enable row level security;

drop policy if exists "profiles_own" on profiles;
create policy "profiles_own" on profiles for all using (auth.uid() = id);

drop policy if exists "settings_own" on user_settings;
create policy "settings_own" on user_settings for all using (auth.uid() = user_id);

drop policy if exists "trips_owner" on trips;
create policy "trips_owner" on trips for all using (auth.uid() = owner_id);

drop policy if exists "trips_shared_read" on trips;
create policy "trips_shared_read" on trips
  for select using (is_shared = true and auth.uid() is not null);

drop policy if exists "trip_data_owner" on trip_data;
create policy "trip_data_owner" on trip_data
  for all using (
    trip_id in (select id from trips where owner_id = auth.uid())
  );

drop policy if exists "trip_data_shared" on trip_data;
create policy "trip_data_shared" on trip_data
  for select using (
    trip_id in (select id from trips where is_shared = true)
  );

drop policy if exists "invite_codes_read" on invite_codes;
create policy "invite_codes_read" on invite_codes for select using (true);

create or replace function create_invite_code(p_code text, p_days_valid int default 30)
returns void as $$
begin
  insert into invite_codes (code, expires_at)
  values (upper(trim(p_code)), now() + (p_days_valid || ' days')::interval);
end;
$$ language plpgsql security definer;
