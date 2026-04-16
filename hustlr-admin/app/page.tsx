'use client';
import { useState, useEffect, useCallback } from 'react';
import dynamic from 'next/dynamic';
import { fetchPoolSummary, fetchApiHealth } from '@/lib/api';

export const metadata = {
  title: 'Admin Dashboard',
  description: 'Monitor insurance pool health, detect fraud, and analyze financial performance in real-time.',
};

// Dynamically import chart-heavy tabs so they SSR-safe
const PoolHealth      = dynamic(() => import('@/components/tabs/PoolHealth'),      { ssr: false });
const ZoneHeatmap     = dynamic(() => import('@/components/tabs/ZoneHeatmap'),     { ssr: false });
const FraudQueue      = dynamic(() => import('@/components/tabs/FraudQueue'),      { ssr: false });
const StressSimulator = dynamic(() => import('@/components/tabs/StressSimulator'), { ssr: false });
const Financials      = dynamic(() => import('@/components/tabs/Financials'),      { ssr: false });
const ProfitSimulator = dynamic(() => import('@/components/tabs/ProfitSimulator'), { ssr: false });

type TabId = 'pool' | 'zone' | 'fraud' | 'profit' | 'stress' | 'financials';

const TABS: Array<{ id: TabId; label: string; emoji: string }> = [
  { id: 'pool',       label: 'Pool Health',        emoji: '⚡' },
  { id: 'zone',       label: 'Zone Heatmap',       emoji: '📍' },
  { id: 'fraud',      label: 'Fraud Queue',         emoji: '🛡' },
  { id: 'profit',     label: 'Profit Simulator',    emoji: '📈' },
  { id: 'stress',     label: 'Stress Simulator',   emoji: '🌪' },
  { id: 'financials', label: 'Financials',          emoji: '📊' },
];

type ApiStatus = 'connecting' | 'live' | 'degraded' | 'offline';

const STORY_STEPS = [
  {
    step: '1',
    title: 'The person',
    copy: 'Name the worker precisely. Example: Ravi, 28, Delhi, Zomato rider, earning INR 18,000 per month.',
  },
  {
    step: '2',
    title: 'The disruption',
    copy: 'Anchor it to a measurable event with time and duration, like AQI above 300 on Tuesday evening leading to three days off-road.',
  },
  {
    step: '3',
    title: 'The loss',
    copy: 'Show the exact number lost, not a vague hardship. Example: INR 1,800 of income gone with rent due Friday.',
  },
  {
    step: '4',
    title: 'The protection',
    copy: 'Explain the automatic payout flow clearly: trigger fires, verification clears, money moves without claim chasing.',
  },
  {
    step: '5',
    title: 'The relief',
    copy: 'End with continuity. The worker rides next week, the family stays okay, and insurance proves its purpose.',
  },
];

const INSURANCE_CHECKLIST = [
  'Objective and verifiable triggers from trusted sources such as CPCB, IMD, or platform telemetry',
  'Scope restricted to income disruption, not health, life, or motor coverage',
  'Automatic payout flow tied to verification instead of manual review first',
  'Financial sustainability shown through BCR limits, reserve logic, and stress testing',
  'Fraud prevention based on cross-checkable data, not just behavioural scoring',
  'Frictionless premium collection via wallet, UPI, payroll, or platform integrations',
  'Dynamic pricing based on local risk and seasonality rather than a flat number',
  'Adverse-selection controls such as lock-out windows before known disaster events',
  'Operational cost discipline through automation and straight-through processing',
  'Basis-risk minimization by matching worker zone and trigger source at a granular level',
];

const COMPLIANCE_NOTES = [
  {
    title: 'IRDAI guidelines',
    copy: 'Claims must be fair, zero-touch where possible, and triggered from trusted independent public sources. Accuracy, fraud controls, and capital proof all matter.',
  },
  {
    title: 'Social Security Code, 2020',
    copy: 'Gig and platform workers are recognized as a protected class, so eligibility logic should be transparent wherever active-day thresholds affect benefits.',
  },
  {
    title: 'DPDP Act, 2023',
    copy: 'GPS, bank or UPI details, and platform activity data need explicit purpose limitation, informed consent, and careful storage practices.',
  },
];

