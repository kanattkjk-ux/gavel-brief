import React, { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import Footer from '../components/Footer';
import {
  FileText, Scale, Users, Video, Building2, Calendar,
  ScrollText, Map, Mic2, BookOpen, ArrowRight, Shield,
  Briefcase, ClipboardList, Star, Zap, ChevronRight
} from 'lucide-react';
import Navbar from '../components/Navbar';
import { useAuth } from '../contexts/AuthContext';

/* ─── helpers ─── */
const useEntrance = () => {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { el.classList.add('vs-visible'); obs.disconnect(); } },
      { threshold: 0.08 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);
  return ref;
};

/* ─── data ─── */
const FEATURED = [
  {
    id: 'post-case',
    label: 'Post a Case',
    badge: 'AI-Powered · Most Popular',
    desc: 'Submit your legal matter and receive instant AI-powered analysis. Verified lawyers respond with tailored proposals and competitive rates.',
    icon: Scale,
    cta: 'Post Your Case',
    path: '/client/dashboard',
    requiresAuth: true,
    role: 'client',
    primary: true,
    testId: 'service-post-case',
  },
  {
    id: 'affidavit',
    label: 'Affidavit Builder',
    badge: 'Flagship Document Tool',
    desc: 'Draft court-ready affidavits in minutes. Our intelligent builder guides you through every clause, ensuring legal precision and compliance.',
    icon: FileText,
    cta: 'Build Affidavit',
    path: '/client/affidavit',
    requiresAuth: true,
    role: 'client',
    primary: false,
    testId: 'service-affidavit',
  },
];

const SECONDARY = [
  { label: 'Online Consultation', desc: 'Video & chat sessions with verified lawyers', icon: Video, path: '/client/consultations', requiresAuth: true },
  { label: 'Lawyer Matching', desc: 'AI-matched lawyers by specialisation & location', icon: Users, path: '/client/lawyers', requiresAuth: true },
  { label: 'VakilVoice AI', desc: 'Voice-guided legal Q&A powered by AI', icon: Mic2, path: '/client/dashboard', requiresAuth: true },
  { label: 'Legal CRM', desc: 'Manage clients, cases and follow-ups in one place', icon: Briefcase, path: '/client/cases', requiresAuth: true },
  { label: 'Referral Exchange', desc: 'Refer and receive cases within the Gavel & Brief network', icon: Star, path: '/client/dashboard', requiresAuth: true },
  { label: 'Geo-Legal Map', desc: 'Find nearby courts, lawyers and legal-aid centres', icon: Map, path: '/client/lawyers', requiresAuth: true },
  { label: 'Case Tracking', desc: 'Real-time updates on your active cases and hearings', icon: ClipboardList, path: '/client/cases', requiresAuth: true },
  { label: 'IPC Browser', desc: 'Search Indian Penal Code sections and case law', icon: ScrollText, path: '/ipc', requiresAuth: false },
  { label: 'Law Firms', desc: 'Explore verified law firms and their practice areas', icon: Building2, path: '/firms', requiresAuth: true },
  { label: 'My Bookings', desc: 'View and manage all your scheduled lawyer sessions', icon: Calendar, path: '/client/bookings', requiresAuth: true },
  { label: 'My Cases', desc: 'Full archive of all cases you have posted', icon: BookOpen, path: '/client/cases', requiresAuth: true },
  { label: 'New Case Form', desc: 'Step-by-step guided form to submit a new matter', icon: Zap, path: '/client/case/new', requiresAuth: true },
];

const TRUST = [
  { n: '50,000+', l: 'Cases Resolved' },
  { n: '3,200+', l: 'Verified Lawyers' },
  { n: '98%', l: 'Satisfaction Rate' },
  { n: '24 hrs', l: 'Avg. Response Time' },
];

