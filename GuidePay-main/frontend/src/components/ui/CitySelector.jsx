import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { MapPin, Search, ChevronDown } from 'lucide-react'

const FALLBACK_CITIES = [
  { zone_key: 'hyderabad-ts', city: 'Hyderabad', district: 'Hyderabad', state: 'Telangana', lat: 17.385, lng: 78.4867, flood_risk_score: 72 },
  { zone_key: 'mumbai-mh', city: 'Mumbai', district: 'Mumbai City', state: 'Maharashtra', lat: 19.076, lng: 72.8777, flood_risk_score: 88 },
  { zone_key: 'bengaluru-ka', city: 'Bengaluru', district: 'Bangalore Urban', state: 'Karnataka', lat: 12.9716, lng: 77.5946, flood_risk_score: 32 },
  { zone_key: 'chennai-tn', city: 'Chennai', district: 'Chennai', state: 'Tamil Nadu', lat: 13.0827, lng: 80.2707, flood_risk_score: 79 },
  { zone_key: 'delhi-dl', city: 'Delhi', district: 'New Delhi', state: 'Delhi', lat: 28.6139, lng: 77.209, flood_risk_score: 48 },
  { zone_key: 'kolkata-wb', city: 'Kolkata', district: 'Kolkata', state: 'West Bengal', lat: 22.5726, lng: 88.3639, flood_risk_score: 85 },
  { zone_key: 'pune-mh', city: 'Pune', district: 'Pune', state: 'Maharashtra', lat: 18.5204, lng: 73.8567, flood_risk_score: 55 },
  { zone_key: 'ahmedabad-gj', city: 'Ahmedabad', district: 'Ahmedabad', state: 'Gujarat', lat: 23.0225, lng: 72.5714, flood_risk_score: 58 },
  { zone_key: 'lucknow-up', city: 'Lucknow', district: 'Lucknow', state: 'Uttar Pradesh', lat: 26.8467, lng: 80.9462, flood_risk_score: 62 },
  { zone_key: 'jaipur-rj', city: 'Jaipur', district: 'Jaipur', state: 'Rajasthan', lat: 26.9124, lng: 75.7873, flood_risk_score: 35 },
  { zone_key: 'ranchi-jh', city: 'Ranchi', district: 'Ranchi', state: 'Jharkhand', lat: 23.3441, lng: 85.3096, flood_risk_score: 42 },
  { zone_key: 'guwahati-as', city: 'Guwahati', district: 'Kamrup Metropolitan', state: 'Assam', lat: 26.1445, lng: 91.7362, flood_risk_score: 92 },
  { zone_key: 'kochi-kl', city: 'Kochi', district: 'Ernakulam', state: 'Kerala', lat: 9.9312, lng: 76.2673, flood_risk_score: 79 },
  { zone_key: 'bhopal-mp', city: 'Bhopal', district: 'Bhopal', state: 'Madhya Pradesh', lat: 23.2599, lng: 77.4126, flood_risk_score: 42 },
  { zone_key: 'patna-br', city: 'Patna', district: 'Patna', state: 'Bihar', lat: 25.5941, lng: 85.1376, flood_risk_score: 88 },
  { zone_key: 'visakhapatnam-ap', city: 'Visakhapatnam', district: 'Visakhapatnam', state: 'Andhra Pradesh', lat: 17.6868, lng: 83.2185, flood_risk_score: 75 },
  { zone_key: 'nagpur-mh', city: 'Nagpur', district: 'Nagpur', state: 'Maharashtra', lat: 21.1458, lng: 79.0882, flood_risk_score: 52 },
  { zone_key: 'coimbatore-tn', city: 'Coimbatore', district: 'Coimbatore', state: 'Tamil Nadu', lat: 11.0168, lng: 76.9558, flood_risk_score: 41 },
  { zone_key: 'surat-gj', city: 'Surat', district: 'Surat', state: 'Gujarat', lat: 21.1702, lng: 72.8311, flood_risk_score: 72 },
  { zone_key: 'dehradun-uk', city: 'Dehradun', district: 'Dehradun', state: 'Uttarakhand', lat: 30.3165, lng: 78.0322, flood_risk_score: 55 },
]

