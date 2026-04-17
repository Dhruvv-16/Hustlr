'use client';

import { useEffect, useMemo, useState } from 'react';
import dynamic from 'next/dynamic';
import {
  Activity,
  BadgeAlert,
  Briefcase,
  CreditCard,
  Database,
  DollarSign,
  FileText,
  HeartPulse,
  LineChart,
  MonitorCheck,
  PlugZap,
  RefreshCw,
  Siren,
  SlidersHorizontal,
  Shield,
  Timer,
  TrendingUp,
  Users,
  Wallet,
  Radar,
} from 'lucide-react';
import AdminApiService from '@/lib/api-service';
import { fetchPoolSummary } from '@/lib/api';
import type { AdminAnalytics, FraudCase, PayoutRequest, SystemHealth } from '@/lib/mock-data';

const FraudQueue = dynamic(() => import('@/components/FraudQueue'));
const UserManagement = dynamic(() => import('@/components/UserManagement'));
const PolicyManagement = dynamic(() => import('@/components/PolicyManagement'));
const PaymentQueue = dynamic(() => import('@/components/PaymentQueue'));
const H3RiskMap = dynamic(() => import('@/components/H3RiskMap'), { ssr: false });
const PoolHealth = dynamic(() => import('@/components/tabs/PoolHealth'));
const ProfitSimulator = dynamic(() => import('@/components/tabs/ProfitSimulator'));
const StressSimulator = dynamic(() => import('@/components/tabs/StressSimulator'));
const Financials = dynamic(() => import('@/components/tabs/Financials'));
const AnalyticsPanel = dynamic(() => import('@/components/AnalyticsPanel'));

const FILTERS = [
  { id: 'all', label: 'All' },
  { id: 'operations', label: 'Operations' },
  { id: 'financial', label: 'Financial' },
  { id: 'review', label: 'Review' },
] as const;

type ViewFilter = (typeof FILTERS)[number]['id'];

