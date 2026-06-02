-- VakilSetu / Gavel & Brief — Supabase PostgreSQL Schema
-- Run this in the Supabase SQL editor to create all required tables.
-- Each table stores documents as JSONB so the Python adapter works
-- without any structural changes to the application code.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── users ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS users_email ON users ((data->>'email'));
CREATE INDEX IF NOT EXISTS users_role  ON users ((data->>'role'));

-- ─── legal_writers ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS legal_writers (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS legal_writers_email ON legal_writers ((data->>'email'));

-- ─── firms ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firms (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS firms_name ON firms ((data->>'name'));

-- ─── cases ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cases (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS cases_lawyer_id  ON cases ((data->>'lawyer_id'));
CREATE INDEX IF NOT EXISTS cases_user_id    ON cases ((data->>'user_id'));
CREATE INDEX IF NOT EXISTS cases_nyay_id    ON cases ((data->>'nyayId'));

-- ─── reviews ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reviews_lawyer_id ON reviews ((data->>'lawyer_id'));
CREATE INDEX IF NOT EXISTS reviews_client_id ON reviews ((data->>'client_id'));

-- ─── surveys ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS surveys (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS surveys_case_id   ON surveys ((data->>'case_id'));
CREATE INDEX IF NOT EXISTS surveys_client_id ON surveys ((data->>'client_id'));

-- ─── laws ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS laws (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── past_cases ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS past_cases (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── drafts ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS drafts (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS drafts_status           ON drafts ((data->>'status'));
CREATE INDEX IF NOT EXISTS drafts_legal_writer_id  ON drafts ((data->>'legal_writer_id'));

-- ─── notifications ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS notifications_user_id ON notifications ((data->>'user_id'));
