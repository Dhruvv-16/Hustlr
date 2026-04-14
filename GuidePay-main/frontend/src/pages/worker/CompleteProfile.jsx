import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import Button from '../../components/ui/Button'
import { useWorkerStore } from '../../store/workerStore'
import { createUserProfile, updateMyProfile } from '../../services/api'
import { ZONE_SUGGESTIONS } from '../../utils/constants'

const pendingProfileKey = 'gp-pending-profile'

export default function CompleteProfile() {
  const storedPendingProfile = (() => {
    const stored = sessionStorage.getItem(pendingProfileKey)
    return stored ? JSON.parse(stored) : null
  })()
  const navigate = useNavigate()
  const worker = useWorkerStore((s) => s.worker)
  const login = useWorkerStore((s) => s.login)
  const updateWorker = useWorkerStore((s) => s.updateWorker)
  const [pendingProfile] = useState(storedPendingProfile)
  const [name, setName] = useState(() => worker?.name || storedPendingProfile?.name || '')
  const [phone, setPhone] = useState(() => worker?.phone || storedPendingProfile?.phone || '')
  const [upiId, setUpiId] = useState(() => worker?.upi_id || '')
  const [region, setRegion] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    setName(worker?.name || pendingProfile?.name || '')
    setPhone(worker?.phone || pendingProfile?.phone || '')
    setUpiId(worker?.upi_id || '')
    setRegion(worker?.zone || '')
  }, [pendingProfile, worker])

  const selectedRegion = useMemo(
    () => ZONE_SUGGESTIONS.find((zone) => zone.id === region),
    [region]
  )

  useEffect(() => {
    const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')
    if (!pendingProfile && !token && !worker) {
      navigate('/login', { replace: true })
    }
  }, [navigate, pendingProfile, worker])

  const handleSubmit = async () => {
    if (!name.trim() || !phone.trim() || !selectedRegion) {
      setError('Please complete all fields')
      return
    }

    setLoading(true)
    setError('')

    try {
      const token = localStorage.getItem('gp-token') || localStorage.getItem('gp-access-token')

      if (pendingProfile?.idToken && !token) {
        const data = await createUserProfile({
          firebase_token: pendingProfile.idToken,
          name: name.trim(),
          phone: phone.trim(),
          city: selectedRegion.city,
          zone: selectedRegion.id,
          upi_id: upiId.trim(),
          zone_lat: selectedRegion.lat,
          zone_lng: selectedRegion.lng,
        })
        localStorage.setItem('gp-access-token', data.access_token)
        localStorage.setItem('gp-token', data.access_token)
        login(data.worker)
        sessionStorage.removeItem(pendingProfileKey)
      } else {
        const updated = await updateMyProfile({
          name: name.trim(),
          phone: phone.trim(),
          city: selectedRegion.city,
          zone: selectedRegion.id,
          upi_id: upiId.trim(),
          zone_lat: selectedRegion.lat,
          zone_lng: selectedRegion.lng,
        })
        updateWorker(updated)
      }

      navigate('/dashboard', { replace: true })
    } catch (e) {
      setError(e?.detail || e?.message || 'Profile setup failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-white pb-24">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        className="px-4 pt-10"
      >
        <div className="mx-auto max-w-[430px]">
          <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 28, fontWeight: 800, color: '#0F0F0F', margin: '0 0 8px' }}>
            Complete your profile
          </h1>
          <p style={{ fontSize: 14, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', margin: '0 0 24px' }}>
            Finish setup before entering the dashboard.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div>
              <label style={{ display: 'block', fontSize: 13, fontWeight: 500, fontFamily: 'Inter, sans-serif', color: '#6B6B6B', marginBottom: 6 }}>
                Name
              </label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                style={{ width: '100%', padding: '0 14px', height: 52, border: '1.5px solid #E4E4E7', borderRadius: 12, fontSize: 15, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', outline: 'none', background: 'white', boxSizing: 'border-box' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', marginBottom: 6 }}>
                Phone
              </label>
              <input
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                style={{ width: '100%', padding: '0 14px', height: 52, border: '1.5px solid #E4E4E7', borderRadius: 12, fontSize: 15, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', outline: 'none', background: 'white', boxSizing: 'border-box' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: 13, fontWeight: 500, fontFamily: 'Inter, sans-serif', color: '#6B6B6B', marginBottom: 6 }}>
                Region
              </label>
              <select
                value={region}
                onChange={(e) => setRegion(e.target.value)}
                style={{ width: '100%', padding: '0 14px', height: 52, border: '1.5px solid #E4E4E7', borderRadius: 12, fontSize: 15, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', outline: 'none', background: 'white', boxSizing: 'border-box' }}
              >
                <option value="">Select your region</option>
                {ZONE_SUGGESTIONS.map((zone) => (
                  <option key={zone.id} value={zone.id}>
                    {zone.name}, {zone.city}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: 13, fontWeight: 500, fontFamily: 'Inter, sans-serif', color: '#6B6B6B', marginBottom: 6 }}>
                UPI ID
              </label>
              <input
                value={upiId}
                onChange={(e) => setUpiId(e.target.value)}
                placeholder="name@bank"
                style={{ width: '100%', padding: '0 14px', height: 52, border: '1.5px solid #E4E4E7', borderRadius: 12, fontSize: 15, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', outline: 'none', background: 'white', boxSizing: 'border-box' }}
              />
            </div>

            {error ? (
              <p style={{ fontSize: 12, color: '#F04438', fontFamily: 'Inter, sans-serif', margin: 0 }}>
                {error}
              </p>
            ) : null}

            <Button onClick={handleSubmit} loading={loading} fullWidth>
              Continue
            </Button>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