/* ─── sub-components ─── */
const FeaturedCard = ({ svc, onGo }) => {
  const ref = useEntrance();
  const Icon = svc.icon;
  return (
    <div
      ref={ref}
      className={`vs-card-entrance group relative overflow-hidden rounded-3xl cursor-pointer select-none
        transition-all duration-300 ease-out
        hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(109,7,26,0.22)]
        ${svc.primary
          ? 'bg-gradient-to-br from-[#6D071A] via-[#800020] to-[#5a0616] border-2 border-[#D4AF37]/40 shadow-[0_20px_48px_rgba(109,7,26,0.28)]'
          : 'bg-white border-2 border-[#EFE7D6] shadow-[0_18px_45px_rgba(109,7,26,0.08)] hover:border-[#D4AF37]/60'
        }`}
      onClick={() => onGo(svc)}
      data-testid={svc.testId}
    >
      {/* Glow orb */}
      {svc.primary && (
        <div className="pointer-events-none absolute -top-16 -right-16 w-56 h-56 rounded-full bg-[#D4AF37]/10 blur-3xl group-hover:bg-[#D4AF37]/20 transition-all duration-500" />
      )}

      <div className="relative p-8 sm:p-10 flex flex-col h-full min-h-[320px]">
        {/* Badge */}
        <div className={`inline-flex items-center gap-1.5 self-start rounded-full px-3 py-1 text-xs font-semibold mb-6
          ${svc.primary ? 'bg-[#D4AF37]/20 text-[#D4AF37] border border-[#D4AF37]/30' : 'bg-[#6D071A]/8 text-[#6D071A] border border-[#6D071A]/15'}`}>
          <span className="w-1.5 h-1.5 rounded-full bg-current animate-pulse" />
          {svc.badge}
        </div>

        {/* Icon */}
        <div className={`w-16 h-16 rounded-2xl flex items-center justify-center mb-6 transition-transform duration-300 group-hover:scale-110
          ${svc.primary ? 'bg-white/15 border border-white/20' : 'bg-gradient-to-br from-[#6D071A] to-[#800020]'}`}>
          <Icon className={`w-8 h-8 ${svc.primary ? 'text-white' : 'text-white'}`} />
        </div>

        {/* Text */}
        <h2 className={`font-heading text-2xl sm:text-3xl font-bold mb-3 tracking-tight
          ${svc.primary ? 'text-white' : 'text-[#171717]'}`}>
          {svc.label}
        </h2>
        <p className={`text-base leading-relaxed flex-1 mb-8
          ${svc.primary ? 'text-white/80' : 'text-[#57534E]'}`}>
          {svc.desc}
        </p>

        {/* CTA */}
        <div className={`inline-flex items-center gap-2 font-semibold text-sm transition-all duration-200 group-hover:gap-3
          ${svc.primary ? 'text-[#D4AF37]' : 'text-[#6D071A]'}`}>
          {svc.cta}
          <ArrowRight className="w-4 h-4 transition-transform duration-200 group-hover:translate-x-1" />
        </div>
      </div>
    </div>
  );
};

