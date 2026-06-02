# VakilSetu - Legal Intelligence Platform PRD

## Original Problem Statement
Build a full-stack web application called "VakilSetu" – a legal case matching platform that has evolved into an AI-powered, decision-tree based legal intelligence platform with dynamic user flow, keyword detection, document OCR, NyayID PDF generation, and structured legal guidance.

## Tech Stack
- **Frontend:** React 19, Tailwind CSS, Framer Motion, Shadcn/UI components
- **Backend:** FastAPI (Python), Motor (async MongoDB driver)
- **Database:** MongoDB
- **AI:** GPT-4o-mini via Emergent LLM Key (emergentintegrations library)
- **OCR:** Tesseract.js (client-side)
- **PDF:** jsPDF (client-side)

## Core Features

### Phase 1 - MVP (DONE)
- JWT authentication (httpOnly cookies, access + refresh tokens)
- Client registration/login, Lawyer registration/login
- Case submission form (type, description, location, urgency, budget)
- Lawyer dashboard with case feed, filters, and accept functionality
- Seeded IPC laws database (25 entries) with embeddings
- Seeded past court cases database (15 entries) with embeddings

### Phase 2 - RAG Analysis (DONE)
- AI-powered case analysis using GPT-4o-mini
- Relevant law matching (vector similarity - MOCKED with hash-based embeddings)
- Similar past case matching
- Lawyer scoring and matching algorithm
- Case status tracking with history

### Phase 3 - Legal Intelligence Engine (DONE - April 10, 2026)
- **5-Phase Interactive Flow:**
  1. Describe: Text input + document upload (OCR) + location/urgency
  2. Analyze: AI keyword extraction + category detection with confidence
  3. Questions: Dynamic decision tree (5 categories: Criminal, Civil, Family, Property, Employment)
  4. Results: Risk assessment, relevant laws, similar cases, AI analysis, matched lawyers
  5. NyayID: Unique case identifier + PDF report download

- **Additional Features:**
  - Stamp paper diagnostic (judicial vs non-judicial)
  - Lawyer connect button (consultation requests)
  - Translation to 8 Indian languages (Hindi, Tamil, Malayalam, Bengali, Telugu, Kannada, Marathi, Gujarati)
  - Case saving with NyayID to client dashboard
  - My Cases page with case tracker and status history
  - Affidavit generator (AI-powered drafting + editable + PDF download)

## API Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user
- `POST /api/cases` - Create case
- `GET /api/cases` - Get cases (lawyer)
- `PUT /api/cases/{id}/accept` - Accept case (lawyer)
- `PUT /api/cases/{id}/status` - Update case status (lawyer)
- `GET /api/my-cases` - Get client's own cases
- `POST /api/analyze-case` - RAG case analysis
- `POST /api/extract-keywords` - AI keyword extraction
- `POST /api/get-questions` - Decision tree questions
- `POST /api/risk-analysis` - Risk and complexity analysis
- `POST /api/generate-nyayid` - Generate NyayID profile
- `POST /api/stamp-paper-diagnostic` - Stamp paper type diagnosis
- `POST /api/consultation-request` - Request lawyer consultation
- `POST /api/save-case-with-nyayid` - Save analyzed case
- `POST /api/generate-affidavit` - AI affidavit generation
- `POST /api/translate` - Text translation
- `GET /api/lawyers` - List lawyers

## Known Limitations
- Vector similarity search uses hash-based embeddings (MOCKED) instead of real OpenAI embeddings
- This causes less accurate law/case matching but core functionality works

## Backlog / Future Tasks
- P2: Real vector embeddings integration for accurate law matching
- P2: Referral system (lawyer-to-lawyer referrals)
- P2: Online consultation (video calls)
- P3: User notification system
- P3: Payment integration for lawyer consultations

## Architecture
```
/app/backend/server.py - Monolith API (all routes, auth, AI logic)
/app/backend/decision_trees.json - Question data for 5 categories
/app/backend/comprehensive_ipc_laws.json - 25 IPC law entries
/app/backend/past_cases_data.json - 15 past court cases
/app/frontend/src/pages/ClientHome.js - Intelligence Engine (5-phase flow)
/app/frontend/src/pages/MyCases.js - Case tracker
/app/frontend/src/pages/AffidavitBuilder.js - Affidavit generator
/app/frontend/src/components/DocumentUpload.js - OCR component
/app/frontend/src/components/NyayIDCard.js - NyayID display + PDF
```
