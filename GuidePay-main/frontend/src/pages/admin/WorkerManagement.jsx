import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { getWorkers } from '../../services/api'
import { Search, ShieldAlert, BadgeCheck, FileDown } from 'lucide-react'
import { useTranslation } from '../../i18n/useTranslation'

const DEMO_WORKERS = [
  { _id: 'demo_1', name: 'Ravi Kumar',    phone: '9999900000', city: 'Hyderabad', zone: 'kondapur-hyderabad', risk_score: 0.92, risk_tier: 'LOW',    premium_amount: 58, has_active_policy: true,  is_active: true,  suspended: false, platforms: ['zepto','swiggy'],   total_claims: 3, created_at: new Date(Date.now()-45*86400000).toISOString() },
  { _id: 'demo_2', name: 'Arjun Sharma',  phone: '9876543210', city: 'Mumbai',    zone: 'kurla-mumbai',        risk_score: 0.74, risk_tier: 'LOW',    premium_amount: 67, has_active_policy: true,  is_active: true,  suspended: false, platforms: ['blinkit','zomato'], total_claims: 1, created_at: new Date(Date.now()-30*86400000).toISOString() },
  { _id: 'demo_3', name: 'Mohammed Ali',  phone: '9123456780', city: 'Chennai',   zone: 'tnagar-chennai',      risk_score: 0.45, risk_tier: 'MEDIUM', premium_amount: 63, has_active_policy: false, is_active: true,  suspended: false, platforms: ['swiggy'],           total_claims: 0, created_at: new Date(Date.now()-15*86400000).toISOString() },
  { _id: 'demo_4', name: 'Priya Patel',   phone: '9988776655', city: 'Bengaluru', zone: 'koramangala-bengaluru',risk_score: 0.88, risk_tier: 'LOW',    premium_amount: 43, has_active_policy: true,  is_active: true,  suspended: false, platforms: ['zepto','blinkit'],  total_claims: 2, created_at: new Date(Date.now()-60*86400000).toISOString() },
  { _id: 'demo_5', name: 'Sita Devi',     phone: '9012345678', city: 'Delhi',     zone: 'dwarka-delhi',        risk_score: 0.31, risk_tier: 'HIGH',   premium_amount: 52, has_active_policy: false, is_active: false, suspended: true,  platforms: ['amazon','swiggy'],  total_claims: 5, created_at: new Date(Date.now()-8*86400000).toISOString()  },
]