const SecondaryCard = ({ svc, onGo, delay }) => {
  const ref = useEntrance();
  const Icon = svc.icon;
  return (
    <div
      ref={ref}
      className="vs-card-entrance group relative bg-white border border-[#EFE7D6] rounded-2xl p-5
        cursor-pointer transition-all duration-250 ease-out
        hover:-translate-y-1 hover:border-[#D4AF37]/50 hover:shadow-[0_12px_32px_rgba(109,7,26,0.10)]"
      style={{ transitionDelay: `${delay}ms` }}
      onClick={() => onGo(svc)}
    >
      <div className="flex items-start gap-4">
        <div className="w-10 h-10 rounded-xl bg-[#6D071A]/6 flex items-center justify-center flex-shrink-0 transition-all duration-200 group-hover:bg-[#6D071A] group-hover:scale-110">
          <Icon className="w-5 h-5 text-[#6D071A] transition-colors duration-200 group-hover:text-white" />
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-[#171717] text-sm mb-1 group-hover:text-[#6D071A] transition-colors duration-200">
            {svc.label}
          </h3>
          <p className="text-xs text-[#57534E] leading-relaxed line-clamp-2">{svc.desc}</p>
        </div>
        <ChevronRight className="w-4 h-4 text-[#EFE7D6] flex-shrink-0 mt-0.5 group-hover:text-[#D4AF37] transition-colors duration-200" />
      </div>
    </div>
  );
};

/* ─── page ─── */
const Services = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const heroRef = useEntrance();

  const handleGo = ({ path, requiresAuth, role }) => {
    if (requiresAuth && !user) { navigate('/login'); return; }
    if (role && user?.role !== role) { navigate('/login'); return; }
    navigate(path);
  };

  return (
    <>
      <style>{`
        @keyframes vs-fade-up {
          from { opacity: 0; transform: translateY(24px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        .vs-card-entrance { opacity: 0; transform: translateY(20px); transition: opacity 0.5s ease, transform 0.5s ease; }
        .vs-visible { opacity: 1 !important; transform: translateY(0) !important; }
        .vs-hero { animation: vs-fade-up 0.7s cubic-bezier(0.22,1,0.36,1) both; }
        .vs-hero-delay { animation: vs-fade-up 0.7s 0.15s cubic-bezier(0.22,1,0.36,1) both; }
      `}</style>

      <div className="min-h-screen bg-[#FFFDF7]" data-testid="services-page">
        <Navbar />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-14 sm:py-20">

          {/* ── Hero header ── */}
          <div ref={heroRef} className="text-center mb-14 vs-hero">
            <div className="inline-flex items-center gap-2 bg-[#6D071A]/8 border border-[#6D071A]/15 rounded-full px-4 py-1.5 mb-5">
              <Shield className="w-3.5 h-3.5 text-[#6D071A]" />
              <span className="text-xs font-semibold text-[#6D071A] tracking-wide uppercase">India's Premier Legal Services Platform</span>
            </div>
            <h1 className="font-heading text-4xl sm:text-5xl lg:text-6xl font-bold text-[#171717] tracking-tight mb-5 leading-tight">
              Your Legal Services{' '}
              <span className="text-[#6D071A] relative inline-block">
                Hub
                <span className="absolute -bottom-1 left-0 right-0 h-0.5 bg-gradient-to-r from-[#D4AF37] to-[#6D071A] rounded-full" />
              </span>
            </h1>
            <p className="text-lg text-[#57534E] max-w-2xl mx-auto leading-relaxed vs-hero-delay">
              Everything you need for expert legal assistance — AI-powered, transparent, and trusted by thousands across India.
            </p>
          </div>

          {/* ── Trust bar ── */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-16 vs-hero-delay">
            {TRUST.map(({ n, l }) => (
              <div key={l} className="text-center bg-white border border-[#EFE7D6] rounded-2xl py-4 px-3 shadow-sm">
                <div className="font-heading text-2xl font-bold text-[#6D071A]">{n}</div>
                <div className="text-xs text-[#57534E] mt-0.5 font-medium">{l}</div>
              </div>
            ))}
          </div>

          {/* ── Section: Priority label ── */}
          <div className="flex items-center gap-3 mb-6">
            <div className="flex items-center gap-2 bg-[#6D071A] text-white rounded-full px-4 py-1.5 text-xs font-bold tracking-wide uppercase">
              <Zap className="w-3.5 h-3.5 text-[#D4AF37]" />
              Flagship Services
            </div>
            <div className="flex-1 h-px bg-[#EFE7D6]" />
          </div>

          {/* ── Featured cards ── */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-16">
            {FEATURED.map((svc) => (
              <FeaturedCard key={svc.id} svc={svc} onGo={handleGo} />
            ))}
          </div>

          {/* ── Section: Secondary label ── */}
          <div className="flex items-center gap-3 mb-6">
            <div className="flex items-center gap-2 bg-white border border-[#EFE7D6] text-[#57534E] rounded-full px-4 py-1.5 text-xs font-semibold tracking-wide uppercase">
              All Services
            </div>
            <div className="flex-1 h-px bg-[#EFE7D6]" />
          </div>

          {/* ── Secondary grid ── */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 mb-20">
            {SECONDARY.map((svc, i) => (
              <SecondaryCard key={svc.label} svc={svc} onGo={handleGo} delay={i * 40} />
            ))}
          </div>

          {/* ── Why Gavel & Brief ── */}
          <div className="bg-gradient-to-br from-[#6D071A] via-[#800020] to-[#5a0616] rounded-3xl shadow-[0_24px_60px_rgba(109,7,26,0.25)] p-10 sm:p-14 relative overflow-hidden">
            <div className="pointer-events-none absolute -top-20 -right-20 w-72 h-72 rounded-full bg-[#D4AF37]/8 blur-3xl" />
            <div className="pointer-events-none absolute -bottom-16 -left-16 w-56 h-56 rounded-full bg-white/4 blur-2xl" />

            <div className="relative grid grid-cols-1 lg:grid-cols-3 gap-10">
              <div className="lg:col-span-1">
                <div className="inline-flex items-center gap-2 bg-[#D4AF37]/20 border border-[#D4AF37]/30 rounded-full px-3 py-1 text-xs font-semibold text-[#D4AF37] mb-4">
                  Trusted Platform
                </div>
                <h2 className="font-heading text-3xl sm:text-4xl font-bold text-white leading-tight mb-4">
                  Why Choose Gavel & Brief?
                </h2>
                <p className="text-white/70 leading-relaxed">
                  India's most trusted legal-tech platform with AI intelligence and verified professionals.
                </p>
              </div>

              <div className="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-6">
                {[
                  { t: 'Verified Lawyers', d: 'All lawyers are bar-certified and background-verified with proven track records.' },
                  { t: 'AI-Powered Analysis', d: 'Instant case analysis with IPC section mapping and outcome probability.' },
                  { t: 'Transparent Pricing', d: 'No hidden charges. Know exactly what you pay before you commit.' },
                  { t: 'Quick Response', d: 'Get lawyer responses within 24 hours of case submission.' },
                ].map(({ t, d }) => (
                  <div key={t} className="flex gap-4">
                    <div className="w-8 h-8 rounded-xl bg-[#D4AF37]/20 border border-[#D4AF37]/30 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <Shield className="w-4 h-4 text-[#D4AF37]" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-white text-sm mb-1">{t}</h4>
                      <p className="text-white/60 text-sm leading-relaxed">{d}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
      <Footer />
    </>
  );
};

export default Services;
