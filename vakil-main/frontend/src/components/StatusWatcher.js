import { useEffect, useRef } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { useAuth } from '../contexts/AuthContext';
import API_URL from '../lib/api';

const STORAGE_KEY = 'vs_case_statuses';
const POLL_MS = 15000;

const STATUS_LABELS = {
  submitted:          'Submitted',
  analyzed:           'AI Analyzed',
  open:               'Open for Assignment',
  accepted:           'Lawyer Assigned',
  in_progress:        'In Progress',
  'in-progress':      'In Progress',
  awaiting_documents: 'Documents Needed',
  in_court:           'In Court',
  completed:          'Completed',
  closed:             'Closed',
};

const STATUS_EMOJI = {
  submitted:          '📋',
  analyzed:           '🤖',
  open:               '📂',
  accepted:           '🤝',
  in_progress:        '⚙️',
  'in-progress':      '⚙️',
  awaiting_documents: '📄',
  in_court:           '⚖️',
  completed:          '✅',
  closed:             '🔒',
};

function normalize(s) {
  if (!s) return 'submitted';
  return s.toLowerCase().replace(/-/g, '_');
}

function readStored() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
  } catch {
    return {};
  }
}

function writeStored(data) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch {}
}

function fireToast(caseType, oldStatus, newStatus) {
  const normNew = normalize(newStatus);
  const normOld = normalize(oldStatus);
  const label = STATUS_LABELS[normNew] || newStatus;
  const emoji = STATUS_EMOJI[normNew] || '🔔';
  const oldLabel = STATUS_LABELS[normOld] || oldStatus;

  toast.custom(
    (t) => (
      <div
        onClick={() => { toast.dismiss(t.id); window.location.href = '/client/cases'; }}
        className={`cursor-pointer max-w-sm w-full bg-white shadow-xl rounded-2xl border border-slate-200 flex items-start gap-3 px-4 py-4 transition-all duration-300 ${
          t.visible ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-2'
        }`}
      >
        <div className="text-2xl flex-shrink-0 mt-0.5">{emoji}</div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <p className="text-sm font-bold text-slate-900 truncate">Case Status Updated</p>
            <span className="flex-shrink-0 flex items-center gap-1">
              <span className="relative flex h-1.5 w-1.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-green-500" />
              </span>
              <span className="text-[10px] font-bold uppercase tracking-wider text-green-600">Live</span>
            </span>
          </div>
          <p className="text-xs text-slate-500 truncate">{caseType || 'Your case'}</p>
          <div className="flex items-center gap-2 mt-2">
            <span className="text-xs text-slate-400 line-through">{oldLabel}</span>
            <span className="text-slate-300">→</span>
            <span className="text-xs font-semibold text-slate-800 bg-amber-50 border border-amber-200 px-1.5 py-0.5 rounded-md">{label}</span>
          </div>
          <p className="text-[10px] text-slate-400 mt-1.5">Click to view your cases</p>
        </div>
      </div>
    ),
    {
      duration: 8000,
      position: 'top-right',
    }
  );
}

const StatusWatcher = () => {
  const { user } = useAuth();
  const casesRef = useRef([]);
  const storedRef = useRef(readStored());
  const intervalRef = useRef(null);

  useEffect(() => {
    if (!user || user.role !== 'client') return;

    const loadCases = async () => {
      try {
        const { data } = await axios.get(`${API_URL}/api/my-cases`);
        casesRef.current = data || [];
      } catch {}
    };

    const pollStatuses = async () => {
      const cases = casesRef.current;
      if (!cases.length) return;

      const stored = storedRef.current;
      const results = await Promise.allSettled(
        cases.map(c => axios.get(`${API_URL}/api/cases/${c.id}/status`))
      );

      results.forEach((r, i) => {
        if (r.status !== 'fulfilled') return;
        const d = r.value.data;
        const c = cases[i];
        const fresh = normalize(d.case_status);
        const prev = stored[c.id] ? normalize(stored[c.id]) : null;

        if (prev !== null && prev !== fresh) {
          fireToast(c.case_type, prev, fresh);
        }
        stored[c.id] = fresh;
      });

      storedRef.current = stored;
      writeStored(stored);
    };

    loadCases().then(pollStatuses);
    intervalRef.current = setInterval(pollStatuses, POLL_MS);

    return () => clearInterval(intervalRef.current);
  }, [user]);

  return null;
};

export default StatusWatcher;
