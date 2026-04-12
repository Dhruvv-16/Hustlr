'use client';
import { useState, useEffect, useCallback } from 'react';
import dynamic from 'next/dynamic';
import { fetchPoolSummary, fetchApiHealth } from '@/lib/api';

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
