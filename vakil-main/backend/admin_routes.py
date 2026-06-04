"""
Admin API routes for Gavel & Brief Admin Dashboard.
All routes are prefixed with /admin/api and require admin JWT auth.
"""

from fastapi import APIRouter, HTTPException, Depends, Request, UploadFile, File
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import os
import jwt
import bcrypt
import csv
import io
import uuid
import json
import logging
from datetime import datetime, timezone, timedelta

logger = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────────────────────────

ADMIN_JWT_SECRET = os.environ.get("JWT_SECRET", "dev-secret-key-change-in-production")
ADMIN_JWT_ALGORITHM = "HS256"
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@gavelandbrief.com")
ADMIN_PASSWORD_HASH = os.environ.get("ADMIN_PASSWORD_HASH", "")
ADMIN_PASSWORD_PLAIN = os.environ.get("ADMIN_PASSWORD", "admin123")  # fallback for first login

router = APIRouter(prefix="/admin/api", tags=["admin"])


# ── Auth helpers ─────────────────────────────────────────────────────────────

def _make_admin_token(email: str) -> str:
    payload = {
        "sub": email,
        "role": "admin",
        "exp": datetime.now(timezone.utc) + timedelta(days=7),
        "type": "admin_access",
    }
    return jwt.encode(payload, ADMIN_JWT_SECRET, algorithm=ADMIN_JWT_ALGORITHM)


async def require_admin(request: Request) -> str:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing admin token")
    token = auth[7:]
    try:
        payload = jwt.decode(token, ADMIN_JWT_SECRET, algorithms=[ADMIN_JWT_ALGORITHM])
        if payload.get("role") != "admin" or payload.get("type") != "admin_access":
            raise HTTPException(status_code=403, detail="Not an admin token")
        return payload["sub"]
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


# ── Supabase client (server-side, uses service role key) ─────────────────────

def _get_supabase():
    try:
        from supabase import create_client
        url = os.environ.get("SUPABASE_URL", "")
        key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
        if url and key:
            return create_client(url, key)
    except Exception as e:
        logger.warning(f"Supabase client init failed: {e}")
    return None


def _get_db():
    """Return the MongoDB db object from server module."""
    try:
        import server as srv
        return getattr(srv, "db", None)
    except Exception:
        return None


# ── Generic DB helpers ────────────────────────────────────────────────────────

def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _new_id() -> str:
    return str(uuid.uuid4())


async def _sb_list(table: str, search_col: str = None, search: str = None,
                   limit: int = 50, offset: int = 0) -> Dict:
    sb = _get_supabase()
    if sb:
        try:
            q = sb.table(table).select("*", count="exact")
            if search and search_col:
                q = q.ilike(search_col, f"%{search}%")
            q = q.order("created_at", desc=True).range(offset, offset + limit - 1)
            res = q.execute()
            return {"items": res.data or [], "total": res.count or len(res.data or [])}
        except Exception as e:
            logger.error(f"Supabase list {table}: {e}")
    return {"items": [], "total": 0}


async def _sb_get(table: str, id: str) -> Optional[Dict]:
    sb = _get_supabase()
    if sb:
        try:
            res = sb.table(table).select("*").eq("id", id).single().execute()
            return res.data
        except Exception:
            pass
    return None


