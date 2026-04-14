import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Search, MapPin, CheckCircle2 } from 'lucide-react'
import TopBar from '../../components/ui/TopBar'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import LiveDot from '../../components/ui/LiveDot'
import { useWorkerStore } from '../../store/workerStore'
import { PLATFORMS, ZONE_SUGGESTIONS, ZONE_RISK } from '../../utils/constants'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const riskBadgeVariant = { HIGH: 'danger', MED: 'warning', LOW: 'success' }

export default function ZoneSelect() {
  const navigate = useNavigate()
  const updateWorker = useWorkerStore((s) => s.updateWorker)
  const [selectedPlatforms, setSelectedPlatforms] = useState(['zepto'])
  const [search, setSearch] = useState('')
  const [selectedZone, setSelectedZone] = useState(null)
  const [showDropdown, setShowDropdown] = useState(false)

  const filtered = search.length > 1
    ? ZONE_SUGGESTIONS.filter((z) =>
        z.name.toLowerCase().includes(search.toLowerCase()) ||
        z.city.toLowerCase().includes(search.toLowerCase())
      )
    : []

  const togglePlatform = (id) => {
    setSelectedPlatforms((prev) =>
      prev.includes(id) ? prev.filter((p) => p !== id) : [...prev, id]
    )
  }

  const handleZoneSelect = (zone) => {
    setSelectedZone(zone)
    setSearch('')
    setShowDropdown(false)
  }

  const handleNext = () => {
    updateWorker({
      platforms: selectedPlatforms,
      zone: selectedZone?.id,
      city: selectedZone?.city,
    })
    navigate('/risk-score')
  }

  const zoneRisk = selectedZone
    ? (ZONE_RISK[selectedZone.id] || ZONE_RISK.default)
    : null

  return (
    <motion.div
      className="min-h-screen bg-white pb-28"
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      <TopBar title="Set up your coverage" />

      {/* Progress */}
      <div className="px-4 pt-3 pb-1 flex items-center justify-between">
        <div className="flex-1 h-[3px] bg-grey-200 rounded-full overflow-hidden mr-3">
          <div className="h-full bg-brand rounded-full" style={{ width: '33%' }} />
        </div>
        <span className="text-[11px] text-[#9B9B9B] font-body flex-shrink-0">Step 1 of 3</span>
      </div>

      <div className="px-4">
        {/* Platforms */}
        <p className="text-[13px] font-medium text-[#6B6B6B] font-body py-4">
          Which platforms do you deliver for?
        </p>

        <div className="grid grid-cols-2 gap-3">
          {PLATFORMS.map((platform) => {
            const selected = selectedPlatforms.includes(platform.id)
            return (
              <motion.button
                key={platform.id}
                whileTap={{ scale: 0.97 }}
                onClick={() => togglePlatform(platform.id)}
                className={`
                  relative p-3.5 rounded-card text-left transition-all duration-150
                  ${selected
                    ? 'bg-brand-light border-[1.5px] border-brand shadow-card'
                    : 'bg-white border-[1.5px] border-grey-200 shadow-card'
                  }
                `}
              >
                {selected && (
                  <CheckCircle2
                    size={16}
                    className="text-brand absolute top-2.5 right-2.5"
                  />
                )}
                <div className="flex items-center gap-2">
                  <span className="text-[22px]">{platform.emoji}</span>
                  <div>
                    <p className="text-[14px] font-semibold font-body text-[#0F0F0F]">
                      {platform.name}
                    </p>
                    <p className="text-[12px] text-[#9B9B9B] font-body">{platform.sub}</p>
                  </div>
                </div>
              </motion.button>
            )
          })}
        </div>

        {/* Zone search */}
        <p className="text-[13px] font-medium text-[#6B6B6B] font-body py-4">
          Your delivery area
        </p>

        <div className="relative">
          <div className="flex items-center gap-3 px-4 h-[52px] rounded-input border-[1.5px] border-[#E4E4E7] bg-white focus-within:border-brand focus-within:shadow-[0_0_0_3px_rgba(217,119,87,0.1)] transition-all">
            <Search size={16} className="text-[#9B9B9B] flex-shrink-0" />
            <input
              type="text"
              placeholder="Search area or landmark..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value)
                setShowDropdown(true)
              }}
              onFocus={() => setShowDropdown(true)}
              className="flex-1 text-[15px] font-body text-[#0F0F0F] placeholder:text-[#C4C4C4] outline-none bg-transparent"
            />
          </div>

          {/* Dropdown */}
          {showDropdown && filtered.length > 0 && (
            <div className="absolute top-[56px] left-0 right-0 bg-white rounded-card shadow-lg z-50 border border-grey-200 overflow-hidden">
              {filtered.map((zone) => (
                <button
                  key={zone.id}
                  onClick={() => handleZoneSelect(zone)}
                  className="w-full flex items-center gap-3 px-4 py-3 border-b border-grey-100 hover:bg-grey-50 text-left"
                >
                  <MapPin size={14} className="text-[#9B9B9B] flex-shrink-0" />
                  <div>
                    <p className="text-[14px] font-body text-[#0F0F0F]">{zone.name}</p>
                    <p className="text-[12px] text-[#6B6B6B] font-body">{zone.city}</p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Selected zone card */}
        {selectedZone && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="mt-3 bg-white rounded-card shadow-card p-4"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <MapPin size={18} className="text-brand" />
                <div>
                  <p className="text-[15px] font-semibold font-body text-[#0F0F0F]">
                    {selectedZone.name}, {selectedZone.city}
                  </p>
                  <p className="text-[12px] text-[#6B6B6B] font-body">
                    {selectedZone.city} · 5km radius
                  </p>
                </div>
              </div>
              <button
                onClick={() => { setSelectedZone(null); setSearch('') }}
                className="text-brand text-[12px] font-semibold font-body"
              >
                Change
              </button>
            </div>

            {/* Risk chips */}
            {zoneRisk && (
              <div className="flex gap-2 mt-3 flex-wrap">
                <span className="flex items-center gap-1.5 text-[13px] font-body text-[#0F0F0F]">
                  🌊 Flood <Badge variant={riskBadgeVariant[zoneRisk.flood]}>{zoneRisk.flood}</Badge>
                </span>
                <span className="flex items-center gap-1.5 text-[13px] font-body text-[#0F0F0F]">
                  📱 Outage <Badge variant={riskBadgeVariant[zoneRisk.outage]}>{zoneRisk.outage}</Badge>
                </span>
                <span className="flex items-center gap-1.5 text-[13px] font-body text-[#0F0F0F]">
                  🚫 Curfew <Badge variant={riskBadgeVariant[zoneRisk.curfew]}>{zoneRisk.curfew}</Badge>
                </span>
              </div>
            )}

            {/* Map placeholder (real map needs API key) */}
            <div className="mt-3 h-[180px] rounded-xl bg-grey-100 overflow-hidden relative">
              <div className="absolute inset-0 flex flex-col items-center justify-center gap-2">
                <MapPin size={32} className="text-brand" />
                <p className="text-[13px] font-body text-[#6B6B6B]">
                  {selectedZone.name}, {selectedZone.city}
                </p>
                <p className="text-[11px] text-[#9B9B9B] font-body">5km monitoring radius</p>
              </div>
            </div>

            {/* Monitor chip */}
            <div className="flex items-center gap-2 mt-2">
              <LiveDot status="active" />
              <span className="text-[12px] text-[#9B9B9B] font-body">Monitored every 15 min</span>
            </div>
          </motion.div>
        )}
      </div>

      {/* Sticky bottom */}
      <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] bg-white border-t border-grey-100 px-4 py-3 z-40">
        <Button
          onClick={handleNext}
          fullWidth
          disabled={!selectedZone || selectedPlatforms.length === 0}
        >
          Calculate My Risk Score →
        </Button>
      </div>
    </motion.div>
  )
}
