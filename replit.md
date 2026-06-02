# VakilSetu - AI-Powered Legal Intelligence Platform

## Project Overview
VakilSetu is an AI-powered legal platform that connects clients with lawyers in India. It provides automated legal case analysis using a 5-phase interactive flow (Describe, Analyze, Questions, Results, NyayID), matches users with relevant IPC laws and past court cases, and generates unique "NyayID" case reports.

## Architecture

### Frontend (React + CRACO)
- **Location**: `vakil-main/frontend/`
- **Port**: 5000
- **Tech**: React 19, Tailwind CSS, Radix UI, Framer Motion, Axios
- **Package Manager**: npm (yarn also present but npm is used)
- **Entry Point**: `src/index.js`
- **API URL**: Configured via `REACT_APP_BACKEND_URL` env var (defaults to `http://localhost:8000`)

### Backend (FastAPI + Python)
- **Location**: `vakil-main/backend/`
- **Port**: 8000
- **Tech**: FastAPI, Motor (MongoDB), scikit-learn TF-IDF, PyJWT, bcrypt
- **Entry Point**: `server.py`
- **Database**: MongoDB Atlas (hardcoded connection string in server.py)

## Workflows
- **Start application**: Frontend React dev server on port 5000
  - Command: `cd vakil-main/frontend && PORT=5000 npm start`
- **Backend API**: FastAPI on port 8000
  - Command: `cd vakil-main/backend && uvicorn server:app --host localhost --port 8000 --reload`

## Key Features
- Legal Intelligence Engine: 5-step case intake flow
- RAG Analysis: TF-IDF similarity matching against seeded laws/cases
- NyayID: Unique case profile and PDF report generation
- Affidavit Builder: AI-powered legal document drafting
- Lawyer Matching: Algorithm-based scoring
- Lawyer Booking System: Browse lawyers → view profiles → pick date/time → select meeting type (Video/Phone/In-Person) → confirm booking
  - Pages: `FindLawyers.js`, `LawyerBooking.js`, `MyBookings.js`
  - Routes: `/client/lawyers`, `/client/lawyers/:lawyerId`, `/client/bookings`
  - Backend endpoints: `GET /api/lawyers/{id}`, `GET /api/lawyers/{id}/slots`, `POST /api/bookings`, `GET /api/bookings`, `PUT /api/bookings/{id}/cancel`
  - 5 demo lawyers seeded with full profiles (bio, fee, experience, languages, availability)

## Environment Variables
- `REACT_APP_BACKEND_URL`: Backend API URL (set in `vakil-main/frontend/.env`)
- `EMERGENT_LLM_KEY`: OpenAI proxy key for AI features
- `STRIPE_API_KEY`: For payment features
- `JWT_SECRET`: JWT signing secret (defaults to dev key)

## Test Credentials
- Client: client@test.com / password123
- Lawyer: lawyer@test.com / password123

## Important Notes
- CORS is set to allow all origins (`*`) with `allow_credentials=False`
- Frontend proxy trust: CRACO devServer configured with `allowedHosts: "all"` and `host: "0.0.0.0"`
- MongoDB Atlas is used (connection string is hardcoded in server.py)
- The `emergentintegrations` package is used for AI and Stripe; requires `EMERGENT_LLM_KEY` env var
