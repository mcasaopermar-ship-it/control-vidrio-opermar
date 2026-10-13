-- CONTROL DE VIDRIO | OPERMAR SA
-- Ejecutar una vez en Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null check (role in ('controller','supervisor')),
  created_at timestamptz not null default now()
);
create or replace function public.current_app_role()
returns text language sql stable security definer set search_path=public
as $$ select role from public.profiles where id=auth.uid() $$;

create table if not exists public.employees (
 id uuid primary key default gen_random_uuid(), name text not null, active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), name text not null unique, family text not null,
 calibre text, format text, pallets_per_truck integer, cases_per_pallet integer,
 bottles_per_case integer not null, color text not null default '#ffffff', border_color text not null default '#2d7451',
 target_cases integer not null default 700, active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.trucks (
 id uuid primary key default gen_random_uuid(), truck_number integer not null unique check(truck_number between 1 and 5),
 code text not null unique, created_at timestamptz not null default now()
);
create table if not exists public.cycles (
 id uuid primary key default gen_random_uuid(), truck_id uuid not null references public.trucks(id),
 operator_id uuid references public.employees(id), operator_status text not null default 'Vacía' check(operator_status in ('Vacía','En proceso','Finalizada')),
 controller_status text not null default 'Para armar' check(controller_status in ('Para armar','En proceso','Para desarmar','Retirada')),
 target_cases integer not null default 700, broken_cases integer not null default 0, notes text,
 created_by uuid references auth.users(id), created_by_name text, created_at timestamptz not null default now(), egressed_at timestamptz
);
create unique index if not exists one_open_cycle_per_truck on public.cycles(truck_id) where egressed_at is null;
create table if not exists public.positions (
 id uuid primary key default gen_random_uuid(), cycle_id uuid not null references public.cycles(id) on delete cascade,
 position_number integer not null check(position_number between 1 and 20), product_name text,
 cases_count integer not null default 0 check(cases_count>=0), bottles_per_case integer not null default 24 check(bottles_per_case>0),
 skeletons_count integer not null default 0 check(skeletons_count>=0), pallets_count numeric(7,2) not null default 0 check(pallets_count>=0),
 notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(cycle_id,position_number)
);
create table if not exists public.declarations (
 id uuid primary key default gen_random_uuid(), cycle_id uuid not null references public.cycles(id), operator_id uuid references public.employees(id),
 declared_cases integer not null check(declared_cases>=0), declared_by uuid references auth.users(id), declared_by_name text, notes text, declared_at timestamptz not null default now()
);
create table if not exists public.verifications (
 id uuid primary key default gen_random_uuid(), cycle_id uuid not null references public.cycles(id), remaining_cases numeric(12,2) not null check(remaining_cases>=0),
 expected_remaining_cases numeric(12,2) not null default 0, difference_cases numeric(12,2) not null default 0, verifier_id uuid references auth.users(id), verifier_name text, notes text, verified_at timestamptz not null default now()
);
create table if not exists public.verification_items (
 id uuid primary key default gen_random_uuid(), verification_id uuid not null references public.verifications(id) on delete cascade,
 position_number integer not null check(position_number between 1 and 20), product_name text not null,
 skeletons_remaining integer not null default 0, bottles_remaining integer not null default 0,
 bottles_per_case integer not null default 24, cases_equivalent numeric(12,2) not null default 0,
 skeleton_distribution jsonb not null default '[]'::jsonb, created_at timestamptz not null default now()
);
create table if not exists public.cycle_events (
 id uuid primary key default gen_random_uuid(), cycle_id uuid not null references public.cycles(id), event_type text not null,
 actor_id uuid references auth.users(id), actor_name text, details text, created_at timestamptz not null default now()
);
create table if not exists public.egresses (
 id uuid primary key default gen_random_uuid(), cycle_id uuid not null unique references public.cycles(id), truck_id uuid not null references public.trucks(id),
 truck_code text not null, supplier_remit text not null, internal_remit text not null, egressed_at timestamptz not null default now(),
 egressed_by uuid references auth.users(id), egressed_by_name text, loaded_cases integer not null default 0, broken_cases integer not null default 0,
 operator_id uuid references public.employees(id), frames_removed boolean not null default false
);

