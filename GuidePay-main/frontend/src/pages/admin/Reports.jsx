import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Download, FileText, BarChart2, AlertTriangle, MapPin, Users, Zap } from 'lucide-react'
import { getAnalytics, getAdminStats, getClaimsQueue } from '../../services/api'
import * as XLSX from 'xlsx'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const REPORT_TYPES = [
  {
    id: 'claims_summary',
    label: 'Claims Summary',
    desc: 'All claims with status, amount, and fraud scores',
    icon: FileText,
    color: '#2E90FA',
    bg: '#EFF8FF',
  },
  {
    id: 'revenue_report',
    label: 'Revenue Report',
    desc: 'Daily premium collections and payouts',
    icon: BarChart2,
    color: '#D97757',
    bg: '#FDF1ED',
  },
  {
    id: 'fraud_analysis',
    label: 'Fraud Analysis',
    desc: 'Claims flagged by fraud detection system',
    icon: AlertTriangle,
    color: '#F04438',
    bg: '#FEF3F2',
  },
  {
    id: 'zone_risk',
    label: 'Zone Risk Report',
    desc: 'Risk levels and exposure by delivery zone',
    icon: MapPin,
    color: '#12B76A',
    bg: '#ECFDF3',
  },
  {
    id: 'worker_portfolio',
    label: 'Worker Portfolio',
    desc: 'Worker profiles, risk scores, and policies',
    icon: Users,
    color: '#7A5AF8',
    bg: '#F4F3FF',
  },
  {
    id: 'trigger_events',
    label: 'Trigger Events Log',
    desc: 'All trigger events with zone and severity data',
    icon: Zap,
    color: '#F79009',
    bg: '#FFFAEB',
  },
]

function exportToExcel(data, filename, sheetName = 'Report') {
  if (!data || data.length === 0) {
    alert('No data available to export.')
    return
  }
  const ws = XLSX.utils.json_to_sheet(data)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, sheetName)
  XLSX.writeFile(wb, `${filename}_${new Date().toISOString().slice(0, 10)}.xlsx`)
}