export default function Dashboard() {
  const [tab, setTab]           = useState<TabId>('pool');
  const [pool, setPool]         = useState<Awaited<ReturnType<typeof fetchPoolSummary>> | null>(null);
  const [loading, setLoading]   = useState(true);
  const [apiStatus, setApiStatus] = useState<ApiStatus>('connecting');
  const [lastFetch, setLastFetch] = useState<string | null>(null);

  const refreshData = useCallback(async () => {
    try {
      setApiStatus('connecting');
      const [poolData] = await Promise.all([
        fetchPoolSummary(),
        fetchApiHealth(),
      ]);
      setPool(poolData);
      setApiStatus('live');
      setLastFetch(new Date().toLocaleTimeString('en-IN'));
    } catch {
      setApiStatus(pool ? 'degraded' : 'offline');
    } finally {
      setLoading(false);
    }
  }, [pool]);

  useEffect(() => {
    refreshData();
    const interval = setInterval(refreshData, 30000);
    return () => clearInterval(interval);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const dotColor = apiStatus === 'live' ? '#3FFF8B' : apiStatus === 'degraded' ? '#FF9800' : apiStatus === 'connecting' ? '#60a5fa' : '#E24B4A';
  const dotPulse = apiStatus === 'live' ? 'pulse-green' : apiStatus === 'offline' ? 'pulse-red' : apiStatus === 'connecting' ? 'pulse-blue' : '';

  return (
    <div className="min-h-screen flex flex-col">
      {/* ── Header ── */}
      <header
        className="sticky top-0 z-40 px-6 py-4 border-b flex items-center justify-between"
        style={{
          background: 'rgba(10,11,10,0.92)',
          backdropFilter: 'blur(16px)',
          borderColor: 'rgba(255,255,255,0.07)',
        }}
      >
        <div className="flex items-center gap-3">
          <div
            className="w-8 h-8 rounded-xl flex items-center justify-center"
            style={{ background: '#3FFF8B' }}
          >
            <span style={{ color: '#0A0B0A', fontSize: 15, fontWeight: 900 }}>H</span>
          </div>
          <div>
            <h1 className="font-black text-base leading-none">Hustlr</h1>
            <p className="text-xs leading-none mt-0.5" style={{ color: 'rgba(255,255,255,0.3)' }}>
              Insurer Admin Dashboard
            </p>
          </div>
        </div>

        <div className="flex items-center gap-5">
          {lastFetch && (
            <p className="text-xs hidden sm:block" style={{ color: 'rgba(255,255,255,0.28)' }}>
              Updated {lastFetch}
            </p>
          )}
          <div className="flex items-center gap-2">
            <span
              className={`w-2 h-2 rounded-full inline-block ${dotPulse}`}
              style={{ background: dotColor }}
            />
            <span className="text-xs font-bold uppercase tracking-wide" style={{ color: 'rgba(255,255,255,0.4)' }}>
              {apiStatus === 'live' ? 'Live' : apiStatus === 'degraded' ? 'Degraded' : apiStatus === 'connecting' ? 'Waking up…' : 'Offline'}
            </span>
          </div>
          <button
            onClick={refreshData}
            className="text-xs font-bold px-3 py-1.5 rounded-lg border transition-all"
            style={{ borderColor: 'rgba(255,255,255,0.1)', color: 'rgba(255,255,255,0.45)' }}
            onMouseEnter={e => {
              (e.currentTarget as HTMLElement).style.color = '#3FFF8B';
              (e.currentTarget as HTMLElement).style.borderColor = 'rgba(63,255,139,0.4)';
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLElement).style.color = 'rgba(255,255,255,0.45)';
              (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255,255,255,0.1)';
            }}
          >
            ↻ Refresh
          </button>
        </div>
      </header>

      {/* ── Tab bar ── */}
      <nav
        className="px-6 py-3 border-b flex gap-2 overflow-x-auto"
        style={{ borderColor: 'rgba(255,255,255,0.07)' }}
      >
        {TABS.map(t => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className="whitespace-nowrap px-4 py-2 rounded-xl border text-sm font-bold transition-all"
            style={
              tab === t.id
                ? { background: 'rgba(63,255,139,0.1)', borderColor: '#3FFF8B', color: '#3FFF8B' }
                : { background: 'transparent', borderColor: 'rgba(255,255,255,0.1)', color: '#91938D' }
            }
          >
            {t.emoji} {t.label}
          </button>
        ))}
      </nav>

      {/* ── Content ── */}
      <main className="flex-1 p-6 w-full max-w-7xl mx-auto">
        {tab === 'pool'       && <PoolHealth      pool={pool} loading={loading} />}
        {tab === 'zone'       && <ZoneHeatmap />}
        {tab === 'fraud'      && <FraudQueue />}
        {tab === 'profit'     && <ProfitSimulator />}
        {tab === 'stress'     && <StressSimulator />}
        {tab === 'financials' && <Financials />}

        {tab === 'pool' && (
          <section className="mt-10 space-y-8">
            <div
              className="rounded-3xl border p-6"
              style={{
                background: 'linear-gradient(180deg, rgba(7,53,74,0.96), rgba(4,31,44,0.96))',
                borderColor: 'rgba(95,225,255,0.18)',
              }}
            >
              <p className="text-xs font-black uppercase tracking-[0.24em]" style={{ color: '#F6C445' }}>
                Storytelling Framework
              </p>
              <h2 className="mt-2 text-2xl font-black">Tell Hustlr like a real insurance product</h2>
              <p className="mt-2 max-w-3xl text-sm leading-6" style={{ color: 'rgba(255,255,255,0.68)' }}>
                These five beats help explain the product in demos, judge conversations, and partner pitches with specificity instead of generic fintech language.
              </p>

              <div className="mt-6 grid gap-4 md:grid-cols-5">
                {STORY_STEPS.map((item) => (
                  <div
                    key={item.step}
                    className="rounded-2xl border p-5"
                    style={{
                      background: 'rgba(255,255,255,0.97)',
                      borderColor: 'rgba(246,196,69,0.28)',
                      color: '#082533',
                    }}
                  >
                    <div
                      className="mb-4 flex h-10 w-10 items-center justify-center rounded-full text-lg font-black"
                      style={{ background: '#27C1F0', color: '#082533' }}
                    >
                      {item.step}
                    </div>
                    <h3 className="text-lg font-black">{item.title}</h3>
                    <p className="mt-3 text-sm leading-6" style={{ color: 'rgba(8,37,51,0.82)' }}>
                      {item.copy}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
              <div
                className="rounded-3xl border p-6"
                style={{
                  background: 'linear-gradient(180deg, rgba(7,53,74,0.96), rgba(4,31,44,0.96))',
                  borderColor: 'rgba(95,225,255,0.18)',
                }}
              >
                <p className="text-xs font-black uppercase tracking-[0.24em]" style={{ color: '#F6C445' }}>
                  Insurance Checklist
                </p>
                <h2 className="mt-2 text-2xl font-black">Does the solution make insurance sense?</h2>
                <div className="mt-6 grid gap-4 md:grid-cols-2">
                  {INSURANCE_CHECKLIST.map((item, index) => (
                    <div
                      key={item}
                      className="flex gap-4 rounded-2xl border p-4"
                      style={{
                        borderColor: 'rgba(255,255,255,0.08)',
                        background: 'rgba(255,255,255,0.03)',
                      }}
                    >
                      <div
                        className="mt-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-black"
                        style={{ background: '#F6C445', color: '#082533' }}
                      >
                        {index + 1}
                      </div>
                      <p className="text-sm leading-6" style={{ color: 'rgba(255,255,255,0.78)' }}>
                        {item}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              <div
                className="rounded-3xl border p-6"
                style={{
                  background: 'linear-gradient(180deg, rgba(7,53,74,0.96), rgba(4,31,44,0.96))',
                  borderColor: 'rgba(95,225,255,0.18)',
                }}
              >
                <p className="text-xs font-black uppercase tracking-[0.24em]" style={{ color: '#F6C445' }}>
                  Regulatory Notes
                </p>
                <h2 className="mt-2 text-2xl font-black">IRDAI, Social Security Code, and DPDP framing</h2>
                <div className="mt-6 space-y-4">
                  {COMPLIANCE_NOTES.map((item) => (
                    <div
                      key={item.title}
                      className="rounded-2xl border p-4"
                      style={{
                        borderColor: 'rgba(255,255,255,0.08)',
                        background: 'rgba(255,255,255,0.03)',
                      }}
                    >
                      <h3 className="text-base font-black" style={{ color: '#56D6FF' }}>
                        {item.title}
                      </h3>
                      <p className="mt-2 text-sm leading-6" style={{ color: 'rgba(255,255,255,0.75)' }}>
                        {item.copy}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </section>
        )}
      </main>

      {/* ── Footer ── */}
      <footer
        className="px-6 py-3 border-t flex flex-col sm:flex-row items-center justify-between gap-1"
        style={{ borderColor: 'rgba(255,255,255,0.07)' }}
      >
        <p className="text-xs" style={{ color: 'rgba(255,255,255,0.2)' }}>
          Hustlr Parametric Insurance · Guidewire DEVTrails 2026
        </p>
        <p className="text-xs" style={{ color: 'rgba(255,255,255,0.2)' }}>
          BCR ceiling 85% · Reinsurance at 4× weekly pool · IsolationForest fraud scoring
        </p>
      </footer>
    </div>
  );
}
