-- ============================================================
-- Gavel & Brief — RAG Core Schema (Migration 001)
-- Normalized PostgreSQL / Supabase compatible
-- Run in Supabase SQL editor AFTER the base schema.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ──────────────────────────────────────────────────────────────
-- LEGAL TAXONOMY
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS legal_domains (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL UNIQUE,
  slug         TEXT NOT NULL UNIQUE,
  description  TEXT,
  icon_name    TEXT,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order   INT NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_domains_slug ON legal_domains (slug);

CREATE TABLE IF NOT EXISTS case_categories (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id        UUID REFERENCES legal_domains(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  slug             TEXT NOT NULL,
  description      TEXT,
  typical_duration TEXT,
  complexity_level TEXT CHECK (complexity_level IN ('low','medium','high','very_high')),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order       INT NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (domain_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_case_categories_domain ON case_categories (domain_id);

CREATE TABLE IF NOT EXISTS legal_scenarios (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID REFERENCES case_categories(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT NOT NULL,
  trigger_keywords TEXT[],
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_scenarios_category ON legal_scenarios (category_id);

-- ──────────────────────────────────────────────────────────────
-- GUIDED INTERVIEW SYSTEM
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS guided_questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID REFERENCES case_categories(id) ON DELETE CASCADE,
  scenario_id     UUID REFERENCES legal_scenarios(id) ON DELETE SET NULL,
  question_text   TEXT NOT NULL,
  question_type   TEXT NOT NULL CHECK (question_type IN ('yesno','text','select','multiselect','date','number')),
  options         JSONB,
  sort_order      INT NOT NULL DEFAULT 0,
  is_required     BOOLEAN NOT NULL DEFAULT TRUE,
  depends_on_q    UUID REFERENCES guided_questions(id) ON DELETE SET NULL,
  depends_on_val  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guided_questions_category ON guided_questions (category_id);

-- ──────────────────────────────────────────────────────────────
-- LEGAL INTELLIGENCE
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS keywords (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  term          TEXT NOT NULL UNIQUE,
  normalized    TEXT NOT NULL,
  category_id   UUID REFERENCES case_categories(id) ON DELETE SET NULL,
  domain_id     UUID REFERENCES legal_domains(id) ON DELETE SET NULL,
  weight        NUMERIC(4,3) NOT NULL DEFAULT 1.0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_keywords_normalized ON keywords (normalized);

CREATE TABLE IF NOT EXISTS legal_rights (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID REFERENCES case_categories(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  article_ref   TEXT,
  ipc_ref       TEXT,
  is_fundamental BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_rights_category ON legal_rights (category_id);

CREATE TABLE IF NOT EXISTS required_actions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID REFERENCES case_categories(id) ON DELETE CASCADE,
  scenario_id   UUID REFERENCES legal_scenarios(id) ON DELETE SET NULL,
  step_number   INT NOT NULL,
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  deadline_days INT,
  authority     TEXT,
  is_mandatory  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_required_actions_category ON required_actions (category_id);

CREATE TABLE IF NOT EXISTS document_requirements (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID REFERENCES case_categories(id) ON DELETE CASCADE,
  scenario_id   UUID REFERENCES legal_scenarios(id) ON DELETE SET NULL,
  document_name TEXT NOT NULL,
  description   TEXT,
  is_mandatory  BOOLEAN NOT NULL DEFAULT TRUE,
  format_hint   TEXT,
  sample_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_doc_requirements_category ON document_requirements (category_id);

CREATE TABLE IF NOT EXISTS legal_timelines (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID REFERENCES case_categories(id) ON DELETE CASCADE,
  stage_name    TEXT NOT NULL,
  stage_order   INT NOT NULL,
  typical_days  INT,
  max_days      INT,
  description   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_timelines_category ON legal_timelines (category_id);

CREATE TABLE IF NOT EXISTS lawyer_recommendations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id             TEXT NOT NULL,
  lawyer_id           TEXT NOT NULL,
  match_score         NUMERIC(5,2),
  specialization_hit  BOOLEAN,
  location_hit        BOOLEAN,
  availability_hit    BOOLEAN,
  recommended_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lawyer_recs_case ON lawyer_recommendations (case_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_recs_lawyer ON lawyer_recommendations (lawyer_id);

-- ──────────────────────────────────────────────────────────────
-- KNOWLEDGE BASE (RAG)
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS legal_sources (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type   TEXT NOT NULL CHECK (source_type IN ('act','judgment','circular','gazette','manual','other')),
  title         TEXT NOT NULL,
  short_title   TEXT,
  jurisdiction  TEXT NOT NULL DEFAULT 'India',
  year          INT,
  authority     TEXT,
  url           TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS acts_master (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id       UUID REFERENCES legal_sources(id) ON DELETE CASCADE,
  act_number      TEXT,
  short_title     TEXT NOT NULL,
  long_title      TEXT,
  year_of_enact   INT,
  ministry        TEXT,
  category_id     UUID REFERENCES case_categories(id) ON DELETE SET NULL,
  domain_id       UUID REFERENCES legal_domains(id) ON DELETE SET NULL,
  is_in_force     BOOLEAN NOT NULL DEFAULT TRUE,
  last_amended    DATE,
  full_text       TEXT,
  summary         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_acts_master_domain ON acts_master (domain_id);
CREATE INDEX IF NOT EXISTS idx_acts_master_year ON acts_master (year_of_enact);

CREATE TABLE IF NOT EXISTS sections_master (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  act_id          UUID REFERENCES acts_master(id) ON DELETE CASCADE,
  section_number  TEXT NOT NULL,
  title           TEXT,
  text            TEXT NOT NULL,
  is_repealed     BOOLEAN NOT NULL DEFAULT FALSE,
  parent_section  UUID REFERENCES sections_master(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (act_id, section_number)
);

CREATE INDEX IF NOT EXISTS idx_sections_act ON sections_master (act_id);

CREATE TABLE IF NOT EXISTS case_precedents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id       UUID REFERENCES legal_sources(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  citation        TEXT NOT NULL UNIQUE,
  court           TEXT NOT NULL,
  bench           TEXT,
  year            INT,
  judgment_date   DATE,
  summary         TEXT NOT NULL,
  full_text       TEXT,
  keywords        TEXT[],
  domain_id       UUID REFERENCES legal_domains(id) ON DELETE SET NULL,
  category_id     UUID REFERENCES case_categories(id) ON DELETE SET NULL,
  overruled_by    UUID REFERENCES case_precedents(id) ON DELETE SET NULL,
  is_landmark     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_precedents_domain ON case_precedents (domain_id);
CREATE INDEX IF NOT EXISTS idx_precedents_year ON case_precedents (year);
CREATE INDEX IF NOT EXISTS idx_precedents_citation ON case_precedents (citation);

CREATE TABLE IF NOT EXISTS legal_documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id       UUID REFERENCES legal_sources(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  doc_type        TEXT NOT NULL CHECK (doc_type IN ('judgment','act','section','circular','article','other')),
  content         TEXT NOT NULL,
  summary         TEXT,
  domain_id       UUID REFERENCES legal_domains(id) ON DELETE SET NULL,
  category_id     UUID REFERENCES case_categories(id) ON DELETE SET NULL,
  metadata        JSONB NOT NULL DEFAULT '{}',
  uploaded_by     TEXT,
  ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_docs_domain ON legal_documents (domain_id);
CREATE INDEX IF NOT EXISTS idx_legal_docs_type ON legal_documents (doc_type);

CREATE TABLE IF NOT EXISTS document_chunks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id     UUID REFERENCES legal_documents(id) ON DELETE CASCADE,
  chunk_index     INT NOT NULL,
  chunk_text      TEXT NOT NULL,
  token_count     INT,
  metadata        JSONB NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_doc_chunks_document ON document_chunks (document_id);

-- ──────────────────────────────────────────────────────────────
-- GLOSSARY & UPDATES
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS legal_glossary (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  term          TEXT NOT NULL UNIQUE,
  definition    TEXT NOT NULL,
  latin_origin  TEXT,
  examples      TEXT[],
  domain_id     UUID REFERENCES legal_domains(id) ON DELETE SET NULL,
  related_terms TEXT[],
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_glossary_term ON legal_glossary (lower(term));

CREATE TABLE IF NOT EXISTS legal_updates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  summary         TEXT NOT NULL,
  full_text       TEXT,
  update_type     TEXT NOT NULL CHECK (update_type IN ('amendment','new_law','circular','notification','judgment','other')),
  effective_date  DATE,
  published_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  source_url      TEXT,
  domain_id       UUID REFERENCES legal_domains(id) ON DELETE SET NULL,
  is_published    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_updates_date ON legal_updates (published_date DESC);
CREATE INDEX IF NOT EXISTS idx_legal_updates_domain ON legal_updates (domain_id);

-- ──────────────────────────────────────────────────────────────
-- CASE STATUS HISTORY (for real-time tracker)
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS case_status_history (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id       TEXT NOT NULL,
  old_status    TEXT,
  new_status    TEXT NOT NULL,
  changed_by    TEXT,
  note          TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_case_status_history_case ON case_status_history (case_id);
CREATE INDEX IF NOT EXISTS idx_case_status_history_time ON case_status_history (created_at DESC);

-- ──────────────────────────────────────────────────────────────
-- updated_at triggers
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'legal_domains','case_categories','legal_scenarios',
    'legal_sources','acts_master','case_precedents','legal_documents',
    'legal_glossary','legal_updates'
  ] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_updated ON %I', t, t);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_updated BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
      t, t
    );
  END LOOP;
END $$;