const getRiskColor = (score) => {
  if (score > 70) return '#F04438'
  if (score > 40) return '#F79009'
  return '#12B76A'
}

const getRiskLabel = (score) => {
  if (score > 70) return 'High Risk'
  if (score > 40) return 'Medium Risk'
  return 'Low Risk'
}

const CityOption = ({ city, onSelect, showState = false }) => (
  <motion.div
    onClick={() => onSelect(city)}
    whileHover={{ background: 'var(--bg-secondary, #F9FAFB)' }}
    style={{
      padding: '10px 14px',
      cursor: 'pointer',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      borderBottom: '1px solid var(--border-light, #F4F4F5)',
    }}
  >
    <div>
      <p style={{
        fontSize: 13, fontWeight: 600, fontFamily: 'Inter',
        color: 'var(--text-primary, #0F0F0F)', margin: 0,
      }}>
        {city.city}
        {showState && (
          <span style={{ fontSize: 11, fontWeight: 400, color: 'var(--text-tertiary, #9B9B9B)', marginLeft: 6 }}>
            {city.state}
          </span>
        )}
      </p>
      {city.district && !showState && (
        <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary, #9B9B9B)', margin: 0 }}>
          {city.district}
        </p>
      )}
    </div>
    <span style={{
      fontSize: 9, fontWeight: 700, fontFamily: 'Inter',
      color: getRiskColor(city.flood_risk_score || 50),
      background: `${getRiskColor(city.flood_risk_score || 50)}15`,
      padding: '2px 8px', borderRadius: 999, whiteSpace: 'nowrap',
    }}>
      {getRiskLabel(city.flood_risk_score || 50)}
    </span>
  </motion.div>
)

