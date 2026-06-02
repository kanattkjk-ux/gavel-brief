-- ============================================================
--  VakilSetu / Gavel & Brief — Supabase Production Schema
--  Run once in the Supabase SQL Editor to set up all tables.
--  Tables use a generic JSONB `data` column so the existing
--  Python adapter (supabase_db.py) works without changes.
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ────────────────────────────────────────────────────────────
-- Helper: drop & recreate tables safely
-- ────────────────────────────────────────────────────────────

-- USERS  (clients + lawyers — role field inside data)
CREATE TABLE IF NOT EXISTS users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- LEGAL WRITERS  (separate collection, role = legal_writer)
CREATE TABLE IF NOT EXISTS legal_writers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- CASES
CREATE TABLE IF NOT EXISTS cases (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- IPC LAWS  (seeded from comprehensive_ipc_laws.json)
CREATE TABLE IF NOT EXISTS laws (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- PAST CASES  (seeded from past_cases_data.json)
CREATE TABLE IF NOT EXISTS past_cases (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- BOOKINGS  (lawyer appointment slots)
CREATE TABLE IF NOT EXISTS bookings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- CONSULTATIONS  (soft consultation requests — pre-booking)
CREATE TABLE IF NOT EXISTS consultations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- LAW FIRMS
CREATE TABLE IF NOT EXISTS firms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- REVIEWS  (client reviews of lawyers)
CREATE TABLE IF NOT EXISTS reviews (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- SURVEYS  (post-session satisfaction surveys)
CREATE TABLE IF NOT EXISTS surveys (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- DRAFTS  (legal writer draft documents)
CREATE TABLE IF NOT EXISTS drafts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- WRITING REQUESTS  (clients request legal documents)
CREATE TABLE IF NOT EXISTS writing_requests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- CASE NOTES  (lawyer/client notes on a case)
CREATE TABLE IF NOT EXISTS case_notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- CASE MESSAGES  (in-app messaging thread per case)
CREATE TABLE IF NOT EXISTS case_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- CASE DOCUMENTS  (uploaded files attached to a case)
CREATE TABLE IF NOT EXISTS case_documents (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- PAYMENT TRANSACTIONS  (Stripe payment records)
CREATE TABLE IF NOT EXISTS payment_transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- REFERRALS  (lawyer-to-lawyer case referrals)
CREATE TABLE IF NOT EXISTS referrals (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  data        JSONB            NOT NULL DEFAULT '{}'
);

-- ────────────────────────────────────────────────────────────
-- INDEXES  (on JSONB paths for the most queried fields)
-- ────────────────────────────────────────────────────────────

-- users: email (unique), role, firmId
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email
  ON users ((data->>'email'));
CREATE INDEX IF NOT EXISTS idx_users_role
  ON users ((data->>'role'));
CREATE INDEX IF NOT EXISTS idx_users_firm_id
  ON users ((data->>'firmId'))
  WHERE data->>'firmId' IS NOT NULL;

-- legal_writers: email (unique)
CREATE UNIQUE INDEX IF NOT EXISTS idx_legal_writers_email
  ON legal_writers ((data->>'email'));

-- cases: user_id, lawyer_id, status, nyayId (unique), case_status
CREATE INDEX IF NOT EXISTS idx_cases_user_id
  ON cases ((data->>'user_id'));
CREATE INDEX IF NOT EXISTS idx_cases_lawyer_id
  ON cases ((data->>'lawyer_id'))
  WHERE data->>'lawyer_id' IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cases_status
  ON cases ((data->>'status'));
CREATE INDEX IF NOT EXISTS idx_cases_case_status
  ON cases ((data->>'case_status'));
CREATE UNIQUE INDEX IF NOT EXISTS idx_cases_nyay_id
  ON cases ((data->>'nyayId'))
  WHERE data->>'nyayId' IS NOT NULL;

-- laws: ipc_section
CREATE INDEX IF NOT EXISTS idx_laws_ipc_section
  ON laws ((data->>'ipc_section'));

-- bookings: client_id, lawyer_id, scheduled_date, status
CREATE INDEX IF NOT EXISTS idx_bookings_client_id
  ON bookings ((data->>'client_id'));
CREATE INDEX IF NOT EXISTS idx_bookings_lawyer_id
  ON bookings ((data->>'lawyer_id'));
CREATE INDEX IF NOT EXISTS idx_bookings_lawyer_date
  ON bookings ((data->>'lawyer_id'), (data->>'scheduled_date'));
CREATE INDEX IF NOT EXISTS idx_bookings_status
  ON bookings ((data->>'status'));

-- consultations: client_id, lawyer_id, status
CREATE INDEX IF NOT EXISTS idx_consultations_client_id
  ON consultations ((data->>'client_id'));
CREATE INDEX IF NOT EXISTS idx_consultations_lawyer_id
  ON consultations ((data->>'lawyer_id'));

-- notifications: user_id, is_read
CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON notifications ((data->>'user_id'));
CREATE INDEX IF NOT EXISTS idx_notifications_is_read
  ON notifications ((data->>'is_read'));

-- reviews: lawyer_id
CREATE INDEX IF NOT EXISTS idx_reviews_lawyer_id
  ON reviews ((data->>'lawyer_id'));

-- drafts: status, legal_writer_id
CREATE INDEX IF NOT EXISTS idx_drafts_status
  ON drafts ((data->>'status'));
CREATE INDEX IF NOT EXISTS idx_drafts_writer_id
  ON drafts ((data->>'legal_writer_id'))
  WHERE data->>'legal_writer_id' IS NOT NULL;

-- writing_requests: status, client_id
CREATE INDEX IF NOT EXISTS idx_writing_requests_status
  ON writing_requests ((data->>'status'));
CREATE INDEX IF NOT EXISTS idx_writing_requests_client_id
  ON writing_requests ((data->>'client_id'));

-- case_notes: case_id
CREATE INDEX IF NOT EXISTS idx_case_notes_case_id
  ON case_notes ((data->>'case_id'));

-- case_messages: case_id
CREATE INDEX IF NOT EXISTS idx_case_messages_case_id
  ON case_messages ((data->>'case_id'));

-- case_documents: case_id
CREATE INDEX IF NOT EXISTS idx_case_documents_case_id
  ON case_documents ((data->>'case_id'));

-- payment_transactions: user_id, session_id
CREATE INDEX IF NOT EXISTS idx_payment_txn_user_id
  ON payment_transactions ((data->>'user_id'));
CREATE INDEX IF NOT EXISTS idx_payment_txn_session_id
  ON payment_transactions ((data->>'session_id'))
  WHERE data->>'session_id' IS NOT NULL;

-- referrals: case_id, referred_by_id, referred_to_id
CREATE INDEX IF NOT EXISTS idx_referrals_case_id
  ON referrals ((data->>'case_id'));
CREATE INDEX IF NOT EXISTS idx_referrals_referred_by
  ON referrals ((data->>'referred_by_id'));
CREATE INDEX IF NOT EXISTS idx_referrals_referred_to
  ON referrals ((data->>'referred_to_id'));

-- ────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- All tables start with RLS disabled so the service-role key
-- (used by the Python backend) can read/write freely.
-- Enable + add policies here once you add Supabase Auth.
-- ────────────────────────────────────────────────────────────

ALTER TABLE users               DISABLE ROW LEVEL SECURITY;
ALTER TABLE legal_writers       DISABLE ROW LEVEL SECURITY;
ALTER TABLE cases               DISABLE ROW LEVEL SECURITY;
ALTER TABLE laws                DISABLE ROW LEVEL SECURITY;
ALTER TABLE past_cases          DISABLE ROW LEVEL SECURITY;
ALTER TABLE bookings            DISABLE ROW LEVEL SECURITY;
ALTER TABLE consultations       DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       DISABLE ROW LEVEL SECURITY;
ALTER TABLE firms               DISABLE ROW LEVEL SECURITY;
ALTER TABLE reviews             DISABLE ROW LEVEL SECURITY;
ALTER TABLE surveys             DISABLE ROW LEVEL SECURITY;
ALTER TABLE drafts              DISABLE ROW LEVEL SECURITY;
ALTER TABLE writing_requests    DISABLE ROW LEVEL SECURITY;
ALTER TABLE case_notes          DISABLE ROW LEVEL SECURITY;
ALTER TABLE case_messages       DISABLE ROW LEVEL SECURITY;
ALTER TABLE case_documents      DISABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE referrals           DISABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- DONE
-- After running this file, restart the backend API workflow.
-- The Python startup() will automatically:
--   • Seed IPC laws  (from comprehensive_ipc_laws.json)
--   • Seed past cases (from past_cases_data.json)
--   • Seed test users: client@test.com / lawyer@test.com / writer@test.com
--   • Seed 5 demo lawyers + 5 law firms
--   • Seed 7 demo cases for client@test.com
-- ────────────────────────────────────────────────────────────