export default function AdminDashboard() {
  const [analytics, setAnalytics] = useState<AdminAnalytics | null>(null);
  const [systemHealth, setSystemHealth] = useState<SystemHealth | null>(null);
  const [poolSummary, setPoolSummary] = useState<Awaited<ReturnType<typeof fetchPoolSummary>> | null>(null);
  const [fraudHighlights, setFraudHighlights] = useState<FraudCase[]>([]);
  const [payoutHighlights, setPayoutHighlights] = useState<PayoutRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [useMockData, setUseMockData] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<ViewFilter>('all');
  const [lastRefresh, setLastRefresh] = useState<string>('');
  const [autoRefreshEnabled, setAutoRefreshEnabled] = useState(true);
  const [refreshEverySec, setRefreshEverySec] = useState(30);

  useEffect(() => {
    loadData();
  }, [useMockData]);

  useEffect(() => {
    if (!autoRefreshEnabled || refreshEverySec < 10) return;

    const timer = setInterval(() => {
      loadData(false);
    }, refreshEverySec * 1000);

    return () => clearInterval(timer);
  }, [autoRefreshEnabled, refreshEverySec, useMockData]);

  const loadData = async (showLoader = true) => {
    if (showLoader) setLoading(true);
    setErrorMessage(null);

    try {
      const [analyticsData, healthData, poolData, fraudData, payoutData] = await Promise.all([
        AdminApiService.getAnalytics(),
        AdminApiService.getSystemHealth(),
        fetchPoolSummary().catch(() => null),
        AdminApiService.getFraudQueue({ limit: 5, status: 'FLAGGED' }),
        AdminApiService.getPayoutQueue({ limit: 5, status: 'APPROVED' }),
      ]);

      setAnalytics(analyticsData);
      setSystemHealth(healthData);
      setPoolSummary(poolData);
      setFraudHighlights(fraudData);
      setPayoutHighlights(payoutData);
      setLastRefresh(new Date().toLocaleTimeString('en-IN'));
    } catch {
      setErrorMessage('Failed to load data');
    } finally {
      if (showLoader) setLoading(false);
    }
  };

  const toggleDataSource = () => {
    setUseMockData(!useMockData);
    AdminApiService.setUseMockData(!useMockData);
  };

  const healthMeta = useMemo(() => {
    if (!systemHealth) {
      return { healthyApis: 0, totalApis: 0, livePct: 0, degraded: false };
    }

    const healthyApis = systemHealth.apis.filter((api) => api.ok).length;
    const totalApis = systemHealth.apis.length;
    const livePct = totalApis > 0 ? Math.round((healthyApis / totalApis) * 100) : 0;

    return {
      healthyApis,
      totalApis,
      livePct,
      degraded: healthyApis !== totalApis,
    };
  }, [systemHealth]);

  const connectionLabel = useMemo(() => {
    if (!systemHealth) return { label: 'DISCONNECTED', tone: 'border-red-500/30 bg-red-500/10 text-red-200' };
    return healthMeta.degraded
      ? { label: 'DEGRADED', tone: 'border-amber-500/30 bg-amber-500/10 text-amber-200' }
      : { label: 'LIVE', tone: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-200' };
  }, [healthMeta.degraded, systemHealth]);

  if (loading) {
    return <LoadingState />;
  }

  if (errorMessage) {
    return <ErrorState errorMessage={errorMessage} onRetry={() => loadData(true)} />;
  }

  const showAll = activeFilter === 'all';
  const showOperations = showAll || activeFilter === 'operations';
  const showFinancial = showAll || activeFilter === 'financial';
  const showReview = showAll || activeFilter === 'review';

  return (
    <div className="min-h-screen bg-[#0a0a0a] text-white">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-[#111111]/95 backdrop-blur-xl">
        <div className="flex items-center justify-between gap-4 px-4 py-3 md:px-6">
          <div className="flex min-w-0 items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-emerald-300">
              <Database className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-white/40">Hustlr</p>
              <h1 className="truncate text-lg font-semibold text-white">Admin Console</h1>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-end gap-2">
            <div className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold ${connectionLabel.tone}`}>
              <MonitorCheck className="h-3.5 w-3.5" />
              {connectionLabel.label}
            </div>
            <button
              onClick={toggleDataSource}
              className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold transition ${
                useMockData ? 'border-orange-500/25 bg-orange-500/10 text-orange-200' : 'border-emerald-500/25 bg-emerald-500/10 text-emerald-200'
              }`}
              title={useMockData ? 'Switch to Real Data' : 'Switch to Demo Data'}
            >
              <PlugZap className="h-3.5 w-3.5" />
              {useMockData ? 'Demo Mode' : 'Live Mode'}
            </button>
            <button
              onClick={() => loadData(true)}
              className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 transition hover:bg-white/10"
            >
              <RefreshCw className="h-3.5 w-3.5" />
              Refresh
            </button>
            <span className="hidden rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-white/45 md:inline-flex">
              Updated {lastRefresh || '--:--:--'}
            </span>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl space-y-5 p-4 md:p-6">
        <div className="rounded-2xl border border-white/10 bg-[#111111] p-4 md:p-5">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <p className="text-[11px] font-bold uppercase tracking-[0.24em] text-white/35">Control Room</p>
              <h2 className="mt-1 text-xl font-semibold text-white">One page. Filtered view. No extra divisions.</h2>
              <p className="mt-1 text-sm text-white/45">Use the chips to switch between operations, financial, and review layers instead of jumping through separate pages.</p>
            </div>
            <div className="flex flex-wrap gap-2">
              {FILTERS.map((filter) => (
                <button
                  key={filter.id}
                  onClick={() => setActiveFilter(filter.id)}
                  className={`rounded-full border px-4 py-2 text-sm font-semibold transition ${
                    activeFilter === filter.id
                      ? 'border-emerald-400/30 bg-emerald-500/15 text-emerald-200'
                      : 'border-white/10 bg-white/5 text-white/70 hover:bg-white/10 hover:text-white'
                  }`}
                >
                  {filter.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {analytics && (
          <>
            <section className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
              <MetricCard title="Total Claims" value={analytics.summary.totalClaims.toString()} subtitle={`${analytics.summary.flaggedClaims} flagged`} icon={<Database className="h-5 w-5" />} tone="blue" />
              <MetricCard title="Total Payouts" value={`₹${(analytics.summary.totalPayout / 100000).toFixed(1)}L`} subtitle="Last 30 days" icon={<DollarSign className="h-5 w-5" />} tone="green" />
              <MetricCard title="Premiums" value={`₹${(analytics.summary.totalPremium / 100000).toFixed(1)}L`} subtitle="Collected" icon={<Briefcase className="h-5 w-5" />} tone="purple" />
              <MetricCard title="Loss Ratio" value={`${analytics.summary.lossRatio.toFixed(1)}%`} subtitle={analytics.summary.lossRatio > 80 ? 'High' : 'Normal'} icon={<TrendingUp className="h-5 w-5" />} tone={analytics.summary.lossRatio > 80 ? 'orange' : 'green'} />
            </section>

            {showAll && (
              <section className="rounded-2xl border border-white/10 bg-[#111111] p-5">
                <div className="grid gap-4 md:grid-cols-3">
                  <MiniStat icon={<BadgeAlert className="h-4 w-4" />} label="Fraud Alerts" value={analytics.summary.flaggedClaims} tone="red" />
                  <MiniStat icon={<HeartPulse className="h-4 w-4" />} label="API Live Rate" value={`${healthMeta.livePct}%`} tone="emerald" />
                  <MiniStat icon={<Timer className="h-4 w-4" />} label="Last Refresh" value={lastRefresh || '--:--'} tone="blue" />
                </div>
              </section>
            )}

            {showOperations && (
              <section className="space-y-4">
                <SectionTitle icon={<Shield className="h-4 w-4" />} title="Operations" subtitle="Fraud, riders, policies, and approvals on one screen" />
                <div className="grid gap-4 xl:grid-cols-2">
                  <CompactCard title="Top Fraud Queue" accent="red">
                    <FraudQueue />
                  </CompactCard>
                  <CompactCard title="Riders" accent="blue">
                    <UserManagement />
                  </CompactCard>
                  <CompactCard title="Policies" accent="green">
                    <PolicyManagement />
                  </CompactCard>
                  <CompactCard title="Payments" accent="orange">
                    <PaymentQueue />
                  </CompactCard>
                </div>
              </section>
            )}

            {showFinancial && (
              <section className="space-y-4">
                <SectionTitle icon={<Wallet className="h-4 w-4" />} title="Financial" subtitle="Reserve, pricing, stress, and revenue in one condensed area" />
                <div className="grid gap-4 xl:grid-cols-2">
                  <CompactCard title="Reserves & Stress" accent="emerald">
                    <PoolHealth pool={poolSummary} loading={false} />
                  </CompactCard>
                  <CompactCard title="Plans & Pricing" accent="purple">
                    <ProfitSimulator />
                  </CompactCard>
                  <CompactCard title="Stress Tests" accent="orange">
                    <StressSimulator />
                  </CompactCard>
                  <CompactCard title="Revenue & Loss" accent="blue">
                    <Financials />
                  </CompactCard>
                </div>
              </section>
            )}

            {showReview && (
              <section className="space-y-4">
                <SectionTitle icon={<Radar className="h-4 w-4" />} title="Review" subtitle="Analytics, map, and system status together" />
                <div className="grid gap-4 xl:grid-cols-2">
                  <CompactCard title="Analytics" accent="emerald">
                    <AnalyticsPanel analytics={analytics} />
                  </CompactCard>
                  <CompactCard title="Risk Map" accent="red">
                    <H3RiskMap />
                  </CompactCard>
                  <CompactCard title="System Health" accent="blue">
                    <SystemHealthPanel systemHealth={systemHealth} healthMeta={healthMeta} />
                  </CompactCard>
                  <CompactCard title="Demo Controls" accent="purple">
                    <SettingsPanel
                      useMockData={useMockData}
                      toggleDataSource={toggleDataSource}
                      autoRefreshEnabled={autoRefreshEnabled}
                      setAutoRefreshEnabled={setAutoRefreshEnabled}
                      refreshEverySec={refreshEverySec}
                      setRefreshEverySec={setRefreshEverySec}
                    />
                  </CompactCard>
                </div>
              </section>
            )}
          </>
        )}
      </main>
    </div>
  );
}

function LoadingState() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[#0a0a0a] text-white">
      <div className="text-center">
        <RefreshCw className="mx-auto mb-4 h-12 w-12 animate-spin text-emerald-400" />
        <p className="text-white/80">Loading analytics...</p>
      </div>
    </div>
  );
}

function ErrorState({ errorMessage, onRetry }: { errorMessage: string; onRetry: () => void }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[#0a0a0a] text-white">
      <div className="text-center">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-red-500/20">
          <Activity className="h-8 w-8 text-red-400" />
        </div>
        <p className="mb-2 text-xl font-semibold text-white">Error Loading Data</p>
        <p className="mb-6 text-gray-400">{errorMessage}</p>
        <button onClick={onRetry} className="rounded-lg bg-emerald-500 px-6 py-2 font-semibold text-white hover:bg-emerald-600">
          Retry
        </button>
      </div>
    </div>
  );
}

function SectionTitle({ icon, title, subtitle }: { icon: React.ReactNode; title: string; subtitle: string }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/10 bg-[#111111] px-4 py-3">
      <div className="flex items-center gap-3">
        <span className="text-emerald-300">{icon}</span>
        <div>
          <h3 className="font-semibold text-white">{title}</h3>
          <p className="text-sm text-white/45">{subtitle}</p>
        </div>
      </div>
    </div>
  );
}

function MetricCard({
  title,
  value,
  subtitle,
  icon,
  tone,
}: {
  title: string;
  value: string;
  subtitle: string;
  icon: React.ReactNode;
  tone: 'blue' | 'green' | 'purple' | 'orange';
}) {
  const toneClasses: Record<typeof tone, string> = {
    blue: 'text-sky-300 border-sky-500/20 bg-sky-500/5',
    green: 'text-emerald-300 border-emerald-500/20 bg-emerald-500/5',
    purple: 'text-violet-300 border-violet-500/20 bg-violet-500/5',
    orange: 'text-orange-300 border-orange-500/20 bg-orange-500/5',
  };

  return (
    <div className={`rounded-2xl border p-4 ${toneClasses[tone]}`}>
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs uppercase tracking-wide text-white/45">{title}</p>
          <p className={`mt-2 text-2xl font-semibold ${toneClasses[tone].split(' ')[0]}`}>{value}</p>
          <p className="mt-1 text-xs text-white/45">{subtitle}</p>
        </div>
        <div className="text-white/70">{icon}</div>
      </div>
    </div>
  );
}

function MiniStat({
  icon,
  label,
  value,
  tone,
}: {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  tone: 'red' | 'emerald' | 'blue';
}) {
  const classes: Record<typeof tone, string> = {
    red: 'border-red-500/20 bg-red-500/5 text-red-200',
    emerald: 'border-emerald-500/20 bg-emerald-500/5 text-emerald-200',
    blue: 'border-sky-500/20 bg-sky-500/5 text-sky-200',
  };

  return (
    <div className={`rounded-2xl border p-4 ${classes[tone]}`}>
      <div className="flex items-center gap-2 text-sm font-semibold">{icon}<span>{label}</span></div>
      <p className="mt-3 text-2xl font-semibold text-white">{value}</p>
    </div>
  );
}

function CompactCard({ title, accent, children }: { title: string; accent: 'red' | 'blue' | 'green' | 'orange' | 'purple' | 'emerald'; children: React.ReactNode }) {
  const accentClasses: Record<typeof accent, string> = {
    red: 'border-red-500/20',
    blue: 'border-sky-500/20',
    green: 'border-emerald-500/20',
    orange: 'border-orange-500/20',
    purple: 'border-violet-500/20',
    emerald: 'border-emerald-500/20',
  };

  return (
    <div className={`rounded-2xl border ${accentClasses[accent]} bg-[#111111] p-4`}>
      <p className="mb-3 text-xs font-bold uppercase tracking-[0.24em] text-white/35">{title}</p>
      <div className="overflow-hidden rounded-xl">{children}</div>
    </div>
  );
}

// AnalyticsPanel is now the dynamic import from @/components/AnalyticsPanel

function Bucket({ value, label, tone }: { value: number; label: string; tone: 'emerald' | 'orange' | 'red' }) {
  const tones: Record<typeof tone, string> = {
    emerald: 'border-emerald-500/20 bg-emerald-500/10 text-emerald-200',
    orange: 'border-orange-500/20 bg-orange-500/10 text-orange-200',
    red: 'border-red-500/20 bg-red-500/10 text-red-200',
  };

  return (
    <div className={`rounded-lg border p-3 ${tones[tone]}`}>
      <p className="text-xs uppercase tracking-wide">{label}</p>
      <p className="mt-1 text-xl font-semibold text-white">{value}</p>
    </div>
  );
}

function SystemHealthPanel({
  systemHealth,
  healthMeta,
}: {
  systemHealth: SystemHealth | null;
  healthMeta: { healthyApis: number; totalApis: number; livePct: number; degraded: boolean };
}) {
  if (!systemHealth) return null;

  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-white/10 bg-black/20 p-4">
        <div className="flex items-center justify-between gap-3">
          <h4 className="text-sm font-semibold text-white">System Monitoring</h4>
          <span className={`rounded-full border px-3 py-1 text-xs font-semibold ${healthMeta.degraded ? 'border-amber-500/20 bg-amber-500/10 text-amber-200' : 'border-emerald-500/20 bg-emerald-500/10 text-emerald-200'}`}>
            {healthMeta.degraded ? 'DEGRADED' : 'OPERATIONAL'}
          </span>
        </div>
        <p className="mt-2 text-sm text-white/45">
          {healthMeta.healthyApis}/{healthMeta.totalApis} services healthy, {healthMeta.livePct}% live.
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          {systemHealth.apis.map((api) => (
            <span key={api.name} className={`rounded-full border px-2.5 py-1 text-xs ${api.ok ? 'border-emerald-500/20 bg-emerald-500/10 text-emerald-200' : 'border-red-500/20 bg-red-500/10 text-red-200'}`}>
              {api.name}
            </span>
          ))}
        </div>
      </div>
      <div className="rounded-xl border border-white/10 bg-black/20 p-4">
        <h4 className="text-sm font-semibold text-white">Live Queue Snapshot</h4>
        <div className="mt-3 space-y-2 text-sm text-white/70">
          <p>Flagged cases: {systemHealth.lastAdjudicatorRun?.claimsCreated ?? 0}</p>
          <p>Last adjudicator run: {systemHealth.lastAdjudicatorRun ? `${systemHealth.lastAdjudicatorRun.durationMs}ms` : '—'}</p>
          <p>24h errors: {systemHealth.errors24h}</p>
        </div>
      </div>
    </div>
  );
}

function SettingsPanel({
  useMockData,
  toggleDataSource,
  autoRefreshEnabled,
  setAutoRefreshEnabled,
  refreshEverySec,
  setRefreshEverySec,
}: {
  useMockData: boolean;
  toggleDataSource: () => void;
  autoRefreshEnabled: boolean;
  setAutoRefreshEnabled: (value: boolean) => void;
  refreshEverySec: number;
  setRefreshEverySec: (value: number) => void;
}) {
  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-white/10 bg-black/20 p-4">
        <p className="text-sm font-semibold text-white">Data Source</p>
        <p className="mt-1 text-xs text-white/45">Switch between mock and connected data.</p>
        <button
          onClick={toggleDataSource}
          className="mt-3 inline-flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm font-semibold text-white/80 hover:bg-white/10"
        >
          <PlugZap className="h-4 w-4" />
          {useMockData ? 'Demo' : 'Live'}
        </button>
      </div>

      <div className="rounded-xl border border-white/10 bg-black/20 p-4">
        <p className="text-sm font-semibold text-white">Auto Refresh</p>
        <div className="mt-3 flex items-center gap-2">
          <button
            onClick={() => setAutoRefreshEnabled(!autoRefreshEnabled)}
            className={`rounded-lg px-3 py-2 text-sm font-semibold ${autoRefreshEnabled ? 'bg-emerald-500 text-white' : 'bg-white/10 text-white/70'}`}
          >
            {autoRefreshEnabled ? 'Enabled' : 'Disabled'}
          </button>
          <input
            type="number"
            min={10}
            max={180}
            value={refreshEverySec}
            onChange={(e) => setRefreshEverySec(Number(e.target.value))}
            className="w-24 rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-white outline-none"
          />
          <span className="text-xs text-white/45">seconds</span>
        </div>
      </div>
    </div>
  );
}