export default function Reports() {
  const navigate = useNavigate()
  const [stats, setStats] = useState(null)
  const [analytics, setAnalytics] = useState(null)
  const [claimsData, setClaimsData] = useState([])
  const [loadingReportId, setLoadingReportId] = useState(null)
  const [daysFilter, setDaysFilter] = useState(30)

  useEffect(() => {
    getAdminStats().then(setStats).catch(console.error)
    getAnalytics(daysFilter).then(setAnalytics).catch(console.error)
    getClaimsQueue('ALL').then(res => setClaimsData(res?.claims || [])).catch(console.error)
  }, [daysFilter])

  const generateReport = async (reportId) => {
    setLoadingReportId(reportId)
    try {
      switch (reportId) {
        case 'claims_summary': {
          const rows = claimsData.map(c => ({
            'Claim ID': c.id || c._id,
            'Worker Name': c.worker?.name || 'Unknown',
            'Worker Phone': c.worker?.phone || '',
            'City': c.worker?.city || '',
            'Trigger Type': c.trigger_type || '',
            'Amount (₹)': c.amount || 0,
            'Status': c.status || '',
            'Fraud Score': c.fraud_score?.toFixed(3) || '0.000',
            'Fraud Flags': (c.fraud_flags || []).join(', '),
            'Created At': c.created_at || '',
            'Paid At': c.paid_at || '',
          }))
          exportToExcel(rows, 'GuidePay_Claims_Summary', 'Claims')
          break
        }

        case 'revenue_report': {
          const revenueRows = (analytics?.daily_revenue || []).map(d => ({
            'Date': d._id,
            'Premiums Collected (₹)': d.amount || 0,
            'Payment Count': d.count || 0,
          }))
          const payoutRows = (analytics?.daily_payouts || []).map(d => ({
            'Date': d._id,
            'Payouts Sent (₹)': d.amount || 0,
            'Claims Paid': d.count || 0,
          }))
          // Merge by date
          const allDates = new Set([
            ...revenueRows.map(r => r.Date),
            ...payoutRows.map(r => r.Date),
          ])
          const merged = Array.from(allDates).sort().map(date => {
            const rev = revenueRows.find(r => r.Date === date) || {}
            const pay = payoutRows.find(r => r.Date === date) || {}
            return {
              'Date': date,
              'Premiums Collected (₹)': rev['Premiums Collected (₹)'] || 0,
              'Payouts Sent (₹)': pay['Payouts Sent (₹)'] || 0,
              'Net Revenue (₹)': (rev['Premiums Collected (₹)'] || 0) - (pay['Payouts Sent (₹)'] || 0),
              'Loss Ratio': rev['Premiums Collected (₹)'] > 0
                ? ((pay['Payouts Sent (₹)'] || 0) / rev['Premiums Collected (₹)']).toFixed(3)
                : '0.000',
            }
          })
          exportToExcel(merged, 'GuidePay_Revenue_Report', 'Revenue')
          break
        }

        case 'fraud_analysis': {
          const fraudClaims = claimsData
            .filter(c => (c.fraud_score || 0) >= 0.3 || c.status === 'MANUAL_REVIEW' || (c.fraud_flags || []).length > 0)
            .map(c => ({
              'Claim ID': c.id || c._id,
              'Worker': c.worker?.name || 'Unknown',
              'Amount (₹)': c.amount || 0,
              'Fraud Score': c.fraud_score?.toFixed(3) || '0.000',
              'Status': c.status || '',
              'Flags': (c.fraud_flags || []).join(', '),
              'Duplicate Check': c.fraud_checks?.duplicate?.result || '',
              'GPS Check': c.fraud_checks?.gps?.result || '',
              'Activity Check': c.fraud_checks?.activity?.result || '',
              'Frequency Check': c.fraud_checks?.frequency?.result || '',
              'Created At': c.created_at || '',
            }))
          exportToExcel(fraudClaims, 'GuidePay_Fraud_Analysis', 'Fraud')
          break
        }

        case 'zone_risk': {
          const zoneRows = (stats?.zone_exposure || []).map(z => ({
            'City': z._id || '',
            'Total Exposure (₹)': z.total_exposure || 0,
            'Workers Affected': z.workers || 0,
          }))
          exportToExcel(
            zoneRows.length > 0 ? zoneRows : [{ 'City': 'No active triggers', 'Total Exposure (₹)': 0, 'Workers Affected': 0 }],
            'GuidePay_Zone_Risk',
            'Zone Risk'
          )
          break
        }

        case 'worker_portfolio': {
          // Use claims data for worker info
          const workerMap = {}
          claimsData.forEach(c => {
            if (c.worker?.name) {
              const key = c.worker.name
              if (!workerMap[key]) {
                workerMap[key] = {
                  'Worker Name': c.worker.name,
                  'Phone': c.worker.phone || '',
                  'City': c.worker.city || '',
                  'Total Claims': 0,
                  'Total Payouts (₹)': 0,
                }
              }
              workerMap[key]['Total Claims']++
              workerMap[key]['Total Payouts (₹)'] += c.amount || 0
            }
          })
          exportToExcel(Object.values(workerMap), 'GuidePay_Worker_Portfolio', 'Workers')
          break
        }

        case 'trigger_events': {
          const triggerRows = (stats?.active_triggers || []).map(t => ({
            'Trigger ID': t.id || t._id || '',
            'City': t.city || '',
            'Zone': t.zone || '',
            'Type': t.trigger_type || '',
            'Severity': t.severity || '',
            'Status': t.status || '',
            'Affected Workers': t.affected_workers || 0,
            'Total Exposure (₹)': t.total_exposure || 0,
            'Started At': t.started_at || '',
            'Source': t.source || '',
          }))
          exportToExcel(
            triggerRows.length > 0 ? triggerRows : [{ 'Trigger ID': 'No active triggers', 'City': '', 'Type': '', 'Severity': '', 'Status': '' }],
            'GuidePay_Trigger_Events',
            'Triggers'
          )
          break
        }
      }
    } catch (e) {
      console.error('Export failed:', e)
      alert('Export failed. Please try again.')
    }
    setLoadingReportId(null)
  }

  const totalClaims = claimsData.length
  const totalRevenue = (analytics?.daily_revenue || []).reduce((s, d) => s + (d.amount || 0), 0)
  const totalPayouts = (analytics?.daily_payouts || []).reduce((s, d) => s + (d.amount || 0), 0)

  return (
    <motion.div
      className="min-h-screen pb-8"
      style={{ background: 'var(--bg-secondary)' }}
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #0A0A0A, #1A1A1A)',
        padding: '20px 20px 24px',
        borderBottom: '1px solid #2A2A2A',
      }}>
        <div style={{ maxWidth: 900, margin: '0 auto' }}>
          <p style={{ fontSize: 11, fontWeight: 700, color: '#6B6B6B', letterSpacing: '1.5px', textTransform: 'uppercase', fontFamily: 'Inter', margin: '0 0 6px' }}>
            ADMIN · SENTINELX
          </p>
          <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 26, fontWeight: 800, color: 'white', margin: '0 0 4px' }}>
            Reports & Exports
          </h1>
          <p style={{ fontSize: 13, color: '#9B9B9B', fontFamily: 'Inter', margin: 0 }}>
            Generate and download Excel reports for any data category
          </p>
        </div>
      </div>

      <div style={{ padding: '20px', maxWidth: 900, margin: '0 auto' }}>
        {/* Summary metrics */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 20 }}>
          {[
            { label: 'Total Claims', value: totalClaims },
            { label: 'Total Revenue', value: `₹${totalRevenue.toLocaleString('en-IN')}` },
            { label: 'Total Payouts', value: `₹${totalPayouts.toLocaleString('en-IN')}` },
          ].map(s => (
            <div key={s.label} style={{
              background: 'var(--bg-card)',
              borderRadius: 12, padding: '14px 16px',
              border: '1px solid var(--border-light)',
            }}>
              <p style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px', margin: '0 0 4px' }}>
                {s.label}
              </p>
              <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                {s.value}
              </p>
            </div>
          ))}
        </div>

        {/* Date range filter */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
          <span style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-secondary)', alignSelf: 'center' }}>Period:</span>
          {[7, 30, 90].map(d => (
            <button
              key={d}
              onClick={() => setDaysFilter(d)}
              style={{
                padding: '6px 14px', borderRadius: 999,
                border: `1px solid ${daysFilter === d ? 'var(--brand)' : 'var(--border-light)'}`,
                background: daysFilter === d ? 'var(--brand-light)' : 'var(--bg-card)',
                color: daysFilter === d ? 'var(--brand)' : 'var(--text-secondary)',
                fontSize: 12, fontWeight: 600, fontFamily: 'Inter',
                cursor: 'pointer',
              }}
            >
              {d}d
            </button>
          ))}
        </div>

        {/* Report cards */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: 12 }}>
          {REPORT_TYPES.map(report => {
            const Icon = report.icon
            const isLoading = loadingReportId === report.id
            return (
              <motion.div
                key={report.id}
                whileHover={{ y: -2 }}
                style={{
                  background: 'var(--bg-card)',
                  borderRadius: 14,
                  padding: 16,
                  border: '1px solid var(--border-light)',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                  <div style={{
                    width: 40, height: 40, borderRadius: 10,
                    background: report.bg,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0,
                  }}>
                    <Icon size={20} color={report.color} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 2px' }}>
                      {report.label}
                    </p>
                    <p style={{ fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter', lineHeight: 1.4, margin: 0 }}>
                      {report.desc}
                    </p>
                  </div>
                </div>
                <motion.button
                  onClick={() => generateReport(report.id)}
                  disabled={isLoading}
                  whileTap={{ scale: 0.97 }}
                  style={{
                    width: '100%', marginTop: 12,
                    padding: '9px 0',
                    borderRadius: 10, border: 'none',
                    background: isLoading ? 'var(--border-light)' : report.bg,
                    color: isLoading ? 'var(--text-tertiary)' : report.color,
                    fontSize: 13, fontWeight: 700, fontFamily: 'Inter',
                    cursor: isLoading ? 'default' : 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                  }}
                >
                  {isLoading ? (
                    <>
                      <div style={{
                        width: 14, height: 14,
                        border: `2px solid ${report.color}`,
                        borderTopColor: 'transparent',
                        borderRadius: 999,
                        animation: 'spin 0.8s linear infinite',
                      }} />
                      Generating...
                    </>
                  ) : (
                    <>
                      <Download size={14} />
                      Export Excel
                    </>
                  )}
                </motion.button>
              </motion.div>
            )
          })}
        </div>
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </motion.div>
  )
}