insert into public.trucks(truck_number,code) values (1,'CH129'),(2,'VOLQUETA-2'),(3,'VOLQUETA-3'),(4,'VOLQUETA-4'),(5,'VOLQUETA-5') on conflict(truck_number) do nothing;
insert into public.products(name,family,calibre,format,pallets_per_truck,cases_per_pallet,bottles_per_case,color,border_color,target_cases) values
('Corona 2/3 · 710','Corona','710','2/3',20,35,24,'#eab308','#16a34a',700),
('Corona 2/3 · 330','Corona','330','2/3',20,35,24,'#eab308','#16a34a',700),
('Corona 340 · 330','Corona','330','340',12,60,24,'#38bdf8','#0284c7',720),
('Corona 1/1 · 710','Corona','710','1/1',14,50,12,'#ffffff','#16803d',700),
('Corona 1/1 · 330','Corona','330','1/1',14,50,24,'#ffffff','#16803d',700),
('Corona cartón · 710','Corona','710','Cartón',8,84,12,'#9ca3af','#6b7280',700),
('Corona cartón · 330','Corona','330','Cartón',8,84,24,'#9ca3af','#6b7280',700),
('Pilsen 1/1','Ámbar','1/1','1/1',14,50,12,'#d97706','#eab308',700),
('Pilsen 340','Ámbar','340','340',12,60,24,'#d97706','#eab308',720),
('Patricia 1/1','Ámbar','1/1','1/1',14,50,12,'#d97706','#166534',700),
('Zillertal 970','Verde','970','1/1',14,50,12,'#16a34a','#15803d',700),
('Stella Artois 975','Verde','975','1/1',14,50,12,'#854d0e','#713f12',700),
('Pepsi 1 L','Pepsi','1 L','1/1',14,50,12,'#ffffff','#38bdf8',700),
('Pepsi 1,25 L','Pepsi','1,25 L','1/1',9,80,6,'#ffffff','#16a34a',700)
on conflict(name) do nothing;

alter table public.profiles enable row level security;
alter table public.employees enable row level security;
alter table public.products enable row level security;
alter table public.trucks enable row level security;
alter table public.cycles enable row level security;
alter table public.positions enable row level security;
alter table public.declarations enable row level security;
alter table public.verifications enable row level security;
alter table public.verification_items enable row level security;
alter table public.cycle_events enable row level security;
alter table public.egresses enable row level security;

drop policy if exists "profile read" on public.profiles;
create policy "profile read" on public.profiles for select to authenticated using (id=auth.uid() or public.current_app_role()='supervisor');
drop policy if exists "profile supervisor manage" on public.profiles;
create policy "profile supervisor manage" on public.profiles for all to authenticated using (public.current_app_role()='supervisor') with check (public.current_app_role()='supervisor');

do $$ declare t text; begin
 foreach t in array array['employees','products','trucks','cycles','positions','declarations','verifications','verification_items','cycle_events','egresses'] loop
  execute format('drop policy if exists "app select %1$s" on public.%1$I',t);
  execute format('create policy "app select %1$s" on public.%1$I for select to authenticated using (public.current_app_role() in (''controller'',''supervisor''))',t);
  execute format('drop policy if exists "app insert %1$s" on public.%1$I',t);
  execute format('create policy "app insert %1$s" on public.%1$I for insert to authenticated with check (public.current_app_role() in (''controller'',''supervisor''))',t);
  execute format('drop policy if exists "app update %1$s" on public.%1$I',t);
  execute format('create policy "app update %1$s" on public.%1$I for update to authenticated using (public.current_app_role() in (''controller'',''supervisor'')) with check (public.current_app_role() in (''controller'',''supervisor''))',t);
  execute format('drop policy if exists "app delete %1$s" on public.%1$I',t);
  execute format('create policy "app delete %1$s" on public.%1$I for delete to authenticated using (public.current_app_role() in (''controller'',''supervisor''))',t);
 end loop; end $$;

-- Crear usuarios en Authentication > Users y luego asignarles perfil:
-- insert into public.profiles(id,full_name,role) values ('UUID-DEL-USUARIO','Nombre','controller');
-- El rol del supervisor es 'supervisor'. Cargar operarios en public.employees.
