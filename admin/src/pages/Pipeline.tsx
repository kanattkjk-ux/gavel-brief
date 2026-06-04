import { useEffect, useState, useRef, useCallback } from 'react'
import { Upload, RefreshCw, Trash2, FileText, Loader2, CheckCircle, XCircle, Clock, Zap, ChevronDown, ChevronUp } from 'lucide-react'
import toast from 'react-hot-toast'
import PageHeader from '../components/ui/PageHeader'
import api from '../lib/api'
import { formatDistanceToNow } from 'date-fns'
import { clsx } from 'clsx'

interface Job {
  job_id: string
  filename: string
  file_size: number
  act_hint: string
  status: string
  progress: number
  message: string
  chunks_created: number
  document_id: string | null
  created_at: string
  updated_at: string
  error?: string
  completed_at?: string
  act_name?: string
  total_pages?: number
}

const STATUS_META: Record<string, { label: string; color: string; icon: React.ReactNode }> = {
  queued:      { label: 'Queued',      color: 'text-gray-400 bg-gray-500/20',     icon: <Clock size={12} /> },
  extracting:  { label: 'Extracting',  color: 'text-blue-400 bg-blue-500/20',     icon: <Loader2 size={12} className="animate-spin" /> },
  ocr:         { label: 'OCR',         color: 'text-purple-400 bg-purple-500/20', icon: <Loader2 size={12} className="animate-spin" /> },
  sectioning:  { label: 'Sectioning',  color: 'text-cyan-400 bg-cyan-500/20',     icon: <Loader2 size={12} className="animate-spin" /> },
  chunking:    { label: 'Chunking',    color: 'text-yellow-400 bg-yellow-500/20', icon: <Loader2 size={12} className="animate-spin" /> },
  summarizing: { label: 'Summarizing', color: 'text-amber-400 bg-amber-500/20',   icon: <Loader2 size={12} className="animate-spin" /> },
  storing:     { label: 'Storing',     color: 'text-teal-400 bg-teal-500/20',     icon: <Loader2 size={12} className="animate-spin" /> },
  done:        { label: 'Done',        color: 'text-green-400 bg-green-500/20',   icon: <CheckCircle size={12} /> },
  failed:      { label: 'Failed',      color: 'text-red-400 bg-red-500/20',       icon: <XCircle size={12} /> },
}

const ACT_TYPES = ['', 'BNS', 'BNSS', 'BSA', 'IPC', 'CrPC', 'IEA', 'Legal Awareness Guide', 'Landmark Cases']

function ProgressBar({ value, status }: { value: number; status: string }) {
  const colorMap: Record<string, string> = {
    done: 'bg-green-500',
    failed: 'bg-red-500',
    queued: 'bg-gray-500',
  }
  const color = colorMap[status] ?? 'bg-brand-500'
  return (
    <div className="h-1.5 w-full bg-white/5 rounded-full overflow-hidden mt-1.5">
      <div
        className={`h-full rounded-full transition-all duration-500 ${color} ${status !== 'done' && status !== 'failed' && status !== 'queued' ? 'animate-pulse' : ''}`}
        style={{ width: `${value}%` }}
      />
    </div>
  )
}