export default function WorkerManagement() {
  const [workers, setWorkers] = useState([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('ALL')
  const [usingDemo, setUsingDemo] = useState(false)
  const { t } = useTranslation()

  useEffect(() => {
    fetchWorkers()
  }, [statusFilter])

  const fetchWorkers = async () => {
    setLoading(true)
    try {
      const res = await getWorkers(statusFilter, search, 50, 0)
      const list = res.workers || []
      if (list.length === 0) {
        // Backend returned no workers — show demo data
        setWorkers(DEMO_WORKERS)
        setTotal(DEMO_WORKERS.length)
        setUsingDemo(true)
      } else {
        setWorkers(list)
        setTotal(res.total || list.length)
        setUsingDemo(false)
      }
    } catch (e) {
      console.error(e)
      setWorkers(DEMO_WORKERS)
      setTotal(DEMO_WORKERS.length)
      setUsingDemo(true)
    }
    setLoading(false)
  }

  const exportToCSV = () => {
    const headers = ['Name', 'Phone', 'City', 'Risk Score', 'Status']
    const csvContent = "data:text/csv;charset=utf-8," 
      + headers.join(",") + "\n"
      + workers.map(w => `${w.name},${w.phone},${w.city},${w.risk_score || 'N/A'},${w.is_active ? 'ACTIVE' : 'INACTIVE'}`).join("\n")
    
    const encodedUri = encodeURI(csvContent)
    const link = document.createElement("a")
    link.setAttribute("href", encodedUri)
    link.setAttribute("download", "workers_export.csv")
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const handleSuspend = async (workerId, suspend) => {
    try {
      const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')
      await fetch(
        `${import.meta.env.VITE_API_URL || 'http://localhost:8000'}/api/v1/admin/workers/${workerId}/suspend`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ suspended: suspend }),
        }
      )
      setWorkers(prev => prev.map(w =>
        (w.id === workerId || w._id === workerId)
          ? { ...w, is_active: !suspend, suspended: suspend }
          : w
      ))
    } catch (e) {
      console.error('Suspend error:', e)
    }
  }

  const riskColor = (score) => {
    if (!score) return '#9B9B9B'
    if (score > 0.75) return '#12B76A'
    if (score >= 0.5) return '#F79009'
    return '#F04438'
  }

  return (
    <div style={{ padding: '24px 32px', color: 'white', maxWidth: 1200, margin: '0 auto' }}>
      
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 28, margin: '0 0 8px' }}>Worker Management</h1>
          <p style={{ color: '#9B9B9B', fontSize: 14, margin: '0 0 6px' }}>{total} total registered delivery partners</p>
          {usingDemo && (
            <span style={{
              fontSize: 11, fontWeight: 700, fontFamily: 'Inter',
              color: '#F79009', background: 'rgba(247,144,9,0.1)',
              padding: '2px 10px', borderRadius: 999,
              border: '1px solid rgba(247,144,9,0.2)',
            }}>
              DEMO DATA — No real workers yet
            </span>
          )}
        </div>
        <button 
          onClick={exportToCSV}
          style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '10px 16px', background: '#D97757', color: 'white', border: 'none', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}>
          <FileDown size={16} /> Export CSV
        </button>
      </div>

      <div style={{ display: 'flex', gap: 16, marginBottom: 24 }}>
        <div style={{ flex: 1, position: 'relative' }}>
          <Search size={18} color="#6B6B6B" style={{ position: 'absolute', top: 11, left: 14 }} />
          <input 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && fetchWorkers()}
            placeholder="Search name, phone, or city..."
            style={{ width: '100%', padding: '10px 14px 10px 42px', background: '#1A1A1A', border: '1px solid #333', borderRadius: 8, color: 'white', outline: 'none' }}
          />
        </div>
        <select 
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          style={{ padding: '10px 16px', background: '#1A1A1A', border: '1px solid #333', borderRadius: 8, color: 'white', outline: 'none', cursor: 'pointer' }}
        >
          <option value="ALL">All Status</option>
          <option value="ACTIVE">Active Policy</option>
          <option value="INACTIVE">No Policy</option>
        </select>
        <button 
          onClick={fetchWorkers}
          style={{ padding: '10px 20px', background: '#2E2E2E', border: '1px solid #444', borderRadius: 8, color: 'white', cursor: 'pointer' }}>
          Apply
        </button>
      </div>

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 60 }}>
          <div className="w-8 h-8 border-4 border-[#333] border-t-[#D97757] rounded-full animate-spin" />
        </div>
      ) : (
        <div style={{ background: '#111', border: '1px solid #222', borderRadius: 12, overflow: 'hidden' }}>
          
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead style={{ background: '#1A1A1A', borderBottom: '1px solid #222' }}>
              <tr>
                <th style={{ padding: '16px 24px', fontSize: 12, color: '#9B9B9B', textTransform: 'uppercase', letterSpacing: 1 }}>Worker Info</th>
                <th style={{ padding: '16px 24px', fontSize: 12, color: '#9B9B9B', textTransform: 'uppercase', letterSpacing: 1 }}>City & Zone</th>
                <th style={{ padding: '16px 24px', fontSize: 12, color: '#9B9B9B', textTransform: 'uppercase', letterSpacing: 1 }}>Income Tier</th>
                <th style={{ padding: '16px 24px', fontSize: 12, color: '#9B9B9B', textTransform: 'uppercase', letterSpacing: 1 }}>Risk Score</th>
                <th style={{ padding: '16px 24px', fontSize: 12, color: '#9B9B9B', textTransform: 'uppercase', letterSpacing: 1 }}>Status</th>
                <th style={{ padding: '16px 24px', fontSize: 12, color: '#9B9B9B', textTransform: 'uppercase', letterSpacing: 1 }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {workers.map((worker, i) => (
                <tr key={worker.id || i} style={{ borderBottom: i < workers.length - 1 ? '1px solid #222' : 'none' }}>
                  <td style={{ padding: '16px 24px' }}>
                    <div style={{ fontWeight: 600, color: 'white', marginBottom: 4 }}>{worker.name || 'Anonymous'}</div>
                    <div style={{ fontSize: 12, color: '#6B6B6B' }}>{worker.phone || 'No phone'}</div>
                  </td>
                  <td style={{ padding: '16px 24px', color: '#E4E4E7' }}>
                    <div style={{ fontWeight: 500, marginBottom: 4 }}>{worker.city || 'Unknown'}</div>
                    <div style={{ fontSize: 12, color: '#6B6B6B' }}>{worker.zone || 'No zone set'}</div>
                  </td>
                  <td style={{ padding: '16px 24px' }}>
                    <div style={{
                      display: 'inline-flex', padding: '4px 10px', borderRadius: 999, fontSize: 12, fontWeight: 700,
                      background: (worker.income_tier || 'Bronze') === 'Gold' ? 'rgba(255, 215, 0, 0.15)' : (worker.income_tier || 'Bronze') === 'Silver' ? 'rgba(168, 169, 173, 0.15)' : 'rgba(205, 127, 50, 0.15)',
                      color: (worker.income_tier || 'Bronze') === 'Gold' ? '#FFD700' : (worker.income_tier || 'Bronze') === 'Silver' ? '#A8A9AD' : '#CD7F32'
                    }}>
                      {worker.income_tier || 'Bronze'}
                    </div>
                  </td>
                  <td style={{ padding: '16px 24px' }}>
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: `${riskColor(worker.risk_score)}15`, color: riskColor(worker.risk_score), padding: '4px 10px', borderRadius: 999, fontSize: 12, fontWeight: 700 }}>
                      <ShieldAlert size={14} /> {(worker.risk_score * 100)?.toFixed(0) || 0}
                    </div>
                  </td>
                  <td style={{ padding: '16px 24px' }}>
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: worker.suspended ? '#F04438' : worker.is_active ? '#12B76A' : '#9B9B9B', fontSize: 12, fontWeight: 600 }}>
                      <BadgeCheck size={14} /> {worker.suspended ? 'Suspended' : worker.is_active ? 'Active' : 'Inactive'}
                    </div>
                  </td>
                  <td style={{ padding: '16px 24px' }}>
                    <motion.button
                      onClick={() => handleSuspend(worker.id || worker._id, !worker.suspended)}
                      whileTap={{ scale: 0.95 }}
                      style={{
                        padding: '4px 10px',
                        borderRadius: 6,
                        border: worker.suspended
                          ? '1px solid rgba(18,183,106,0.3)'
                          : '1px solid rgba(240,68,56,0.3)',
                        background: worker.suspended
                          ? 'rgba(18,183,106,0.1)'
                          : 'rgba(240,68,56,0.1)',
                        color: worker.suspended ? '#12B76A' : '#F04438',
                        fontSize: 11, fontWeight: 700,
                        fontFamily: 'Inter', cursor: 'pointer',
                      }}
                    >
                      {worker.suspended ? 'Unsuspend' : 'Suspend'}
                    </motion.button>
                  </td>
                </tr>
              ))}
              {workers.length === 0 && (
                <tr>
                  <td colSpan={4} style={{ padding: 40, textAlign: 'center', color: '#6B6B6B' }}>No workers found matching your criteria.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
