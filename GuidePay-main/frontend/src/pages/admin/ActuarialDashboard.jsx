import { useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  CartesianGrid,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'

import {
  getActuarialExposure,
  getActuarialReserve,
  getActuarialSummary,
  simulateActuarialScenario,
} from '../../services/api'
import { formatINRShort } from '../../utils/formatters'

const LOSS_COLORS = {
  good: '#12B76A',
  medium: '#F79009',
  high: '#F04438',
}

const DEFAULT_FORM = {
  city: 'Hyderabad',
  trigger_type: 'FLOOD',
  num_workers: 100,
  days: 7,
  payout_amount: 600,
  weekly_premium: 58,
}

const gaugeMeta = (lossRatio = 0) => {
  if (lossRatio < 0.65) return { label: 'Healthy', color: LOSS_COLORS.good }
  if (lossRatio <= 0.85) return { label: 'Watchlist', color: LOSS_COLORS.medium }
  return { label: 'Stress', color: LOSS_COLORS.high }
}

export default function ActuarialDashboard() {
  const [summary, setSummary] = useState(null)
  const [reserve, setReserve] = useState(null)
  const [exposure, setExposure] = useState([])
  const [scenario, setScenario] = useState(null)
  const [form, setForm] = useState(DEFAULT_FORM)
  const [loading, setLoading] = useState(true)
  const [simulating, setSimulating] = useState(false)

  const load = async () => {
    setLoading(true)
    try {
      const [summaryRes, reserveRes, exposureRes] = await Promise.all([
        getActuarialSummary(),
        getActuarialReserve(),
        getActuarialExposure(),
      ])
      setSummary(summaryRes)
      setReserve(reserveRes)
      setExposure(exposureRes?.cities || [])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  useEffect(() => {
    handleSimulate()
  }, [])

  const handleSimulate = async () => {
    setSimulating(true)
    try {
      const res = await simulateActuarialScenario(form)
      setScenario(res)
    } finally {
      setSimulating(false)
    }
  }

  const ratio = summary?.loss_ratio || 0
  const gauge = gaugeMeta(ratio)
  const gaugePercent = Math.min(Math.round(ratio * 100), 100)
  const trend = summary?.trend || []

  const cityExposureChart = useMemo(
    () => exposure.map((city) => ({
      city: city.city,
      exposure: Math.round(city.total_exposure || 0),
      workers: city.workers || 0,
    })),
    [exposure]
  )

  const kpis = [
    { label: 'Total Premium Collected', value: formatINRShort(summary?.total_premiums || 0), sub: 'Lifetime written premium', color: '#D97757' },
    { label: 'Total Payouts', value: formatINRShort(summary?.total_payouts || 0), sub: 'Paid claims only', color: '#2E90FA' },
    { label: 'Loss Ratio', value: `${Math.round((summary?.loss_ratio || 0) * 100)}%`, sub: gauge.label, color: gauge.color },
    { label: 'Active Exposure', value: formatINRShort(summary?.active_exposure || 0), sub: 'Live event-linked exposure', color: '#7A5AF8' },
  ]

  return (
    <motion.div className="min-h-screen bg-grey-50 pb-8" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }}>
      <div className="px-4 pt-4 flex flex-col gap-4">
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
          {kpis.map((kpi) => (
            <div key={kpi.label} className="bg-white rounded-card shadow-card p-4">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">{kpi.label}</p>
              <p className="font-display font-bold text-[28px] mt-1 leading-tight" style={{ color: kpi.color }}>
                {loading ? '...' : kpi.value}
              </p>
              <p className="text-[12px] text-[#6B6B6B] font-body mt-0.5">{kpi.sub}</p>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-[1.1fr_1fr] gap-4">
          <div className="bg-white rounded-card shadow-card p-4">
            <div className="flex items-center justify-between mb-3">
              <p className="text-[15px] font-semibold font-body text-[#0F0F0F]">Loss Ratio Gauge</p>
              <span className="text-[12px] font-semibold font-body" style={{ color: gauge.color }}>{gauge.label}</span>
            </div>
            <div className="flex items-center gap-6">
              <div style={{ position: 'relative', width: 148, height: 148 }}>
                <svg width="148" height="148" viewBox="0 0 148 148">
                  <circle cx="74" cy="74" r="60" fill="none" stroke="#F2F4F7" strokeWidth="12" />
                  <circle
                    cx="74"
                    cy="74"
                    r="60"
                    fill="none"
                    stroke={gauge.color}
                    strokeWidth="12"
                    strokeLinecap="round"
                    strokeDasharray={377}
                    strokeDashoffset={377 - (377 * gaugePercent / 100)}
                    transform="rotate(-90 74 74)"
                  />
                </svg>
                <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                  <span className="font-display text-[34px] font-bold text-[#0F0F0F]">{gaugePercent}%</span>
                  <span className="text-[11px] font-body text-[#98A2B3]">Loss Ratio</span>
                </div>
              </div>
              <div className="flex-1 flex flex-col gap-2">
                <div className="rounded-[12px] p-3" style={{ background: '#ECFDF3' }}>
                  <p className="text-[12px] font-semibold font-body text-[#027A48]">Green zone</p>
                  <p className="text-[12px] font-body text-[#027A48] mt-1">Below 65% loss ratio. Sustainable weekly book.</p>
                </div>
                <div className="rounded-[12px] p-3" style={{ background: '#FFFAEB' }}>
                  <p className="text-[12px] font-semibold font-body text-[#B54708]">Yellow zone</p>
                  <p className="text-[12px] font-body text-[#B54708] mt-1">65%–85%. Watch reserves and trigger clustering.</p>
                </div>
                <div className="rounded-[12px] p-3" style={{ background: '#FEF3F2' }}>
                  <p className="text-[12px] font-semibold font-body text-[#B42318]">Red zone</p>
                  <p className="text-[12px] font-body text-[#B42318] mt-1">Above 85%. Reprice, cap exposure, or inject reserve.</p>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-card shadow-card p-4">
            <div className="flex items-center justify-between mb-3">
              <p className="text-[15px] font-semibold font-body text-[#0F0F0F]">Scenario Simulator</p>
              <button onClick={handleSimulate} className="px-3 py-2 rounded-[10px] bg-[#0F0F0F] text-white text-[12px] font-semibold font-body">
                {simulating ? 'Running...' : 'Run Scenario'}
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4">
              <select value={form.city} onChange={(e) => setForm((prev) => ({ ...prev, city: e.target.value }))} className="h-11 rounded-[10px] border border-grey-200 px-3 text-[13px] font-body">
                {['Hyderabad', 'Mumbai', 'Chennai', 'Bengaluru', 'Delhi'].map((city) => <option key={city}>{city}</option>)}
              </select>
              <select value={form.trigger_type} onChange={(e) => setForm((prev) => ({ ...prev, trigger_type: e.target.value }))} className="h-11 rounded-[10px] border border-grey-200 px-3 text-[13px] font-body">
                {['FLOOD', 'OUTAGE', 'CURFEW', 'AIR_QUALITY', 'FESTIVAL_DISRUPTION'].map((trigger) => <option key={trigger}>{trigger}</option>)}
              </select>
            </div>

            <div className="flex flex-col gap-3 mb-4">
              <label className="text-[12px] font-semibold font-body text-[#344054]">Workers: {form.num_workers}</label>
              <input type="range" min="10" max="500" step="10" value={form.num_workers} onChange={(e) => setForm((prev) => ({ ...prev, num_workers: Number(e.target.value) }))} />
              <label className="text-[12px] font-semibold font-body text-[#344054]">Days: {form.days}</label>
              <input type="range" min="1" max="14" step="1" value={form.days} onChange={(e) => setForm((prev) => ({ ...prev, days: Number(e.target.value) }))} />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="rounded-[12px] bg-[#F8FAFC] p-3">
                <p className="text-[11px] font-body text-[#98A2B3]">Premium Collected</p>
                <p className="font-display text-[24px] font-bold text-[#0F172A] mt-1">{formatINRShort(scenario?.premium_collected || 0)}</p>
              </div>
              <div className="rounded-[12px] bg-[#F8FAFC] p-3">
                <p className="text-[11px] font-body text-[#98A2B3]">Payout Expected</p>
                <p className="font-display text-[24px] font-bold text-[#0F172A] mt-1">{formatINRShort(scenario?.payout_expected || 0)}</p>
              </div>
              <div className="rounded-[12px] bg-[#F8FAFC] p-3">
                <p className="text-[11px] font-body text-[#98A2B3]">Loss Ratio</p>
                <p className="font-display text-[24px] font-bold text-[#0F172A] mt-1">{Math.round((scenario?.loss_ratio || 0) * 100)}%</p>
              </div>
              <div className="rounded-[12px] bg-[#F8FAFC] p-3">
                <p className="text-[11px] font-body text-[#98A2B3]">Risk Level</p>
                <span className="inline-flex mt-2 px-3 py-1 rounded-pill text-[12px] font-semibold font-body" style={{ background: `${gaugeMeta(scenario?.loss_ratio || 0).color}15`, color: gaugeMeta(scenario?.loss_ratio || 0).color }}>
                  {scenario?.risk_level || 'LOW'}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
          <div className="bg-white rounded-card shadow-card p-4">
            <p className="text-[15px] font-semibold font-body text-[#0F0F0F] mb-4">Premium vs Payout Trend</p>
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={trend}>
                <defs>
                  <linearGradient id="premiumFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#D97757" stopOpacity={0.24} />
                    <stop offset="95%" stopColor="#D97757" stopOpacity={0.02} />
                  </linearGradient>
                  <linearGradient id="payoutFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2E90FA" stopOpacity={0.24} />
                    <stop offset="95%" stopColor="#2E90FA" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#F2F4F7" vertical={false} />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area dataKey="premiums" stroke="#D97757" fill="url(#premiumFill)" strokeWidth={2} />
                <Area dataKey="payouts" stroke="#2E90FA" fill="url(#payoutFill)" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          <div className="bg-white rounded-card shadow-card p-4">
            <p className="text-[15px] font-semibold font-body text-[#0F0F0F] mb-4">City Exposure</p>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={cityExposureChart}>
                <CartesianGrid stroke="#F2F4F7" vertical={false} />
                <XAxis dataKey="city" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="exposure" fill="#7A5AF8" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
          <div className="bg-white rounded-card shadow-card p-4">
            <p className="text-[12px] font-semibold font-body text-[#475467]">Required Reserve</p>
            <p className="font-display text-[28px] font-bold text-[#0F172A] mt-1">{formatINRShort(reserve?.reserve_required || 0)}</p>
          </div>
          <div className="bg-white rounded-card shadow-card p-4">
            <p className="text-[12px] font-semibold font-body text-[#475467]">Current Buffer</p>
            <p className="font-display text-[28px] font-bold text-[#0F172A] mt-1">{formatINRShort(reserve?.current_buffer || 0)}</p>
          </div>
          <div className="bg-white rounded-card shadow-card p-4">
            <p className="text-[12px] font-semibold font-body text-[#475467]">Reserve Gap</p>
            <p className="font-display text-[28px] font-bold mt-1" style={{ color: (reserve?.reserve_gap || 0) > 0 ? '#F04438' : '#12B76A' }}>
              {formatINRShort(reserve?.reserve_gap || 0)}
            </p>
          </div>
        </div>
      </div>
    </motion.div>
  )
}
