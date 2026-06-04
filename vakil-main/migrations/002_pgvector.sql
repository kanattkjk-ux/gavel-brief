-- ============================================================
-- Gavel & Brief — pgvector Migration (Migration 002)
-- Adds vector embeddings for true semantic RAG retrieval.
-- Replaces TF-IDF cosine similarity with pgvector ANN search.
-- Run AFTER migration 001.
-- ============================================================

-- Enable pgvector (available by default on Supabase)
CREATE EXTENSION IF NOT EXISTS vector;

-- ──────────────────────────────────────────────────────────────
-- Add embedding columns to existing RAG tables
-- ──────────────────────────────────────────────────────────────

-- laws table (stored as JSONB wrapper — add a native embedding table)
ALTER TABLE laws ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- past_cases
ALTER TABLE past_cases ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- document_chunks (primary RAG retrieval table)
ALTER TABLE document_chunks ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- case_precedents
ALTER TABLE case_precedents ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- acts_master sections
ALTER TABLE sections_master ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- ──────────────────────────────────────────────────────────────
-- HNSW indexes for fast approximate nearest-neighbour search
-- Using cosine distance (inner product for normalized vectors)
-- ──────────────────────────────────────────────────────────────

-- laws
CREATE INDEX IF NOT EXISTS idx_laws_embedding_hnsw
  ON laws USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- past_cases
CREATE INDEX IF NOT EXISTS idx_past_cases_embedding_hnsw
  ON past_cases USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- document_chunks (most queried)
CREATE INDEX IF NOT EXISTS idx_doc_chunks_embedding_hnsw
  ON document_chunks USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- case_precedents
CREATE INDEX IF NOT EXISTS idx_precedents_embedding_hnsw
  ON case_precedents USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- ──────────────────────────────────────────────────────────────
-- RPC helper functions (callable via Supabase .rpc())
-- ──────────────────────────────────────────────────────────────

-- Find top-K most relevant laws
CREATE OR REPLACE FUNCTION match_laws(
  query_embedding vector(1536),
  match_threshold FLOAT DEFAULT 0.3,
  match_count     INT   DEFAULT 5
)
RETURNS TABLE (
  id             TEXT,
  ipc_section    TEXT,
  title          TEXT,
  description    TEXT,
  keywords       JSONB,
  similarity     FLOAT
)
LANGUAGE sql STABLE AS $$
  SELECT
    l.id,
    l.data->>'ipc_section' AS ipc_section,
    l.data->>'title'       AS title,
    l.data->>'description' AS description,
    l.data->'keywords'     AS keywords,
    1 - (l.embedding <=> query_embedding) AS similarity
  FROM laws l
  WHERE l.embedding IS NOT NULL
    AND 1 - (l.embedding <=> query_embedding) > match_threshold
  ORDER BY l.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- Find top-K most similar past cases
CREATE OR REPLACE FUNCTION match_past_cases(
  query_embedding vector(1536),
  match_threshold FLOAT DEFAULT 0.3,
  match_count     INT   DEFAULT 5
)
RETURNS TABLE (
  id          TEXT,
  title       TEXT,
  summary     TEXT,
  court       TEXT,
  citation    TEXT,
  year        TEXT,
  source_url  TEXT,
  keywords    JSONB,
  similarity  FLOAT
)
LANGUAGE sql STABLE AS $$
  SELECT
    p.id,
    p.data->>'title'      AS title,
    p.data->>'summary'    AS summary,
    p.data->>'court'      AS court,
    p.data->>'citation'   AS citation,
    p.data->>'year'       AS year,
    p.data->>'source_url' AS source_url,
    p.data->'keywords'    AS keywords,
    1 - (p.embedding <=> query_embedding) AS similarity
  FROM past_cases p
  WHERE p.embedding IS NOT NULL
    AND 1 - (p.embedding <=> query_embedding) > match_threshold
  ORDER BY p.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- Find top-K most relevant document chunks (for Knowledge Base RAG)
CREATE OR REPLACE FUNCTION match_document_chunks(
  query_embedding vector(1536),
  match_threshold FLOAT DEFAULT 0.3,
  match_count     INT   DEFAULT 8,
  filter_domain   UUID  DEFAULT NULL
)
RETURNS TABLE (
  id           UUID,
  document_id  UUID,
  chunk_text   TEXT,
  chunk_index  INT,
  doc_title    TEXT,
  doc_type     TEXT,
  metadata     JSONB,
  similarity   FLOAT
)
LANGUAGE sql STABLE AS $$
  SELECT
    dc.id,
    dc.document_id,
    dc.chunk_text,
    dc.chunk_index,
    ld.title          AS doc_title,
    ld.doc_type       AS doc_type,
    dc.metadata,
    1 - (dc.embedding <=> query_embedding) AS similarity
  FROM document_chunks dc
  JOIN legal_documents ld ON ld.id = dc.document_id
  WHERE dc.embedding IS NOT NULL
    AND 1 - (dc.embedding <=> query_embedding) > match_threshold
    AND (filter_domain IS NULL OR ld.domain_id = filter_domain)
  ORDER BY dc.embedding <=> query_embedding
  LIMIT match_count;
$$;
