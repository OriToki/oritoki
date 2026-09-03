-- =====================================================================
--  ORITOKI — Talent Pool backend (Supabase)
--  ---------------------------------------------------------------------
--  HOW TO USE:
--   1. Create a free project at https://supabase.com
--   2. Open  SQL Editor  →  New query  →  paste this whole file  →  Run
--   3. In  Project Settings → API  copy the  Project URL  and the
--      anon public key, and paste them into join.html
--      (SUPABASE_URL / SUPABASE_ANON_KEY) and later into the admin page.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------- Applications table ----------
create table if not exists public.specialist_applications (
  id                uuid primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  first_name        text not null,
  last_name         text not null,
  phone             text not null,
  email             text not null,
  city              text,
  country           text,
  certifications    text[] not null default '{}',
  rope_level        text,
  experience_years  text,
  specialties       text[] not null default '{}',
  work_regions      text[] not null default '{}',
  languages         text[] not null default '{}',
  driving_license   text[] not null default '{}',
  own_ppe           text,
  notes             text,
  cv_url            text,
  -- status: New | Reviewed | Contacted | Hired | Archived
  status            text not null default 'New'
);

create index if not exists idx_apps_created_at on public.specialist_applications (created_at desc);
create index if not exists idx_apps_status     on public.specialist_applications (status);

-- ---------- Row Level Security ----------
alter table public.specialist_applications enable row level security;

-- The public form (anon) may INSERT an application, nothing else.
drop policy if exists "public can insert applications" on public.specialist_applications;
create policy "public can insert applications"
  on public.specialist_applications for insert
  to anon
  with check (true);

-- Signed-in admins may read / update (e.g. change status).
drop policy if exists "authenticated can read applications" on public.specialist_applications;
create policy "authenticated can read applications"
  on public.specialist_applications for select
  to authenticated
  using (true);

drop policy if exists "authenticated can update applications" on public.specialist_applications;
create policy "authenticated can update applications"
  on public.specialist_applications for update
  to authenticated
  using (true) with check (true);

-- ---------- CV storage bucket ----------
--  NOTE: the bucket below is PUBLIC for simplicity (CV links open directly).
--  File names are randomised, but the links are technically public.
--  For stricter privacy: set  public = false  and have the admin page use
--  supabase.storage.from('cvs').createSignedUrl(path, 3600) instead.
insert into storage.buckets (id, name, public)
values ('cvs', 'cvs', true)
on conflict (id) do nothing;

drop policy if exists "anyone can upload a cv" on storage.objects;
create policy "anyone can upload a cv"
  on storage.objects for insert
  to anon
  with check (bucket_id = 'cvs');

drop policy if exists "anyone can read a cv" on storage.objects;
create policy "anyone can read a cv"
  on storage.objects for select
  to public
  using (bucket_id = 'cvs');

-- =====================================================================
--  ADMIN LOGIN: in the Supabase dashboard → Authentication → Users →
--  "Add user", create your admin email + password. The admin dashboard
--  page (built next) will sign in with it to read/manage applications.
-- =====================================================================
