'use client';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer, PieChart, Pie, Cell,
} from 'recharts';
import { BCRGauge } from '@/components/BCRGauge';
import { MetricCard } from '@/components/ui';
import { PLAN_CONFIG, WEEKLY_HISTORY } from '@/lib/constants';
import { fmt, bcrColor } from '@/lib/utils';

interface Props {
  pool: { weeklyPool: number; bcr: number; activePolicies: number; reserve: number; circuitBreakerTripped: boolean } | null;
  loading: boolean;
}

const PLAN_DIST = [
  { name: 'Basic',    value: 30, color: '#3FFF8B66' },
  { name: 'Standard', value: 50, color: '#3FFF8B' },
  { name: 'Full',     value: 20, color: '#3FFF8BCC' },
];

const PLAN_ROWS = [
  { key: 'basic' as const,    pct: 30, workers: 3000 },
  { key: 'standard' as const, pct: 50, workers: 5000 },
  { key: 'full' as const,     pct: 20, workers: 2000 },
];

export default function PoolHealth({ pool, loading }: Props) {
  const bcr     = pool?.bcr ?? 58.3;
  const weekly  = pool?.weeklyPool ?? 490000;
  const active  = pool?.activePolicies ?? 8420;
  const reserve = pool?.reserve ?? 940000;
  const tripped = pool?.circuitBreakerTripped ?? false;

  return (
    <div className="space-y-6">
      {/* Metric row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard label="Weekly Pool" value={fmt(weekly)} sub={`${active.toLocaleString('en-IN')} active policies`} loading={loading} />
        <MetricCard label="Current BCR" value={`${bcr.toFixed(1)}%`} sub="85% = circuit breaker threshold" color={bcrColor(bcr)} loading={loading} />
        <MetricCard label="Active Policies" value={active.toLocaleString('en-IN')} sub="Across 6 Chennai zones" loading={loading} />
        <MetricCard label="Reserve Fund" value={fmt(reserve)} sub="2× weekly pool maintained" color="#2196F3" loading={loading} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* BCR Gauge */}
        <div className="card p-6 flex flex-col items-center gap-4">
          <p className="text-xs font-bold tracking-widest uppercase self-start" style={{ color: '#91938D' }}>BCR GAUGE</p>
          <BCRGauge bcr={bcr} />
          <div className={`flex items-center gap-2 px-4 py-2 rounded-full border text-xs font-black ${
            tripped
              ? 'border-red-500/40 bg-red-500/10 text-red-400'
              : 'border-emerald-500/40 bg-emerald-500/10 text-emerald-400'
          }`}>
            <span className={`w-2 h-2 rounded-full ${tripped ? 'bg-red-400 pulse-red' : 'bg-emerald-400 pulse-green'}`} />
            CIRCUIT BREAKER {tripped ? 'OPEN — HALTED' : 'CLOSED — OPEN'}
          </div>
        </div>

        {/* Bar chart */}
        <div className="card p-6 lg:col-span-2">
          <p className="text-xs font-bold tracking-widest uppercase mb-4" style={{ color: '#91938D' }}>
            WEEKLY PREMIUMS vs CLAIMS (8 WEEKS)
          </p>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={WEEKLY_HISTORY} barGap={4}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="week" tick={{ fill: '#91938D', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#91938D', fontSize: 10 }} axisLine={false} tickLine={false}
                tickFormatter={v => `₹${(v / 1000).toFixed(0)}K`} />
              <Tooltip
                contentStyle={{ background: '#111311', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8 }}
                labelStyle={{ color: '#E1E3DE' }}
                formatter={(v: number) => [fmt(v)]}
              />
              <Legend wrapperStyle={{ fontSize: 12, color: '#91938D' }} />
              <Bar dataKey="premiums" name="Premiums" fill="#3FFF8B" radius={[4,4,0,0]} />
              <Bar dataKey="claims"   name="Claims"   fill="#E24B4A88" radius={[4,4,0,0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Plan distribution */}
      <div className="card p-6">
        <p className="text-xs font-bold tracking-widest uppercase mb-6" style={{ color: '#91938D' }}>PLAN DISTRIBUTION</p>
        <div className="flex flex-col lg:flex-row items-center gap-8">
          <PieChart width={200} height={200}>
            <Pie data={PLAN_DIST} cx={100} cy={100} innerRadius={55} outerRadius={90} paddingAngle={3} dataKey="value">
              {PLAN_DIST.map((e, i) => <Cell key={i} fill={e.color} />)}
            </Pie>
            <Tooltip
              contentStyle={{ background: '#111311', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8 }}
              formatter={(v: number) => [`${v}%`]}
            />
          </PieChart>

          <div className="flex-1 w-full space-y-4">
            {PLAN_ROWS.map(row => {
              const cfg = PLAN_CONFIG[row.key];
              return (
                <div key={row.key} className="card-sm p-4">
                  <div className="flex items-center justify-between mb-3">
                    <span className="font-bold text-sm">{cfg.name}</span>
                    <div className="flex gap-2">
                      <span className="badge-green">₹{cfg.base}/wk</span>
                      <span className="badge-blue">Cap ₹{cfg.max_payout}</span>
                      <span className="badge-amber">{cfg.multiplier}×</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="flex-1 bg-white/5 rounded-full h-2">
                      <div className="h-full rounded-full" style={{ width: `${row.pct}%`, background: '#3FFF8B' }} />
                    </div>
                    <span className="text-sm font-black w-10 text-right" style={{ color: '#3FFF8B' }}>{row.pct}%</span>
                    <span className="text-xs w-28" style={{ color: 'rgba(255,255,255,0.35)' }}>{row.workers.toLocaleString('en-IN')} workers</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
