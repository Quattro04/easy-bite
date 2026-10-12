-- EasyBite — only allow sign-ups from approved email addresses.
-- Run once in Supabase: SQL Editor → New query → paste → replace the two emails → Run.
-- Existing accounts are not affected. Safe to re-run.

create table if not exists public.signup_allowlist (
  email text primary key
);
-- RLS on with no policies: the list can't be read or changed through the app's API.
alter table public.signup_allowlist enable row level security;

create or replace function public.enforce_signup_allowlist() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.signup_allowlist where lower(email) = lower(new.email)) then
    raise exception 'signup_not_allowed';
  end if;
  return new;
end $$;

drop trigger if exists signup_allowlist on auth.users;
create trigger signup_allowlist before insert on auth.users
  for each row execute function public.enforce_signup_allowlist();

-- Who may sign up (lower/upper case doesn't matter):
insert into public.signup_allowlist (email) values
  ('you@example.com'),
  ('friend@example.com')
on conflict do nothing;

-- Later, to let someone else in:   insert into public.signup_allowlist values ('new@person.com');
-- To see the list:                 select * from public.signup_allowlist;