export const CitySelector = ({ value, onChange, placeholder = 'Search your city...', error }) => {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [selectedCity, setSelectedCity] = useState(null)
  const inputRef = useRef(null)
  const searchTimeout = useRef(null)

  useEffect(() => {
    loadInitialCities()
  }, [])

  const loadInitialCities = async () => {
    try {
      const BASE = (typeof import.meta !== 'undefined' && import.meta.env?.VITE_API_URL) || 'http://localhost:8000'
      const res = await fetch(`${BASE}/api/v1/workers/cities/all`)
      if (res.ok) {
        const data = await res.json()
        setResults(data.cities || FALLBACK_CITIES)
      } else {
        setResults(FALLBACK_CITIES)
      }
    } catch {
      setResults(FALLBACK_CITIES)
    }
  }

  const searchCities = async (q) => {
    if (!q || q.length < 2) {
      loadInitialCities()
      return
    }
    setLoading(true)
    try {
      const BASE = (typeof import.meta !== 'undefined' && import.meta.env?.VITE_API_URL) || 'http://localhost:8000'
      const res = await fetch(`${BASE}/api/v1/workers/cities/search?query=${encodeURIComponent(q)}`)
      if (res.ok) {
        const data = await res.json()
        setResults(data.cities || [])
      } else {
        filterLocal(q)
      }
    } catch {
      filterLocal(q)
    } finally {
      setLoading(false)
    }
  }

  const filterLocal = (q) => {
    const ql = q.toLowerCase()
    setResults(
      FALLBACK_CITIES.filter(c =>
        c.city.toLowerCase().includes(ql) ||
        c.state.toLowerCase().includes(ql) ||
        (c.district || '').toLowerCase().includes(ql)
      )
    )
  }

  const handleInputChange = (e) => {
    const q = e.target.value
    setQuery(q)
    clearTimeout(searchTimeout.current)
    searchTimeout.current = setTimeout(() => searchCities(q), 300)
  }

  const handleSelect = (city) => {
    setSelectedCity(city)
    setQuery('')
    setOpen(false)
    if (onChange) {
      onChange({
        zone: city.zone_key,
        city: city.city,
        state: city.state,
        lat: city.lat,
        lng: city.lng,
        flood_risk_score: city.flood_risk_score,
      })
    }
  }

  // Group by state for browse mode
  const groupedResults = {}
  results.forEach(city => {
    if (!groupedResults[city.state]) groupedResults[city.state] = []
    groupedResults[city.state].push(city)
  })

  const displayCity = selectedCity || value

  return (
    <div style={{ position: 'relative' }}>
      <motion.div
        onClick={() => {
          setOpen(!open)
          setTimeout(() => inputRef.current?.focus(), 100)
        }}
        style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '12px 14px',
          background: 'white',
          border: error ? '1.5px solid #F04438' : '1.5px solid #E4E4E7',
          borderRadius: 12, cursor: 'pointer', minHeight: 48,
        }}
      >
        <MapPin size={16} color="#9B9B9B" />
        {displayCity ? (
          <div style={{ flex: 1 }}>
            <p style={{ fontSize: 14, fontWeight: 600, fontFamily: 'Inter', color: '#0F0F0F', margin: 0 }}>
              {displayCity.city || displayCity.zone}
            </p>
            <p style={{ fontSize: 11, fontFamily: 'Inter', color: '#9B9B9B', margin: 0 }}>
              {displayCity.state}
            </p>
          </div>
        ) : (
          <span style={{ flex: 1, fontSize: 14, fontFamily: 'Inter', color: '#9B9B9B' }}>
            {placeholder}
          </span>
        )}
        <ChevronDown
          size={16} color="#9B9B9B"
          style={{ transform: open ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }}
        />
      </motion.div>

      {error && (
        <p style={{ fontSize: 11, color: '#F04438', fontFamily: 'Inter', margin: '4px 0 0' }}>{error}</p>
      )}

      <AnimatePresence>
        {open && (
          <>
            <div onClick={() => setOpen(false)} style={{ position: 'fixed', inset: 0, zIndex: 99 }} />
            <motion.div
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              style={{
                position: 'absolute', top: '100%', left: 0, right: 0,
                marginTop: 6,
                background: 'white',
                border: '1px solid #E4E4E7',
                borderRadius: 14, zIndex: 100,
                maxHeight: 360, overflow: 'hidden',
                display: 'flex', flexDirection: 'column',
                boxShadow: '0 8px 32px rgba(0,0,0,0.12)',
              }}
            >
              {/* Search input */}
              <div style={{
                padding: '10px 12px',
                borderBottom: '1px solid #F4F4F5',
                display: 'flex', alignItems: 'center', gap: 8,
                flexShrink: 0,
              }}>
                <Search size={14} color="#9B9B9B" />
                <input
                  ref={inputRef}
                  value={query}
                  onChange={handleInputChange}
                  placeholder="Search city, district, state..."
                  style={{
                    flex: 1, border: 'none', outline: 'none',
                    fontSize: 13, fontFamily: 'Inter',
                    background: 'transparent', color: '#0F0F0F',
                  }}
                />
                {loading && (
                  <div style={{
                    width: 14, height: 14,
                    border: '2px solid #D97757',
                    borderTopColor: 'transparent',
                    borderRadius: 999,
                    animation: 'spin 0.8s linear infinite',
                  }} />
                )}
              </div>

              {/* Results list */}
              <div style={{ overflowY: 'auto', flex: 1 }}>
                {query.length < 2 ? (
                  Object.entries(groupedResults)
                    .sort(([a], [b]) => a.localeCompare(b))
                    .map(([state, cities]) => (
                      <div key={state}>
                        <div style={{
                          padding: '8px 14px 4px',
                          fontSize: 10, fontWeight: 700,
                          fontFamily: 'Inter',
                          color: '#9B9B9B',
                          letterSpacing: '1.5px',
                          textTransform: 'uppercase',
                          background: '#F9FAFB',
                          position: 'sticky', top: 0,
                        }}>
                          {state}
                        </div>
                        {cities.map(city => (
                          <CityOption key={city.zone_key} city={city} onSelect={handleSelect} />
                        ))}
                      </div>
                    ))
                ) : results.length === 0 ? (
                  <div style={{
                    padding: '30px 20px', textAlign: 'center',
                    color: '#9B9B9B', fontSize: 13, fontFamily: 'Inter',
                  }}>
                    No cities found for "{query}"
                  </div>
                ) : (
                  results.map(city => (
                    <CityOption key={city.zone_key} city={city} onSelect={handleSelect} showState={true} />
                  ))
                )}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  )
}

export default CitySelector
