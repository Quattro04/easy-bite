-- EasyBite — Supabase schema
-- Run once in the Supabase dashboard: SQL Editor → New query → paste → Run.
-- Safe to re-run.

-- Groups (households) ----------------------------------------------------
create table if not exists public.groups (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 60),
  invite_code text not null unique
              default upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8)),
  created_by  uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id  uuid not null references public.groups(id) on delete cascade,
  user_id   uuid not null references auth.users(id) on delete cascade,
  email     text,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- All shared app data, one row per entity (recipe, planned day, list item, …).
-- kind ∈ recipe | plan | list | ing | hidden | store ; data = null means deleted.
create table if not exists public.entries (
  group_id   uuid not null references public.groups(id) on delete cascade,
  kind       text not null,
  key        text not null,
  data       jsonb,
  device     text,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  primary key (group_id, kind, key)
);

create or replace function public.touch_entry() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists entries_touch on public.entries;
create trigger entries_touch before insert or update on public.entries
  for each row execute function public.touch_entry();

-- Access control -----------------------------------------------------------
create or replace function public.is_member(gid uuid) returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from group_members where group_id = gid and user_id = auth.uid());
$$;

alter table public.groups        enable row level security;
alter table public.group_members enable row level security;
alter table public.entries       enable row level security;

drop policy if exists "members read group"   on public.groups;
drop policy if exists "members read members" on public.group_members;
drop policy if exists "leave group"          on public.group_members;
drop policy if exists "members read entries" on public.entries;
drop policy if exists "members add entries"  on public.entries;
drop policy if exists "members edit entries" on public.entries;

create policy "members read group"   on public.groups        for select using (public.is_member(id));
create policy "members read members" on public.group_members for select using (public.is_member(group_id));
create policy "leave group"          on public.group_members for delete using (user_id = auth.uid());
create policy "members read entries" on public.entries       for select using (public.is_member(group_id));
create policy "members add entries"  on public.entries       for insert with check (public.is_member(group_id));
create policy "members edit entries" on public.entries       for update using (public.is_member(group_id))
                                                                  with check (public.is_member(group_id));

-- Create / join a group (run with elevated rights, but only for the caller) -
create or replace function public.create_group(p_name text) returns public.groups
language plpgsql security definer set search_path = public as $$
declare g groups;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  insert into groups (name, created_by) values (trim(p_name), auth.uid()) returning * into g;
  insert into group_members (group_id, user_id, email) values (g.id, auth.uid(), auth.jwt() ->> 'email');
  return g;
end $$;

create or replace function public.join_group(p_code text) returns public.groups
language plpgsql security definer set search_path = public as $$
declare g groups;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into g from groups where invite_code = upper(trim(p_code));
  if not found then raise exception 'invalid code'; end if;
  insert into group_members (group_id, user_id, email) values (g.id, auth.uid(), auth.jwt() ->> 'email')
    on conflict do nothing;
  return g;
end $$;

revoke execute on function public.create_group(text) from public, anon;
revoke execute on function public.join_group(text)   from public, anon;
grant  execute on function public.create_group(text) to authenticated;
grant  execute on function public.join_group(text)   to authenticated;

-- Live updates ------------------------------------------------------------
do $$ begin
  alter publication supabase_realtime add table public.entries;
exception when duplicate_object then null;
end $$;
