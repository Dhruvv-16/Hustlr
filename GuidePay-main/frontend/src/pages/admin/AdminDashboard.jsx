import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import Badge from '../../components/ui/Badge'
import { getAdminDashboardStats, getZoneRiskMonitor, simulateTrigger } from '../../services/api'
import { formatINRShort } from '../../utils/formatters'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

export default function AdminDashboard() {
  const [stats, setStats] = useState(null)
  const [zoneRisk, setZoneRisk] = useState(null)
  const [loading, setLoading] = useState(true)
  
  const [simCity, setSimCity] = useState('Hyderabad')
  const [simType, setSimType] = useState('FLOOD')
  const [simulating, setSimulating] = useState(false)
  const [simResult, setSimResult] = useState(null)

  useEffect(() => {
    const loadDashboard = async () => {
      try {
        const statsData = await getAdminDashboardStats()
        setStats(statsData)
        
        const zoneData = await getZoneRiskMonitor()
        setZoneRisk(zoneData)
      } catch (err) {
        console.error("Error loading dashboard", err)
      } finally {
        setLoading(false)
      }
    }
    loadDashboard()
  }, [])

  const handleSimulate = async () => {
    setSimulating(true)
    setSimResult(null)
    try {
      const result = await simulateTrigger(simCity, simType)
      setSimResult({
        success: true,
        message: result?.message || `${simType} trigger fired in ${simCity}`,
      })
      const statsData = await getAdminDashboardStats().catch(() => null)
      if (statsData) setStats(statsData)
      const zoneData = await getZoneRiskMonitor().catch(() => null)
      if (zoneData) setZoneRisk(zoneData)
    } catch (error) {
      setSimResult({
        success: false,
        message: error?.detail || error?.message || 'Trigger simulation failed',
      })
    } finally {
      setSimulating(false)
      setTimeout(() => setSimResult(null), 5000)
    }
  }

  const { overview, financials, tier_breakdown, claims_by_trigger } = stats || {}
  
  return (
    <motion.div className="min-h-screen bg-grey-50 pb-8" variants={pageVariants} initial="initial" animate="animate" exit="exit">
      <div className="mt-3 flex flex-col gap-3">
      
        {/* KPI Grid */}
        <div className="px-4">
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            {/* Row 1 */}
            <div className="bg-white rounded-card shadow-card p-3.5">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">Active Policies</p>
              <p className="font-display font-bold text-[24px] mt-1 text-[#2E90FA] leading-tight">{loading ? '...' : overview?.active_policies}</p>
            </div>
            <div className="bg-white rounded-card shadow-card p-3.5">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">Claims Today</p>
              <p className="font-display font-bold text-[24px] mt-1 text-[#F79009] leading-tight">{loading ? '...' : overview?.claims_today}</p>
            </div>
            <div className="bg-white rounded-card shadow-card p-3.5 md:col-span-1 col-span-2">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">Pending Review</p>
              <p className={`font-display font-bold text-[24px] mt-1 leading-tight ${overview?.pending_manual_review > 0 ? 'text-[#F04438]' : 'text-[#12B76A]'}`}>
                {loading ? '...' : overview?.pending_manual_review}
              </p>
            </div>
            
            {/* Row 2 */}
            <div className="bg-white rounded-card shadow-card p-3.5">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">Monthly Premium</p>
              <p className="font-display font-bold text-[24px] mt-1 text-[#12B76A] leading-tight">
                {loading ? '...' : `₹${financials?.monthly_premium_collected?.toLocaleString('en-IN')}`}
              </p>
            </div>
            <div className="bg-white rounded-card shadow-card p-3.5">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">Monthly Payouts</p>
              <p className="font-display font-bold text-[24px] mt-1 text-[#F79009] leading-tight">
                {loading ? '...' : `₹${financials?.monthly_payouts?.toLocaleString('en-IN')}`}
              </p>
            </div>
            <div className="bg-white rounded-card shadow-card p-3.5 md:col-span-1 col-span-2">
              <p className="text-[11px] font-medium font-body text-[#9B9B9B] uppercase tracking-[1px]">Loss Ratio</p>
              <p className={`font-display font-bold text-[24px] mt-1 leading-tight ${financials?.loss_ratio > 65 ? 'text-[#F04438]' : 'text-[#12B76A]'}`}>
                {loading ? '...' : (
                  <>
                    {financials?.loss_ratio}%
                    {stats?.data_mode === 'demo' && (
                      <span className="ml-2 text-[10px] bg-[#F2F4F7] text-[#344054] px-1.5 py-0.5 rounded-sm border border-[#D0D5DD] tracking-wide relative -top-1">DEMO DATA</span>
                    )}
                  </>
                )}
              </p>
            </div>
          </div>
        </div>

        {/* Tier Breakdown */}
        <div className="px-4">
          <div className="flex gap-2 overflow-x-auto pb-1 mt-1">
            <div className="flex-shrink-0 bg-white rounded-card shadow-card px-4 py-3 min-w-[130px]">
              <p className="text-[13px] font-medium font-body text-[#0F0F0F] flex items-center gap-1.5">🥇 Gold Workers</p>
              <p className="font-display font-bold text-[20px] mt-1 text-[#0F0F0F]">{loading ? '...' : tier_breakdown?.gold}</p>
            </div>
            <div className="flex-shrink-0 bg-white rounded-card shadow-card px-4 py-3 min-w-[130px]">
              <p className="text-[13px] font-medium font-body text-[#0F0F0F] flex items-center gap-1.5">🥈 Silver Workers</p>
              <p className="font-display font-bold text-[20px] mt-1 text-[#0F0F0F]">{loading ? '...' : tier_breakdown?.silver}</p>
            </div>
            <div className="flex-shrink-0 bg-white rounded-card shadow-card px-4 py-3 min-w-[130px]">
              <p className="text-[13px] font-medium font-body text-[#0F0F0F] flex items-center gap-1.5">🥉 Bronze Workers</p>
              <p className="font-display font-bold text-[20px] mt-1 text-[#0F0F0F]">{loading ? '...' : tier_breakdown?.bronze}</p>
            </div>
          </div>
        </div>

        {/* Simulator */}
        <div style={{ margin: '8px 16px', background: '#1A1A1A', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 14, padding: 20 }}>
          <div style={{ marginBottom: 12 }}>
            <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: 700, color: 'white', margin: '0 0 3px' }}>Simulation Tools</p>
            <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'rgba(255,255,255,0.4)', margin: 0 }}>
              Trigger an anomalous event manually to test ML fraud hooks and the claims queue auto-fill logic.
            </p>
          </div>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
            <select value={simCity} onChange={(e) => setSimCity(e.target.value)} style={{ background: '#111', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, padding: '8px 12px', color: 'white', fontSize: 13, fontFamily: 'Inter', outline: 'none', cursor: 'pointer' }}>
              {['Hyderabad', 'Mumbai', 'Chennai', 'Bengaluru', 'Delhi'].map((city) => <option key={city} value={city}>{city}</option>)}
            </select>
            <select value={simType} onChange={(e) => setSimType(e.target.value)} style={{ background: '#111', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, padding: '8px 12px', color: 'white', fontSize: 13, fontFamily: 'Inter', outline: 'none', cursor: 'pointer' }}>
              <option value="FLOOD">Flood Alert</option>
              <option value="OUTAGE">Platform Outage</option>
              <option value="CURFEW">Government Curfew</option>
            </select>
            <motion.button onClick={handleSimulate} disabled={simulating} whileTap={{ scale: 0.97 }} style={{ padding: '9px 20px', borderRadius: 8, border: 'none', background: simulating ? '#333' : '#D97757', color: simulating ? 'rgba(255,255,255,0.4)' : 'white', fontSize: 13, fontWeight: 700, fontFamily: 'Inter', cursor: simulating ? 'not-allowed' : 'pointer' }}>
              {simulating ? 'Simulating...' : 'Fire Trigger'}
            </motion.button>
            {simResult && (
              <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} style={{ background: simResult.success ? 'rgba(18,183,106,0.1)' : 'rgba(240,68,56,0.1)', border: simResult.success ? '1px solid rgba(18,183,106,0.25)' : '1px solid rgba(240,68,56,0.25)', borderRadius: 8, padding: '8px 12px', fontSize: 12, fontFamily: 'Inter', color: simResult.success ? '#12B76A' : '#F04438' }}>
                {simResult.message}
              </motion.div>
            )}
          </div>
        </div>

        {/* Zone Risk Monitor */}
        <div className="mx-4 bg-white rounded-card shadow-card overflow-hidden">
          <div className="px-4 py-3.5 border-b border-grey-100 flex flex-col sm:flex-row sm:justify-between sm:items-center">
            <span className="text-[14px] font-semibold font-body text-[#0F0F0F]">Zone Risk Monitor</span>
            {zoneRisk?.summary?.critical_zones > 0 && (
              <span className="text-[12px] font-semibold text-[#F04438] bg-danger-light px-2 py-1 rounded-md mt-2 sm:mt-0">
                ⚠️ {zoneRisk.summary.critical_zones} zones at critical risk · Total exposure: ₹{zoneRisk.summary.total_potential_exposure?.toLocaleString('en-IN')}
              </span>
            )}
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left" style={{ minWidth: 500 }}>
              <thead>
                <tr className="bg-grey-50 text-[11px] font-semibold text-[#6B6B6B] uppercase tracking-wide">
                  <th className="px-4 py-3 font-body">City</th>
                  <th className="px-4 py-3 font-body">Risk</th>
                  <th className="px-4 py-3 font-body">Active Policies</th>
                  <th className="px-4 py-3 font-body">Claims/Month</th>
                  <th className="px-4 py-3 font-body">Exposure</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-grey-50 text-[13px] font-body text-[#0F0F0F]">
                {(zoneRisk?.zones || []).map((zone) => (
                  <tr key={zone.city}>
                    <td className="px-4 py-3 font-semibold">{zone.city}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-1 text-[11px] font-bold rounded-md uppercase ${
                        zone.risk_color === 'red' ? 'bg-[#F04438] text-white' :
                        zone.risk_color === 'orange' ? 'bg-[#F79009] text-white' :
                        zone.risk_color === 'yellow' ? 'bg-[#FDB022] text-[#0F0F0F]' :
                        'bg-[#12B76A] text-white'
                      }`}>
                        {zone.risk_color === 'red' && '🔴'}
                        {zone.risk_color === 'orange' && '🟠'}
                        {zone.risk_color === 'yellow' && '🟡'}
                        {zone.risk_color === 'green' && '🟢'}
                        {' '}
                        {zone.risk_level}
                      </span>
                    </td>
                    <td className="px-4 py-3">{zone.active_policies}</td>
                    <td className="px-4 py-3">{zone.claims_this_month}</td>
                    <td className="px-4 py-3 font-semibold">₹{zone.potential_exposure_inr?.toLocaleString('en-IN')}</td>
                  </tr>
                ))}
                {!zoneRisk?.zones?.length && !loading && (
                  <tr>
                    <td colSpan="5" className="px-4 py-6 text-center text-[13px] text-[#9B9B9B]">No zones actively monitored.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Claims by Trigger */}
        <div className="mx-4 bg-white rounded-card shadow-card overflow-hidden">
          <div className="px-4 py-3.5 border-b border-grey-100">
            <span className="text-[14px] font-semibold font-body text-[#0F0F0F]">Claims by Trigger</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left" style={{ minWidth: 400 }}>
              <thead>
                <tr className="bg-grey-50 text-[11px] font-semibold text-[#6B6B6B] uppercase tracking-wide">
                  <th className="px-4 py-3 font-body">Trigger Type</th>
                  <th className="px-4 py-3 font-body">Count</th>
                  <th className="px-4 py-3 font-body text-right">Total Payout</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-grey-50 text-[13px] font-body text-[#0F0F0F]">
                {(claims_by_trigger || []).map((trigger) => (
                  <tr key={trigger._id}>
                    <td className="px-4 py-3 font-semibold">{trigger._id}</td>
                    <td className="px-4 py-3">{trigger.count}</td>
                    <td className="px-4 py-3 text-right font-semibold">₹{trigger.total_payout?.toLocaleString('en-IN')}</td>
                  </tr>
                ))}
                {!claims_by_trigger?.length && !loading && (
                  <tr>
                    <td colSpan="3" className="px-4 py-6 text-center text-[13px] text-[#9B9B9B]">No claims found this month.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </motion.div>
  )
}
