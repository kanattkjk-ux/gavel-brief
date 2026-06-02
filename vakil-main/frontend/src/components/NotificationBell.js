import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { Bell, Check, CheckCheck, Info, Phone, Users, CreditCard, MessageCircle, BarChart2 } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

import API_URL from '../lib/api';

const iconMap = {
  info: Info,
  consultation: Phone,
  referral: Users,
  payment: CreditCard,
  case_message: MessageCircle,
  digest: BarChart2,
};

const NotificationBell = () => {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState([]);
  const [chatSummary, setChatSummary] = useState({ total_unread: 0, cases: [] });
  const [isOpen, setIsOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (user) {
      fetchNotifications();
      fetchChatSummary();
    }
    const interval = setInterval(() => {
      if (user) {
        fetchNotifications();
        fetchChatSummary();
      }
    }, 15000);
    return () => clearInterval(interval);
  }, [user]);

  useEffect(() => {
    const handleClick = (e) => { if (ref.current && !ref.current.contains(e.target)) setIsOpen(false); };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const fetchNotifications = async () => {
    try {
      const { data } = await axios.get(`${API_URL}/api/notifications`);
      setNotifications(data);
    } catch {}
  };

  const fetchChatSummary = async () => {
    try {
      const { data } = await axios.get(`${API_URL}/api/messages/unread-summary`);
      setChatSummary(data);
    } catch {}
  };

  const markRead = async (id) => {
    try {
      await axios.put(`${API_URL}/api/notifications/${id}/read`, {});
      setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
    } catch {}
  };

  const markAllRead = async () => {
    try {
      await axios.put(`${API_URL}/api/notifications/read-all`, {});
      setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    } catch {}
  };

  const notifUnread = notifications.filter(n => !n.read).length;
  const chatUnread = chatSummary?.total_unread || 0;
  const unreadCount = notifUnread + chatUnread;
  const chatCases = chatSummary?.cases || [];

  if (!user) return null;

  return (
    <div className="relative" ref={ref} data-testid="notification-bell">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative text-[#555555] hover:text-[#111111] transition-colors"
        data-testid="notification-bell-btn"
      >
        <Bell className="w-5 h-5" />
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center" data-testid="notification-badge">
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 top-10 w-80 bg-white rounded-xl shadow-2xl border border-slate-200 z-50 overflow-hidden" data-testid="notification-dropdown">
          <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
            <p className="text-sm font-semibold text-slate-900">Notifications</p>
            {unreadCount > 0 && (
              <button onClick={markAllRead} className="text-xs text-slate-500 hover:text-slate-800 flex items-center gap-1" data-testid="mark-all-read">
                <CheckCheck className="w-3 h-3" /> Mark all read
              </button>
            )}
          </div>
          <div className="max-h-96 overflow-y-auto">
            {chatCases.length > 0 && (
              <div className="bg-amber-50/40 border-b border-amber-100">
                <div className="px-4 py-2 flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-amber-700">
                  <MessageCircle className="w-3.5 h-3.5" /> Unread chat messages
                </div>
                {chatCases.map(cc => (
                  <div
                    key={cc.case_id}
                    className="px-4 py-2.5 border-b border-amber-100/60 hover:bg-amber-50 cursor-pointer flex items-center justify-between gap-3"
                    onClick={() => {
                      setIsOpen(false);
                      window.location.href = user?.role === 'lawyer' ? '/lawyer/dashboard' : '/client/cases';
                    }}
                    data-testid={`chat-unread-${cc.case_id}`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-8 h-8 rounded-full bg-amber-200 flex items-center justify-center flex-shrink-0">
                        <MessageCircle className="w-4 h-4 text-amber-700" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-semibold text-slate-900 truncate">
                          {cc.case_type || 'Case'}{cc.nyay_id ? ` · ${cc.nyay_id}` : ''}
                        </p>
                        <p className="text-xs text-slate-500">{cc.unread} new message{cc.unread !== 1 ? 's' : ''}</p>
                      </div>
                    </div>
                    <span className="bg-red-500 text-white text-[10px] font-bold rounded-full min-w-[20px] h-5 flex items-center justify-center px-1.5">
                      {cc.unread > 99 ? '99+' : cc.unread}
                    </span>
                  </div>
                ))}
              </div>
            )}
            {notifications.length === 0 && chatCases.length === 0 ? (
              <div className="p-6 text-center text-sm text-slate-400">No notifications</div>
            ) : notifications.length === 0 ? null : (
              notifications.slice(0, 10).map(n => {
                const Icon = iconMap[n.type] || Info;
                return (
                  <div
                    key={n.id}
                    className={`px-4 py-3 border-b border-slate-50 hover:bg-slate-50 cursor-pointer flex items-start gap-3 ${!n.read ? 'bg-blue-50/50' : ''}`}
                    onClick={() => markRead(n.id)}
                    data-testid={`notification-item-${n.id}`}
                  >
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${!n.read ? 'bg-amber-100' : 'bg-slate-100'}`}>
                      <Icon className={`w-4 h-4 ${!n.read ? 'text-amber-600' : 'text-slate-400'}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className={`text-sm ${!n.read ? 'font-semibold text-slate-900' : 'text-slate-600'}`}>{n.title}</p>
                      <p className="text-xs text-slate-500 truncate">{n.message}</p>
                      <p className="text-[10px] text-slate-400 mt-0.5">{new Date(n.created_at).toLocaleString()}</p>
                    </div>
                    {!n.read && <div className="w-2 h-2 bg-amber-500 rounded-full flex-shrink-0 mt-1.5" />}
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default NotificationBell;
