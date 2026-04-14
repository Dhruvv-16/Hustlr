import { motion } from 'framer-motion'
import { Search, Download, AlertCircle, CheckCircle2, XCircle } from 'lucide-react'
import { useState, useEffect } from 'react'
import * as XLSX from 'xlsx'
import Badge from '../../components/ui/Badge'
import { getAdminClaims, approveClaim, rejectClaim } from '../../services/api'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const TRIGGER_ICONS = {
  FLOOD: '🌊',
  OUTAGE: '🔌',
  CURFEW: '🚫',
  AQI: '💨',
  FESTIVAL: '🎊',
  UNKNOWN: '⚠️'
}

export default function ClaimsQueue() {
  const [claims, setClaims] = useState([])
  const [statusFilter, setStatusFilter] = useState('ALL')
  const [triggerFilter, setTriggerFilter] = useState('ALL')
  const [tierFilter, setTierFilter] = useState('ALL')
  const [searchQuery, setSearchQuery] = useState('')
  const [loading, setLoading] = useState(true)

  const fetchClaims = async () => {
    setLoading(true)
    try {
      const res = await getAdminClaims({
        status: statusFilter,
        trigger_type: triggerFilter,
        tier: tierFilter,
        limit: 100
      })
      setClaims(res?.claims || [])
    } catch {
      setClaims([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchClaims()
  }, [statusFilter, triggerFilter, tierFilter])

  const handleApprove = async (claimId) => {
    await approveClaim(claimId)
    fetchClaims()
  }

  const handleReject = async (claimId) => {
    const reason = prompt("Enter rejection reason:", "Manual review — does not meet criteria")
    if (reason !== null) {
      await rejectClaim(claimId, reason)
      fetchClaims()
    }
  }

  const exportToExcel = () => {
    const rows = claims.map((claim) => ({
      'Claim ID': claim.id || claim._id,
      Worker: claim.worker_name || claim.worker?.name || 'Unknown',
      City: claim.worker_city || claim.worker?.city || '',
      'Trigger Type': claim.trigger_type || '',
      'Amount (Rs)': claim.amount || 0,
      'Tier': claim.payout_tier || '',
      Status: claim.status || '',
      'Fraud Score': claim.fraud_score?.toFixed?.(3) || '0.000',
      'Fraud Risk': claim.fraud_risk_label || '',
      'Created At': claim.created_at || '',
    }))
    const ws = XLSX.utils.json_to_sheet(rows)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Claims')
    XLSX.writeFile(wb, `Claims_${statusFilter}_${new Date().toISOString().slice(0, 10)}.xlsx`)
  }

  const filteredClaims = claims.filter(c => {
    const searchLow = searchQuery.toLowerCase()
    return (
      (c.worker_name || c.worker?.name || '').toLowerCase().includes(searchLow) ||
      (c._id || '').toLowerCase().includes(searchLow)
    )
  })

  return (
    <motion.div className="min-h-screen bg-grey-50 pb-8" variants={pageVariants} initial="initial" animate="animate" exit="exit">
      <div className="px-4 mt-3">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-[17px] font-bold font-display text-[#0F0F0F]">Claims Queue</h2>
          <button onClick={exportToExcel} className="flex items-center gap-2 px-3 py-2 rounded-[8px] bg-[#0F0F0F] text-white text-[12px] font-semibold font-body">
            <Download size={13} />
            Export
          </button>
        </div>

        <div className="flex items-center gap-3 px-4 h-[48px] rounded-input border-[1.5px] border-grey-200 bg-white mb-3">
          <Search size={16} className="text-grey-400 flex-shrink-0" />
          <input 
            type="text" 
            placeholder="Search worker or claim ID..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="flex-1 text-[14px] font-body text-[#0F0F0F] placeholder:text-grey-300 outline-none bg-transparent" 
          />
        </div>

        <div className="flex flex-wrap gap-2 mb-4 bg-white p-3 rounded-card shadow-card">
          <div className="flex flex-col">
            <label className="text-[11px] font-bold text-grey-500 uppercase mb-1">Status</label>
            <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-grey-50 border border-grey-200 rounded-[8px] p-2 text-[13px] font-body outline-none cursor-pointer text-[#0F0F0F]">
              <option value="ALL">All Statuses</option>
              <option value="PENDING">Pending</option>
              <option value="AUTO_APPROVED">Auto Approved</option>
              <option value="MANUAL_REVIEW">Manual Review</option>
              <option value="PAID">Paid</option>
              <option value="APPROVED">Approved (Pending Payout)</option>
              <option value="REJECTED">Rejected</option>
            </select>
          </div>
          <div className="flex flex-col">
            <label className="text-[11px] font-bold text-grey-500 uppercase mb-1">Trigger</label>
            <select value={triggerFilter} onChange={(e) => setTriggerFilter(e.target.value)} className="bg-grey-50 border border-grey-200 rounded-[8px] p-2 text-[13px] font-body outline-none cursor-pointer text-[#0F0F0F]">
              <option value="ALL">All Events</option>
              <option value="FLOOD">🌊 Flood</option>
              <option value="OUTAGE">🔌 Outage</option>
              <option value="CURFEW">🚫 Curfew</option>
              <option value="AQI">💨 AQI</option>
              <option value="FESTIVAL">🎊 Festival</option>
            </select>
          </div>
          <div className="flex flex-col">
            <label className="text-[11px] font-bold text-grey-500 uppercase mb-1">Tier</label>
            <select value={tierFilter} onChange={(e) => setTierFilter(e.target.value)} className="bg-grey-50 border border-grey-200 rounded-[8px] p-2 text-[13px] font-body outline-none cursor-pointer text-[#0F0F0F]">
              <option value="ALL">All Tiers</option>
              <option value="Gold">Gold</option>
              <option value="Silver">Silver</option>
              <option value="Bronze">Bronze</option>
            </select>
          </div>
        </div>

        <div className="bg-white rounded-card shadow-card overflow-hidden">
          {loading ? (
            <div className="px-4 py-8 text-center">
              <p className="text-[14px] text-[#9B9B9B] font-body">Loading queue...</p>
            </div>
          ) : filteredClaims.map((claim, index) => (
            <div key={claim._id} className={`p-4 ${index < filteredClaims.length - 1 ? 'border-b border-grey-50' : ''} ${claim.status === 'MANUAL_REVIEW' ? 'bg-danger-light' : ''}`}>
              <div className="flex items-start justify-between">
                <div className="flex-1 min-w-0 mr-3">
                  <p className="text-[15px] font-semibold font-body text-[#0F0F0F]">
                    {claim.worker_name || claim.worker?.name || 'Worker'} 
                    <span className="text-[13px] font-normal text-[#6B6B6B] ml-1">({claim.worker_city || claim.worker?.city || 'Unknown city'})</span>
                  </p>
                  
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-[13px] font-medium bg-grey-100 px-2 py-0.5 rounded-[4px]">
                      {TRIGGER_ICONS[claim.trigger_type] || '⚠️'} {claim.trigger_type}
                    </span>
                    <span className="text-[13px] font-semibold text-[#0F0F0F]">₹{claim.amount}</span>
                    {claim.payout_tier && (
                      <Badge variant="info">{claim.payout_tier}</Badge>
                    )}
                  </div>

                  <div className="flex items-center gap-2 mt-2">
                    <span className={`text-[12px] font-bold px-2 py-0.5 rounded-full ${
                      claim.fraud_risk_color === 'red' ? 'text-[#F04438] bg-[#F04438]/10' :
                      claim.fraud_risk_color === 'yellow' ? 'text-[#F79009] bg-[#F79009]/10' :
                      'text-[#12B76A] bg-[#12B76A]/10'
                    }`}>
                      {claim.fraud_risk_label || 'Unknown Risk'} (Score: {claim.fraud_score?.toFixed(2) || '0.00'})
                    </span>
                  </div>
                </div>
                
                <div className="text-right flex-shrink-0 flex flex-col items-end gap-1">
                  <Badge variant={
                    claim.status === 'AUTO_APPROVED' || claim.status === 'PAID' || claim.status === 'APPROVED' ? 'success' : 
                    claim.status === 'MANUAL_REVIEW' || claim.status === 'REJECTED' ? 'danger' : 'info'
                  }>
                    {claim.status === 'AUTO_APPROVED' ? 'Auto Approved' : 
                     claim.status === 'PAID' ? 'Paid' : 
                     claim.status === 'APPROVED' ? 'Approved' :
                     claim.status === 'MANUAL_REVIEW' ? 'Review' : 
                     claim.status === 'REJECTED' ? 'Rejected' :
                     claim.status}
                  </Badge>
                  <p className="text-[11px] text-[#9B9B9B] font-body mt-1">ID: {claim._id?.slice(0, 8)}</p>
                </div>
              </div>

              {claim.status === 'MANUAL_REVIEW' && (
                <div className="flex gap-2 mt-4 pt-3 border-t border-grey-100">
                  <button onClick={() => handleApprove(claim._id)} className="flex-1 h-9 flex items-center justify-center gap-1.5 bg-success text-white text-[13px] font-semibold font-body rounded-button">
                    <CheckCircle2 size={16} /> Approve
                  </button>
                  <button onClick={() => handleReject(claim._id)} className="flex-1 h-9 flex items-center justify-center gap-1.5 bg-danger text-white text-[13px] font-semibold font-body rounded-button">
                    <XCircle size={16} /> Reject
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>

        {!loading && filteredClaims.length === 0 && (
          <div className="text-center py-12">
            <p className="text-[15px] text-[#6B6B6B] font-body flex flex-col items-center gap-2">
              <AlertCircle size={24} className="text-grey-300" />
              No claims match your filters
            </p>
          </div>
        )}
      </div>
    </motion.div>
  )
}
