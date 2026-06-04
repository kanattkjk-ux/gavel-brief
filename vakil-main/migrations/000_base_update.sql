-- ============================================================
-- Gavel & Brief — Base Schema Additions (Migration 000)
-- Updates to existing JSONB tables.
-- Run BEFORE migrations 001 and 002.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Ensure base tables exist (idempotent)
CREATE TABLE IF NOT EXISTS users (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users ((data->>'email'));
CREATE INDEX IF NOT EXISTS idx_users_role  ON users ((data->>'role'));

CREATE TABLE IF NOT EXISTS legal_writers (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_legal_writers_email ON legal_writers ((data->>'email'));

CREATE TABLE IF NOT EXISTS firms (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cases (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cases_lawyer_id ON cases ((data->>'lawyer_id'));
CREATE INDEX IF NOT EXISTS idx_cases_user_id   ON cases ((data->>'user_id'));
CREATE INDEX IF NOT EXISTS idx_cases_nyay_id   ON cases ((data->>'nyayId'));
CREATE INDEX IF NOT EXISTS idx_cases_status    ON cases ((data->>'status'));

CREATE TABLE IF NOT EXISTS reviews (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS surveys (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS laws (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_laws_ipc ON laws ((data->>'ipc_section'));

CREATE TABLE IF NOT EXISTS past_cases (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS drafts (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_drafts_status    ON drafts ((data->>'status'));
CREATE INDEX IF NOT EXISTS idx_drafts_writer_id ON drafts ((data->>'legal_writer_id'));

CREATE TABLE IF NOT EXISTS notifications (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications ((data->>'user_id'));

CREATE TABLE IF NOT EXISTS payment_transactions (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add GIN index on data for full-JSONB search
CREATE INDEX IF NOT EXISTS idx_cases_data_gin   ON cases   USING GIN (data);
CREATE INDEX IF NOT EXISTS idx_users_data_gin   ON users   USING GIN (data);
