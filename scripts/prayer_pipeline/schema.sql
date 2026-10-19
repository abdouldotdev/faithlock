-- FaithLock — prayers metadata table + audio storage bucket.
-- Run in the Supabase SQL editor (runs as a privileged role, so it can also
-- create the storage bucket + policies below). Idempotent — safe to re-run.
--
-- Access model (publishable key only — no service_role):
--   • App      → publishable key + anonymous sign-in → role `authenticated`
--                → READ prayers + may mint signed URLs for the private audio.
--   • Pipeline → publishable key, no sign-in        → role `anon`
--                → WRITE prayers + upload audio (content publishing).

create table if not exists public.prayers (
  id             text not null,
  title          text not null,
  domain         text not null,
  lang           text not null default 'en',
  scripture_ref  text,
  scripture_text text,
  script_text    text,
  duration_sec   integer,
  audio_path     text,
  audio_url      text,
  -- Forced-alignment word timestamps (Replicate cureau/force-align-wordstamps),
  -- normalised to: [{ word: string, start_ms: int, end_ms: int }, ...]. Drives
  -- exact karaoke sync in the player; null → falls back to estimated TTS sync.
  word_timings   jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- Composite key: the same prayer id exists once per language (en, fr, …).
  primary key (id, lang)
);

-- Idempotent column add for databases provisioned before word_timings existed.
alter table public.prayers add column if not exists word_timings jsonb;

create index if not exists prayers_domain_idx on public.prayers (domain);
create index if not exists prayers_lang_idx on public.prayers (lang);

alter table public.prayers enable row level security;

-- Read: only authenticated sessions. The app signs in anonymously at launch,
-- so unauthenticated REST hits with just the publishable key are rejected.
drop policy if exists "prayers readable by anyone" on public.prayers;
drop policy if exists "prayers readable by authenticated" on public.prayers;
create policy "prayers readable by authenticated"
  on public.prayers for select
  to authenticated
  using (true);

-- Write: the content pipeline (publishable key, no session → `anon`) publishes
-- prayers. upsert ⇒ needs both insert and update.
drop policy if exists "prayers insertable by pipeline" on public.prayers;
create policy "prayers insertable by pipeline"
  on public.prayers for insert
  to anon
  with check (true);
drop policy if exists "prayers updatable by pipeline" on public.prayers;
create policy "prayers updatable by pipeline"
  on public.prayers for update
  to anon
  using (true)
  with check (true);

-- ── Storage: PRIVATE bucket for prayer audio ────────────────────────────────
-- Private → the app streams via short-lived signed URLs (createSignedUrl),
-- which requires SELECT on the object as `authenticated`.
insert into storage.buckets (id, name, public)
values ('prayer-audio', 'prayer-audio', false)
on conflict (id) do update set public = excluded.public;

-- Read / sign: authenticated app sessions only.
drop policy if exists "prayer audio readable by authenticated" on storage.objects;
create policy "prayer audio readable by authenticated"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'prayer-audio');

-- Write: the pipeline uploads (publishable key → `anon`). upsert ⇒ insert+update.
drop policy if exists "prayer audio insertable by pipeline" on storage.objects;
create policy "prayer audio insertable by pipeline"
  on storage.objects for insert
  to anon
  with check (bucket_id = 'prayer-audio');
drop policy if exists "prayer audio updatable by pipeline" on storage.objects;
create policy "prayer audio updatable by pipeline"
  on storage.objects for update
  to anon
  using (bucket_id = 'prayer-audio')
  with check (bucket_id = 'prayer-audio');
