-- BBW WMS Schema
-- Run this in Supabase SQL Editor

-- Staged items per aisle
create table if not exists bbw_staged (
  id            uuid primary key default gen_random_uuid(),
  aisle_id      text not null,
  dept          text not null,
  item_name     text not null,
  sku           text,
  qty_original  numeric not null,
  qty_current   numeric not null,
  unit          text default 'units',
  pallets       numeric default 0,
  staged_by     text not null,
  staged_at     timestamptz default now(),
  status        text default 'active', -- active | depleted | returned
  notes         text
);

-- Transaction log (consume / return / stage / adjust)
create table if not exists bbw_transactions (
  id          uuid primary key default gen_random_uuid(),
  staged_id   uuid references bbw_staged(id),
  aisle_id    text not null,
  item_name   text not null,
  tx_type     text not null, -- stage | consume | return | adjust
  qty         numeric not null,
  actor       text not null,
  actor_role  text,
  tx_at       timestamptz default now(),
  notes       text
);

-- Inventory master (simple SKU list for warehouse manager)
create table if not exists bbw_inventory (
  id          uuid primary key default gen_random_uuid(),
  sku         text unique not null,
  name        text not null,
  category    text,
  unit        text default 'units',
  qty_on_hand numeric default 0,
  reorder_lvl numeric default 0,
  location    text,
  notes       text,
  updated_at  timestamptz default now()
);

-- Forklift inspections (existing table — keep as-is, just ensure RLS allows anon)
create table if not exists inspections (
  id           uuid primary key default gen_random_uuid(),
  equipment_id text,
  driver_name  text,
  shift        text,
  submitted_at timestamptz default now(),
  keyoff       jsonb,
  keyon        jsonb,
  passed       boolean default true,
  notes        text
);

-- RLS: allow anon read/write on all bbw tables
alter table bbw_staged      enable row level security;
alter table bbw_transactions enable row level security;
alter table bbw_inventory    enable row level security;
alter table inspections      enable row level security;

drop policy if exists "anon all bbw_staged"       on bbw_staged;
drop policy if exists "anon all bbw_transactions" on bbw_transactions;
drop policy if exists "anon all bbw_inventory"    on bbw_inventory;
drop policy if exists "anon all inspections"      on inspections;

create policy "anon all bbw_staged"       on bbw_staged       for all using (true) with check (true);
create policy "anon all bbw_transactions" on bbw_transactions for all using (true) with check (true);
create policy "anon all bbw_inventory"    on bbw_inventory    for all using (true) with check (true);
create policy "anon all inspections"      on inspections      for all using (true) with check (true);