function JobRow({ job, onDelete, onRefresh }: { job: Job; onDelete: (id: string) => void; onRefresh: () => void }) {
  const [expanded, setExpanded] = useState(false)
  const meta = STATUS_META[job.status] ?? STATUS_META.queued
  const isRunning = !['done', 'failed', 'queued'].includes(job.status)

  return (
    <div className={`card overflow-hidden transition-all ${isRunning ? 'border-brand-500/30' : ''}`}>
      <div className="p-4">
        <div className="flex items-start gap-3">
          <div className="w-9 h-9 rounded-lg bg-surface-2 flex items-center justify-center flex-shrink-0 mt-0.5 border border-white/[0.08]">
            <FileText size={16} className="text-brand-400" />
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between gap-2">
              <p className="text-sm font-medium text-gray-200 truncate">{job.filename}</p>
              <div className="flex items-center gap-2 flex-shrink-0">
                <span className={`badge gap-1 ${meta.color}`}>
                  {meta.icon}{meta.label}
                </span>
                {!isRunning && (
                  <button onClick={() => onDelete(job.job_id)}
                    className="p-1 rounded text-gray-600 hover:text-red-400 transition-colors">
                    <Trash2 size={13} />
                  </button>
                )}
                <button onClick={() => setExpanded(e => !e)}
                  className="p-1 rounded text-gray-600 hover:text-gray-300 transition-colors">
                  {expanded ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
                </button>
              </div>
            </div>

            <div className="flex items-center gap-3 mt-1 flex-wrap">
              {job.act_name && (
                <span className="badge bg-brand-600/20 text-brand-400 text-[10px]">{job.act_name}</span>
              )}
              {job.act_hint && !job.act_name && (
                <span className="badge bg-surface-3 text-gray-400 text-[10px]">{job.act_hint}</span>
              )}
              {job.total_pages && (
                <span className="text-[11px] text-gray-500">{job.total_pages} pages</span>
              )}
              {job.chunks_created > 0 && (
                <span className="text-[11px] text-green-500">{job.chunks_created.toLocaleString()} chunks</span>
              )}
              <span className="text-[11px] text-gray-600">
                {formatDistanceToNow(new Date(job.created_at), { addSuffix: true })}
              </span>
            </div>

            <p className="text-xs text-gray-500 mt-1.5">{job.message}</p>
            <ProgressBar value={job.progress} status={job.status} />
          </div>
        </div>
      </div>

      {expanded && (
        <div className="border-t border-white/[0.08] px-4 py-3 bg-surface-2/50">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
            <div>
              <p className="text-gray-500 mb-0.5">Job ID</p>
              <p className="text-gray-400 font-mono text-[10px] truncate">{job.job_id}</p>
            </div>
            <div>
              <p className="text-gray-500 mb-0.5">File Size</p>
              <p className="text-gray-400">{(job.file_size / 1024).toFixed(1)} KB</p>
            </div>
            <div>
              <p className="text-gray-500 mb-0.5">Document ID</p>
              <p className="text-gray-400 font-mono text-[10px] truncate">{job.document_id || '—'}</p>
            </div>
            <div>
              <p className="text-gray-500 mb-0.5">Completed</p>
              <p className="text-gray-400">{job.completed_at ? formatDistanceToNow(new Date(job.completed_at), { addSuffix: true }) : '—'}</p>
            </div>
          </div>
          {job.error && (
            <div className="mt-3 p-2.5 bg-red-500/10 border border-red-500/20 rounded-lg">
              <p className="text-xs text-red-400 font-mono">{job.error}</p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default function Pipeline() {
  const [jobs, setJobs] = useState<Job[]>([])
  const [stats, setStats] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)
  const [uploading, setUploading] = useState(false)
  const [actHint, setActHint] = useState('')
  const [dragOver, setDragOver] = useState(false)
  const fileRef = useRef<HTMLInputElement>(null)
  const pollRef = useRef<number | null>(null)

  const refresh = useCallback(async () => {
    try {
      const [jobsRes, statsRes] = await Promise.all([
        api.get('/pipeline/jobs'),
        api.get('/pipeline/stats'),
      ])
      setJobs(jobsRes.data.jobs ?? [])
      setStats(statsRes.data)
    } catch {
      // silent
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    refresh()
    // Poll every 2s while any job is running
    pollRef.current = window.setInterval(() => {
      const hasRunning = jobs.some(j => !['done', 'failed'].includes(j.status))
      if (hasRunning) refresh()
    }, 2000)
    return () => { if (pollRef.current) clearInterval(pollRef.current) }
  }, [refresh, jobs.length])

  // Separate interval for always polling
  useEffect(() => {
    const id = setInterval(refresh, 3000)
    return () => clearInterval(id)
  }, [refresh])

  async function handleFiles(files: FileList | null) {
    if (!files || files.length === 0) return
    const file = files[0]
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      toast.error('Only PDF files are supported')
      return
    }
    setUploading(true)
    const fd = new FormData()
    fd.append('file', file)
    fd.append('act_hint', actHint)
    try {
      const r = await api.post('/pipeline/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } })
      toast.success(`"${file.name}" queued for processing`)
      await refresh()
      setJobs(prev => [r.data, ...prev])
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail
      toast.error(msg || 'Upload failed')
    } finally {
      setUploading(false)
      if (fileRef.current) fileRef.current.value = ''
    }
  }

  async function handleDelete(jobId: string) {
    try {
      await api.delete(`/pipeline/jobs/${jobId}`)
      setJobs(j => j.filter(x => x.job_id !== jobId))
      toast.success('Job removed')
    } catch { toast.error('Remove failed') }
  }

  const running = jobs.filter(j => !['done', 'failed'].includes(j.status)).length
  const done = jobs.filter(j => j.status === 'done').length
  const failed = jobs.filter(j => j.status === 'failed').length

  return (
    <div>
      <PageHeader
        title="PDF Ingestion Pipeline"
        description="Upload legal PDFs — BNS, BNSS, BSA, Case Summaries, and more"
        actions={
          <button className="btn-secondary" onClick={refresh}>
            <RefreshCw size={14} /> Refresh
          </button>
        }
      />

      {/* Stats bar */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        {[
          { label: 'Total Jobs', value: jobs.length, color: 'text-gray-300' },
          { label: 'Processing', value: running, color: 'text-brand-400' },
          { label: 'Completed', value: done, color: 'text-green-400' },
          { label: 'Failed', value: failed, color: 'text-red-400' },
        ].map(({ label, value, color }) => (
          <div key={label} className="card p-4">
            <p className="text-xs text-gray-500 mb-1">{label}</p>
            <p className={`text-xl font-bold ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Upload zone */}
      <div
        className={clsx(
          'card border-2 border-dashed p-8 mb-6 text-center cursor-pointer transition-all',
          dragOver ? 'border-brand-500 bg-brand-500/5' : 'border-white/10 hover:border-brand-500/40 hover:bg-white/[0.02]'
        )}
        onDragOver={(e) => { e.preventDefault(); setDragOver(true) }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => { e.preventDefault(); setDragOver(false); handleFiles(e.dataTransfer.files) }}
        onClick={() => fileRef.current?.click()}
      >
        <input ref={fileRef} type="file" accept=".pdf" className="hidden" onChange={(e) => handleFiles(e.target.files)} />
        <div className="flex flex-col items-center gap-3">
          {uploading ? (
            <>
              <Loader2 size={28} className="text-brand-400 animate-spin" />
              <p className="text-sm font-medium text-gray-300">Uploading…</p>
            </>
          ) : (
            <>
              <div className="w-12 h-12 rounded-xl bg-brand-600/20 flex items-center justify-center">
                <Upload size={22} className="text-brand-400" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-200">Drop a PDF here or click to browse</p>
                <p className="text-xs text-gray-500 mt-1">Supports BNS, BNSS, BSA, Case Summaries, Legal Guides · Max 50 MB</p>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Act type selector */}
      <div className="flex items-center gap-3 mb-6">
        <label className="text-xs text-gray-400 whitespace-nowrap">Document type (optional):</label>
        <div className="flex flex-wrap gap-1.5">
          {ACT_TYPES.map((act) => (
            <button
              key={act || 'auto'}
              onClick={() => setActHint(act)}
              className={clsx(
                'px-3 py-1 rounded-full text-xs font-medium transition-colors border',
                actHint === act
                  ? 'bg-brand-600 border-brand-500 text-white'
                  : 'bg-surface-2 border-white/10 text-gray-400 hover:border-brand-500/40 hover:text-gray-200'
              )}
            >
              {act || 'Auto-detect'}
            </button>
          ))}
        </div>
      </div>

      {/* Pipeline stages legend */}
      <div className="card p-4 mb-6">
        <div className="flex items-center gap-2 mb-3">
          <Zap size={13} className="text-brand-400" />
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Pipeline Stages</p>
        </div>
        <div className="flex flex-wrap gap-2">
          {Object.entries(STATUS_META).map(([key, { label, color, icon }]) => (
            <span key={key} className={`badge gap-1 ${color}`}>{icon}{label}</span>
          ))}
        </div>
      </div>

      {/* Jobs list */}
      <div className="space-y-3">
        {loading ? (
          Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="card p-4 animate-pulse">
              <div className="flex gap-3">
                <div className="w-9 h-9 bg-white/5 rounded-lg" />
                <div className="flex-1">
                  <div className="h-4 bg-white/5 rounded w-1/2 mb-2" />
                  <div className="h-3 bg-white/5 rounded w-1/3" />
                </div>
              </div>
            </div>
          ))
        ) : jobs.length === 0 ? (
          <div className="card p-12 text-center">
            <Upload size={32} className="mx-auto text-gray-600 mb-3" />
            <p className="text-gray-500 text-sm">No jobs yet — upload a PDF to get started</p>
          </div>
        ) : (
          jobs.map(job => (
            <JobRow key={job.job_id} job={job} onDelete={handleDelete} onRefresh={refresh} />
          ))
        )}
      </div>
    </div>
  )
}