async def _sb_insert(table: str, data: Dict) -> Optional[Dict]:
    sb = _get_supabase()
    if sb:
        try:
            data.setdefault("id", _new_id())
            data.setdefault("created_at", _now_iso())
            res = sb.table(table).insert(data).execute()
            return res.data[0] if res.data else data
        except Exception as e:
            logger.error(f"Supabase insert {table}: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    raise HTTPException(status_code=503, detail="Database not available")


async def _sb_update(table: str, id: str, data: Dict) -> Optional[Dict]:
    sb = _get_supabase()
    if sb:
        try:
            data["updated_at"] = _now_iso()
            res = sb.table(table).update(data).eq("id", id).execute()
            return res.data[0] if res.data else data
        except Exception as e:
            logger.error(f"Supabase update {table}: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    raise HTTPException(status_code=503, detail="Database not available")


async def _sb_delete(table: str, id: str):
    sb = _get_supabase()
    if sb:
        try:
            sb.table(table).delete().eq("id", id).execute()
            return
        except Exception as e:
            logger.error(f"Supabase delete {table}: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    raise HTTPException(status_code=503, detail="Database not available")


# ── Schemas ───────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str

class DocumentUpdate(BaseModel):
    title: Optional[str] = None
    source: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class ChunkUpdate(BaseModel):
    content: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class SourceCreate(BaseModel):
    name: str
    url: Optional[str] = None
    type: Optional[str] = "other"
    description: Optional[str] = None

class CaseCreate(BaseModel):
    title: str
    court: Optional[str] = None
    year: Optional[int] = None
    citation: Optional[str] = None
    category: Optional[str] = "civil"
    summary: Optional[str] = None

class ActCreate(BaseModel):
    title: str
    number: Optional[str] = None
    year: Optional[int] = None
    ministry: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None

class UserUpdate(BaseModel):
    role: Optional[str] = None
    is_active: Optional[bool] = None

class SettingsUpdate(BaseModel):
    new_password: Optional[str] = None


# ── Auth ──────────────────────────────────────────────────────────────────────

@router.post("/login")
async def admin_login(body: LoginRequest):
    if body.email.lower() != ADMIN_EMAIL.lower():
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Check hashed password first, then fall back to plain (for initial setup)
    if ADMIN_PASSWORD_HASH:
        ok = bcrypt.checkpw(body.password.encode(), ADMIN_PASSWORD_HASH.encode())
    else:
        ok = body.password == ADMIN_PASSWORD_PLAIN

    if not ok:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {"token": _make_admin_token(body.email), "email": body.email}


# ── Dashboard ─────────────────────────────────────────────────────────────────

@router.get("/dashboard")
async def get_dashboard(admin: str = Depends(require_admin)):
    sb = _get_supabase()
    counts = {"documents": 0, "chunks": 0, "sources": 0, "cases": 0, "acts": 0, "users": 0}
    recent = []

    if sb:
        try:
            for tbl, key in [("gb_documents", "documents"), ("gb_chunks", "chunks"),
                              ("gb_sources", "sources"), ("gb_cases", "cases"),
                              ("gb_acts", "acts"), ("users", "users")]:
                try:
                    res = sb.table(tbl).select("id", count="exact").execute()
                    counts[key] = res.count or 0
                except Exception:
                    pass

            # Recent across tables
            for tbl, typ in [("gb_documents", "document"), ("gb_cases", "case"), ("gb_acts", "act")]:
                try:
                    res = sb.table(tbl).select("id,title,created_at").order("created_at", desc=True).limit(3).execute()
                    for row in (res.data or []):
                        recent.append({"type": typ, "title": row.get("title", "Untitled"), "created_at": row["created_at"]})
                except Exception:
                    pass

            recent.sort(key=lambda x: x["created_at"], reverse=True)
            recent = recent[:10]
        except Exception as e:
            logger.error(f"Dashboard error: {e}")

    return {"counts": counts, "recent_activity": recent}


# ── Documents ─────────────────────────────────────────────────────────────────

@router.get("/documents")
async def list_documents(search: str = "", limit: int = 50, offset: int = 0,
                         admin: str = Depends(require_admin)):
    return await _sb_list("gb_documents", "title", search or None, limit, offset)


@router.get("/documents/{doc_id}")
async def get_document(doc_id: str, admin: str = Depends(require_admin)):
    doc = await _sb_get("gb_documents", doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return doc


@router.post("/documents/upload")
async def upload_document(file: UploadFile = File(...), admin: str = Depends(require_admin)):
    content = await file.read()
    filename = file.filename or "untitled"
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "unknown"

    # Store document record in Supabase
    doc_id = _new_id()
    data = {
        "id": doc_id,
        "title": filename.rsplit(".", 1)[0],
        "source": "Upload",
        "file_type": ext,
        "file_size": len(content),
        "chunk_count": 0,
        "created_at": _now_iso(),
        "metadata": {"original_filename": filename},
    }

    # Try to extract text and create chunks for PDFs
    text_content = ""
    if ext == "txt":
        try:
            text_content = content.decode("utf-8", errors="ignore")
        except Exception:
            pass
    elif ext == "pdf":
        try:
            import fitz  # PyMuPDF
            doc = fitz.open(stream=content, filetype="pdf")
            text_content = "\n".join(page.get_text() for page in doc)
        except ImportError:
            logger.warning("PyMuPDF not available; storing PDF metadata only")
        except Exception as e:
            logger.error(f"PDF parse error: {e}")

    doc_record = await _sb_insert("gb_documents", data)

    # Create chunks if we have text
    chunks_created = 0
    if text_content.strip():
        chunk_size = 500
        words = text_content.split()
        chunks = [" ".join(words[i:i+chunk_size]) for i in range(0, len(words), chunk_size)]
        sb = _get_supabase()
        if sb:
            for idx, chunk_text in enumerate(chunks[:200]):  # cap at 200 chunks
                try:
                    sb.table("gb_chunks").insert({
                        "id": _new_id(),
                        "document_id": doc_id,
                        "document_title": data["title"],
                        "content": chunk_text,
                        "chunk_index": idx,
                        "created_at": _now_iso(),
                    }).execute()
                    chunks_created += 1
                except Exception:
                    pass
            # Update chunk count
            try:
                sb.table("gb_documents").update({"chunk_count": chunks_created}).eq("id", doc_id).execute()
            except Exception:
                pass

    return {**doc_record, "chunk_count": chunks_created, "message": f"Uploaded with {chunks_created} chunks"}


@router.post("/documents/import-csv")
async def import_documents_csv(file: UploadFile = File(...), admin: str = Depends(require_admin)):
    content = await file.read()
    text = content.decode("utf-8", errors="ignore")
    reader = csv.DictReader(io.StringIO(text))
    imported = 0
    for row in reader:
        try:
            data = {
                "id": _new_id(),
                "title": row.get("title", row.get("name", "Untitled")),
                "source": row.get("source", ""),
                "file_type": row.get("file_type", row.get("type", "csv")),
                "chunk_count": 0,
                "created_at": _now_iso(),
                "metadata": {k: v for k, v in row.items() if k not in ("title", "source", "file_type")},
            }
            await _sb_insert("gb_documents", data)
            imported += 1
        except Exception as e:
            logger.error(f"CSV row import failed: {e}")
    return {"imported": imported, "message": f"Imported {imported} documents"}


@router.put("/documents/{doc_id}")
async def update_document(doc_id: str, body: DocumentUpdate, admin: str = Depends(require_admin)):
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    return await _sb_update("gb_documents", doc_id, updates)


@router.delete("/documents/{doc_id}")
async def delete_document(doc_id: str, admin: str = Depends(require_admin)):
    # Delete associated chunks
    sb = _get_supabase()
    if sb:
        try:
            sb.table("gb_chunks").delete().eq("document_id", doc_id).execute()
        except Exception:
            pass
    await _sb_delete("gb_documents", doc_id)
    return {"ok": True}


# ── Chunks ────────────────────────────────────────────────────────────────────

@router.get("/chunks")
async def list_chunks(q: str = "", limit: int = 20, offset: int = 0,
                      admin: str = Depends(require_admin)):
    if q:
        return await _sb_list("gb_chunks", "content", q, limit, offset)
    return await _sb_list("gb_chunks", None, None, limit, offset)


@router.get("/chunks/search")
async def search_chunks(q: str = "", admin: str = Depends(require_admin)):
    return await _sb_list("gb_chunks", "content", q, 50, 0)


@router.get("/chunks/{chunk_id}")
async def get_chunk(chunk_id: str, admin: str = Depends(require_admin)):
    chunk = await _sb_get("gb_chunks", chunk_id)
    if not chunk:
        raise HTTPException(status_code=404, detail="Chunk not found")
    return chunk


@router.put("/chunks/{chunk_id}")
async def update_chunk(chunk_id: str, body: ChunkUpdate, admin: str = Depends(require_admin)):
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    return await _sb_update("gb_chunks", chunk_id, updates)


@router.delete("/chunks/{chunk_id}")
async def delete_chunk(chunk_id: str, admin: str = Depends(require_admin)):
    await _sb_delete("gb_chunks", chunk_id)
    return {"ok": True}


# ── Sources ───────────────────────────────────────────────────────────────────

@router.get("/sources")
async def list_sources(search: str = "", limit: int = 50, offset: int = 0,
                       admin: str = Depends(require_admin)):
    return await _sb_list("gb_sources", "name", search or None, limit, offset)


@router.post("/sources")
async def create_source(body: SourceCreate, admin: str = Depends(require_admin)):
    return await _sb_insert("gb_sources", body.model_dump())


@router.put("/sources/{source_id}")
async def update_source(source_id: str, body: SourceCreate, admin: str = Depends(require_admin)):
    return await _sb_update("gb_sources", source_id, body.model_dump())


@router.delete("/sources/{source_id}")
async def delete_source(source_id: str, admin: str = Depends(require_admin)):
    await _sb_delete("gb_sources", source_id)
    return {"ok": True}


@router.post("/sources/import-csv")
async def import_sources_csv(file: UploadFile = File(...), admin: str = Depends(require_admin)):
    content = await file.read()
    reader = csv.DictReader(io.StringIO(content.decode("utf-8", errors="ignore")))
    imported = 0
    for row in reader:
        try:
            await _sb_insert("gb_sources", {
                "id": _new_id(), "name": row.get("name", ""), "url": row.get("url", ""),
                "type": row.get("type", "other"), "description": row.get("description", ""),
                "created_at": _now_iso(),
            })
            imported += 1
        except Exception:
            pass
    return {"imported": imported}


# ── Cases ─────────────────────────────────────────────────────────────────────

@router.get("/cases")
async def list_cases(search: str = "", limit: int = 50, offset: int = 0,
                     admin: str = Depends(require_admin)):
    return await _sb_list("gb_cases", "title", search or None, limit, offset)


@router.get("/cases/{case_id}")
async def get_case(case_id: str, admin: str = Depends(require_admin)):
    case = await _sb_get("gb_cases", case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    return case


@router.post("/cases")
async def create_case(body: CaseCreate, admin: str = Depends(require_admin)):
    return await _sb_insert("gb_cases", body.model_dump())


@router.put("/cases/{case_id}")
async def update_case(case_id: str, body: CaseCreate, admin: str = Depends(require_admin)):
    return await _sb_update("gb_cases", case_id, body.model_dump())


@router.delete("/cases/{case_id}")
async def delete_case(case_id: str, admin: str = Depends(require_admin)):
    await _sb_delete("gb_cases", case_id)
    return {"ok": True}


@router.post("/cases/import-csv")
async def import_cases_csv(file: UploadFile = File(...), admin: str = Depends(require_admin)):
    content = await file.read()
    reader = csv.DictReader(io.StringIO(content.decode("utf-8", errors="ignore")))
    imported = 0
    for row in reader:
        try:
            year_val = row.get("year")
            await _sb_insert("gb_cases", {
                "id": _new_id(), "title": row.get("title", ""), "court": row.get("court", ""),
                "year": int(year_val) if year_val and year_val.isdigit() else None,
                "citation": row.get("citation", ""), "category": row.get("category", "civil"),
                "summary": row.get("summary", ""), "created_at": _now_iso(),
            })
            imported += 1
        except Exception:
            pass
    return {"imported": imported}


# ── Acts ──────────────────────────────────────────────────────────────────────

@router.get("/acts")
async def list_acts(search: str = "", limit: int = 50, offset: int = 0,
                    admin: str = Depends(require_admin)):
    return await _sb_list("gb_acts", "title", search or None, limit, offset)


@router.get("/acts/{act_id}")
async def get_act(act_id: str, admin: str = Depends(require_admin)):
    act = await _sb_get("gb_acts", act_id)
    if not act:
        raise HTTPException(status_code=404, detail="Act not found")
    return act


@router.post("/acts")
async def create_act(body: ActCreate, admin: str = Depends(require_admin)):
    return await _sb_insert("gb_acts", body.model_dump())


@router.put("/acts/{act_id}")
async def update_act(act_id: str, body: ActCreate, admin: str = Depends(require_admin)):
    return await _sb_update("gb_acts", act_id, body.model_dump())


@router.delete("/acts/{act_id}")
async def delete_act(act_id: str, admin: str = Depends(require_admin)):
    await _sb_delete("gb_acts", act_id)
    return {"ok": True}


@router.post("/acts/import-csv")
async def import_acts_csv(file: UploadFile = File(...), admin: str = Depends(require_admin)):
    content = await file.read()
    reader = csv.DictReader(io.StringIO(content.decode("utf-8", errors="ignore")))
    imported = 0
    for row in reader:
        try:
            year_val = row.get("year")
            await _sb_insert("gb_acts", {
                "id": _new_id(), "title": row.get("title", ""), "number": row.get("number", ""),
                "year": int(year_val) if year_val and year_val.isdigit() else None,
                "ministry": row.get("ministry", ""), "category": row.get("category", ""),
                "description": row.get("description", ""), "created_at": _now_iso(),
            })
            imported += 1
        except Exception:
            pass
    return {"imported": imported}


# ── Users ─────────────────────────────────────────────────────────────────────

@router.get("/users")
async def list_users(search: str = "", limit: int = 50, offset: int = 0,
                     admin: str = Depends(require_admin)):
    sb = _get_supabase()
    if sb:
        try:
            q = sb.table("users").select("id,email,name,role,is_active,created_at,last_login", count="exact")
            if search:
                q = q.or_(f"email.ilike.%{search}%,name.ilike.%{search}%")
            q = q.order("created_at", desc=True).range(offset, offset + limit - 1)
            res = q.execute()
            return {"items": res.data or [], "total": res.count or 0}
        except Exception as e:
            logger.error(f"List users: {e}")
    return {"items": [], "total": 0}


@router.put("/users/{user_id}")
async def update_user(user_id: str, body: UserUpdate, admin: str = Depends(require_admin)):
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    return await _sb_update("users", user_id, updates)


@router.delete("/users/{user_id}")
async def delete_user(user_id: str, admin: str = Depends(require_admin)):
    await _sb_delete("users", user_id)
    return {"ok": True}


# ── Settings ──────────────────────────────────────────────────────────────────

@router.get("/settings")
async def get_settings(admin: str = Depends(require_admin)):
    doc_count = 0
    chunk_count = 0
    sb = _get_supabase()
    if sb:
        try:
            r = sb.table("gb_documents").select("id", count="exact").execute()
            doc_count = r.count or 0
        except Exception:
            pass
        try:
            r = sb.table("gb_chunks").select("id", count="exact").execute()
            chunk_count = r.count or 0
        except Exception:
            pass

    return {
        "admin_email": ADMIN_EMAIL,
        "openai_configured": bool(os.environ.get("OPENAI_API_KEY") or os.environ.get("EMERGENT_LLM_KEY")),
        "supabase_configured": bool(os.environ.get("SUPABASE_URL") and os.environ.get("SUPABASE_SERVICE_ROLE_KEY")),
        "mongo_configured": bool(os.environ.get("MONGO_URL")),
        "db_backend": "supabase" if os.environ.get("SUPABASE_URL") else "mongodb",
        "document_count": doc_count,
        "chunk_count": chunk_count,
    }


@router.put("/settings")
async def update_settings(body: SettingsUpdate, admin: str = Depends(require_admin)):
    if body.new_password:
        if len(body.new_password) < 8:
            raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
        hashed = bcrypt.hashpw(body.new_password.encode(), bcrypt.gensalt()).decode()
        # We can't modify env vars at runtime, so we store in Supabase settings table
        sb = _get_supabase()
        if sb:
            try:
                sb.table("gb_settings").upsert({
                    "key": "admin_password_hash", "value": hashed, "updated_at": _now_iso()
                }).execute()
            except Exception:
                pass
        return {"message": "Password updated — restart server to take effect"}
    return {"message": "No changes made"}


@router.post("/settings/migrate")
async def run_migration(admin: str = Depends(require_admin)):
    """Check which Gavel & Brief tables exist in Supabase."""
    sb = _get_supabase()
    if not sb:
        raise HTTPException(status_code=503, detail="Supabase not configured")

    tables = ["gb_documents", "gb_chunks", "gb_sources", "gb_cases", "gb_acts", "gb_settings"]
    found = []
    missing = []

    for tbl in tables:
        try:
            sb.table(tbl).select("id").limit(1).execute()
            found.append(tbl)
        except Exception as e:
            err = str(e).lower()
            if "relation" in err or "does not exist" in err or "not found" in err or "42p01" in err:
                missing.append(tbl)
            else:
                found.append(f"{tbl} (uncertain)")

    if missing:
        return {
            "message": f"{len(found)} tables ready, {len(missing)} need creation",
            "tables_ready": found,
            "tables_missing": missing,
            "action_required": True,
            "instructions": (
                "Run admin/supabase_migration.sql in the Supabase SQL Editor at "
                f"{os.environ.get('SUPABASE_URL', '')}/project/default/sql"
            ),
        }

    return {
        "message": f"All {len(found)} tables are ready",
        "tables_ready": found,
        "action_required": False,
    }
