-- Gavel & Brief Admin Dashboard — Supabase Migration
-- Run this in your Supabase SQL Editor: https://tuntezbubswvzbcgstow.supabase.co

-- Enable UUID and vector extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- Documents
CREATE TABLE IF NOT EXISTS gb_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    source TEXT,
    file_type TEXT,
    file_size INTEGER,
    chunk_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chunks (text segments from documents)
CREATE TABLE IF NOT EXISTS gb_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES gb_documents(id) ON DELETE CASCADE,
    document_title TEXT,
    content TEXT NOT NULL,
    chunk_index INTEGER DEFAULT 0,
    embedding VECTOR(1536),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sources
CREATE TABLE IF NOT EXISTS gb_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    url TEXT,
    type TEXT DEFAULT 'other',
    description TEXT,
    document_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cases
CREATE TABLE IF NOT EXISTS gb_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    court TEXT,
    year INTEGER,
    citation TEXT,
    category TEXT DEFAULT 'civil',
    summary TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Acts
CREATE TABLE IF NOT EXISTS gb_acts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    number TEXT,
    year INTEGER,
    ministry TEXT,
    category TEXT,
    description TEXT,
    section_count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Settings
CREATE TABLE IF NOT EXISTS gb_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_gb_chunks_document_id ON gb_chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_gb_chunks_content ON gb_chunks USING gin(to_tsvector('english', content));
CREATE INDEX IF NOT EXISTS idx_gb_documents_title ON gb_documents USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_gb_cases_title ON gb_cases USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_gb_acts_title ON gb_acts USING gin(to_tsvector('english', title));

-- Enable RLS (tables are accessed via service role key — bypass RLS)
ALTER TABLE gb_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE gb_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE gb_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE gb_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE gb_acts ENABLE ROW LEVEL SECURITY;
ALTER TABLE gb_settings ENABLE ROW LEVEL SECURITY;

-- Service role bypass policies (admin backend uses service role key)
CREATE POLICY "Service role full access" ON gb_documents FOR ALL USING (true);
CREATE POLICY "Service role full access" ON gb_chunks FOR ALL USING (true);
CREATE POLICY "Service role full access" ON gb_sources FOR ALL USING (true);
CREATE POLICY "Service role full access" ON gb_cases FOR ALL USING (true);
CREATE POLICY "Service role full access" ON gb_acts FOR ALL USING (true);
CREATE POLICY "Service role full access" ON gb_settings FOR ALL USING (true);
