import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight } from 'lucide-react'

// Year-independent holidays — MM-DD keys only
const HOLIDAY_TEMPLATES = {
  '01-01': { name: "New Year's Day", emoji: '🎉', type: 'public', risk: 'low' },
  '01-14': { name: 'Makar Sankranti', emoji: '🪁', type: 'festival', risk: 'medium', note: 'Order surge · Zone delays' },
  '01-23': { name: 'Netaji Jayanti', emoji: '🇮🇳', type: 'public', risk: 'low' },
  '01-26': { name: 'Republic Day', emoji: '🇮🇳', type: 'national', risk: 'high', note: 'Road closures · Possible restrictions' },
  '02-14': { name: "Valentine's Day", emoji: '💝', type: 'informal', risk: 'low', note: 'High order surge' },
  '02-26': { name: 'Maha Shivratri', emoji: '🙏', type: 'festival', risk: 'low' },
  '03-20': { name: 'Holi', emoji: '🌈', type: 'festival', risk: 'high', note: 'Major disruption · Platform slowdowns · Street closures' },
  '03-31': { name: 'Eid ul-Fitr', emoji: '🌙', type: 'festival', risk: 'medium', note: 'High order volume · Traffic delays' },
  '04-06': { name: 'Ram Navami', emoji: '🏹', type: 'festival', risk: 'low' },
  '04-10': { name: 'Good Friday', emoji: '✝️', type: 'public', risk: 'low' },
  '04-14': { name: 'Ambedkar Jayanti / Tamil New Year', emoji: '📘', type: 'public', risk: 'medium', note: 'Processions in some cities' },
  '05-01': { name: 'Labour Day', emoji: '✊', type: 'public', risk: 'medium', note: 'Platform worker protests possible' },
  '05-09': { name: 'Rabindra Jayanti', emoji: '🎶', type: 'regional', risk: 'low' },
  '06-07': { name: 'Eid ul-Adha', emoji: '🐑', type: 'festival', risk: 'medium', note: 'High demand · Route delays' },
  '06-15': { name: 'Monsoon begins', emoji: '🌧️', type: 'weather', risk: 'high', note: 'Flood season starts · Ensure coverage active' },
  '07-05': { name: 'Muharram', emoji: '🌙', type: 'festival', risk: 'medium' },
  '07-15': { name: 'Peak monsoon', emoji: '⛈️', type: 'weather', risk: 'high', note: 'Highest flood risk · IMD alerts likely' },
  '08-15': { name: 'Independence Day', emoji: '🇮🇳', type: 'national', risk: 'high', note: 'Security restrictions · Road closures' },
  '08-22': { name: 'Raksha Bandhan', emoji: '🧡', type: 'festival', risk: 'low', note: 'Order surge' },
  '08-29': { name: 'Janmashtami', emoji: '🪈', type: 'festival', risk: 'medium', note: 'Dahi Handi events · Route delays' },
  '09-17': { name: 'Ganesh Chaturthi', emoji: '🐘', type: 'festival', risk: 'high', note: 'Massive disruption Mumbai/Pune · 10 days of events' },
  '10-02': { name: 'Gandhi Jayanti', emoji: '🕊️', type: 'national', risk: 'low' },
  '10-15': { name: 'Navratri begins', emoji: '🪔', type: 'festival', risk: 'medium', note: '9 day festival · Varied disruptions' },
  '10-20': { name: 'Dussehra', emoji: '🏹', type: 'festival', risk: 'high', note: 'Major processions · Traffic jams · Platform surge' },
  '10-28': { name: 'Diwali', emoji: '🪔', type: 'festival', risk: 'high', note: 'Highest demand day · Air quality warnings · Possible disruptions' },
  '10-30': { name: 'Govardhan Puja', emoji: '🌼', type: 'festival', risk: 'low' },
  '11-02': { name: 'Bhai Dooj', emoji: '💛', type: 'festival', risk: 'low' },
  '11-09': { name: 'Guru Nanak Jayanti', emoji: '🙏', type: 'festival', risk: 'medium', note: 'Processions in North India' },
  '12-25': { name: 'Christmas', emoji: '🎄', type: 'public', risk: 'low', note: 'High order surge expected' },
  '12-31': { name: "New Year's Eve", emoji: '🎆', type: 'informal', risk: 'medium', note: 'Very high order volume · Late night surge' },
}

// Monsoon months (1-indexed): June-Sept = high risk
const MONSOON_MONTHS = [6, 7, 8, 9]

const MONSOON_RISK = {
  5: 'low',
  6: 'high',
  7: 'high',
  8: 'high',
  9: 'medium',
  10: 'low',
}

const MONTH_NAMES = [
  'January', 'February', 'March', 'April',
  'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
]

const RISK_COLOR = {
  high: '#F04438',
  medium: '#F79009',
  low: '#12B76A',
  weather: '#2E90FA',
}

export const IndiaCalendar = () => {
  const now = new Date()
  const [year, setYear] = useState(now.getFullYear())
  const [month, setMonth] = useState(now.getMonth())
  const [selected, setSelected] = useState(null)

  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const firstDayOfWeek = new Date(year, month, 1).getDay()

  // Year-independent key: MM-DD
  const getKey = (day) => {
    const m = String(month + 1).padStart(2, '0')
    const d = String(day).padStart(2, '0')
    return `${m}-${d}`
  }

  const getEvent = (day) => HOLIDAY_TEMPLATES[getKey(day)]
  const isToday = (day) =>
    day === now.getDate() &&
    month === now.getMonth() &&
    year === now.getFullYear()

  const monsoonRisk = MONSOON_RISK[month + 1]
  const isMonsoon = MONSOON_MONTHS.includes(month + 1)

  const prev = () => {
    if (month === 0) { setMonth(11); setYear(y => y - 1) }
    else setMonth(m => m - 1)
    setSelected(null)
  }

  const next = () => {
    if (month === 11) { setMonth(0); setYear(y => y + 1) }
    else setMonth(m => m + 1)
    setSelected(null)
  }

  const selectedEvent = selected ? getEvent(selected) : null

  // Count events this month
  const monthPrefix = String(month + 1).padStart(2, '0')
  const monthEvents = Object.entries(HOLIDAY_TEMPLATES).filter(
    ([key]) => key.startsWith(monthPrefix + '-')
  )

  return (
    <div style={{
      background: 'var(--bg-card)',
      borderRadius: 16,
      border: '1px solid var(--border)',
      overflow: 'hidden',
    }}>
      {/* Monsoon warning banner */}
      {monsoonRisk === 'high' && (
        <div style={{
          background: 'rgba(240,68,56,0.08)',
          borderBottom: '1px solid rgba(240,68,56,0.15)',
          padding: '10px 16px',
          display: 'flex',
          gap: 8, alignItems: 'center',
        }}>
          <span style={{ fontSize: 16 }}>🌧️</span>
          <div>
            <p style={{
              fontSize: 12, fontWeight: 700,
              fontFamily: 'Inter', color: '#F04438',
              margin: 0,
            }}>
              Monsoon season — high flood risk
            </p>
            <p style={{
              fontSize: 11, color: 'var(--text-tertiary)',
              fontFamily: 'Inter', margin: 0,
            }}>
              Ensure your coverage is active this month
            </p>
          </div>
        </div>
      )}

      {/* Calendar header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '14px 16px',
        borderBottom: '1px solid var(--border-light)',
      }}>
        <motion.button
          onClick={prev}
          whileTap={{ scale: 0.85 }}
          style={{
            background: 'var(--bg-secondary)',
            border: 'none',
            borderRadius: 999,
            width: 32, height: 32,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <ChevronLeft size={16} color="var(--text-secondary)" />
        </motion.button>

        <div style={{ textAlign: 'center' }}>
          <p style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 16, fontWeight: 800,
            color: 'var(--text-primary)', margin: 0,
          }}>
            {MONTH_NAMES[month]} {year}
          </p>
          {monthEvents.length > 0 && (
            <p style={{
              fontSize: 11, color: 'var(--text-tertiary)',
              fontFamily: 'Inter', margin: '2px 0 0',
            }}>
              {monthEvents.length} events this month
            </p>
          )}
        </div>

        <motion.button
          onClick={next}
          whileTap={{ scale: 0.85 }}
          style={{
            background: 'var(--bg-secondary)',
            border: 'none',
            borderRadius: 999,
            width: 32, height: 32,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <ChevronRight size={16} color="var(--text-secondary)" />
        </motion.button>
      </div>

      {/* Day headers */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(7, 1fr)',
        padding: '8px 12px 2px',
      }}>
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(d => (
          <div key={d} style={{
            textAlign: 'center',
            fontSize: 10,
            fontFamily: 'Inter',
            fontWeight: 600,
            color: 'var(--text-tertiary)',
            padding: '4px 0',
          }}>
            {d}
          </div>
        ))}
      </div>

      {/* Date grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(7, 1fr)',
        padding: '0 8px 8px',
        gap: 1,
      }}>
        {/* Blank cells */}
        {Array.from({ length: firstDayOfWeek }).map((_, i) => (
          <div key={`blank-${i}`} style={{ height: 44 }} />
        ))}

        {/* Day cells */}
        {Array.from({ length: daysInMonth }, (_, i) => i + 1)
          .map(day => {
            const event = getEvent(day)
            const today = isToday(day)
            const sel = selected === day

            return (
              <motion.button
                key={day}
                onClick={() => setSelected(sel ? null : day)}
                whileTap={{ scale: 0.88 }}
                style={{
                  height: 44,
                  borderRadius: 10,
                  border: 'none',
                  cursor: 'pointer',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 2,
                  background: sel
                    ? '#FDF1ED'
                    : today
                      ? '#D97757'
                      : 'transparent',
                  position: 'relative',
                }}
              >
                <span style={{
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: today ? 700 : 400,
                  color: today ? 'white'
                    : sel ? '#D97757'
                      : 'var(--text-primary)',
                  lineHeight: 1,
                }}>
                  {day}
                </span>

                {/* Event indicator dot */}
                {event && (
                  <div style={{
                    width: 4, height: 4,
                    borderRadius: 999,
                    background: today
                      ? 'rgba(255,255,255,0.8)'
                      : RISK_COLOR[event.risk] || '#D97757',
                    flexShrink: 0,
                  }} />
                )}

                {/* Emoji for high-risk days */}
                {event && event.risk === 'high' && !today && (
                  <span style={{
                    fontSize: 7,
                    lineHeight: 1,
                    position: 'absolute',
                    top: 3,
                    right: 3,
                  }}>
                    ⚠️
                  </span>
                )}
              </motion.button>
            )
          })}
      </div>

      {/* Selected event detail */}
      <AnimatePresence>
        {selected && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            style={{ overflow: 'hidden' }}
          >
            <div style={{
              padding: '14px 16px',
              borderTop: '1px solid var(--border-light)',
              background: 'var(--bg-secondary)',
            }}>
              {selectedEvent ? (
                <div style={{
                  display: 'flex',
                  gap: 12,
                  alignItems: 'flex-start',
                }}>
                  <div style={{
                    width: 44, height: 44,
                    borderRadius: 12,
                    background: `${RISK_COLOR[selectedEvent.risk] || '#D97757'}15`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 22,
                    flexShrink: 0,
                  }}>
                    {selectedEvent.emoji}
                  </div>
                  <div style={{ flex: 1 }}>
                    <p style={{
                      fontSize: 14, fontWeight: 700,
                      fontFamily: 'Inter',
                      color: 'var(--text-primary)',
                      margin: '0 0 3px',
                    }}>
                      {selectedEvent.name}
                    </p>
                    {selectedEvent.note && (
                      <p style={{
                        fontSize: 12, fontFamily: 'Inter',
                        color: RISK_COLOR[selectedEvent.risk],
                        fontWeight: 600,
                        margin: '0 0 4px',
                      }}>
                        ⚠ {selectedEvent.note}
                      </p>
                    )}
                    <div style={{
                      display: 'flex',
                      gap: 6,
                      flexWrap: 'wrap',
                    }}>
                      <span style={{
                        fontSize: 10, fontWeight: 700,
                        fontFamily: 'Inter',
                        color: RISK_COLOR[selectedEvent.risk],
                        background: `${RISK_COLOR[selectedEvent.risk]}15`,
                        padding: '3px 8px',
                        borderRadius: 999,
                        textTransform: 'uppercase',
                        letterSpacing: '0.5px',
                      }}>
                        {selectedEvent.risk} risk
                      </span>
                      <span style={{
                        fontSize: 10, fontWeight: 600,
                        fontFamily: 'Inter',
                        color: 'var(--text-tertiary)',
                        background: 'var(--bg-tertiary, #F4F4F5)',
                        padding: '3px 8px',
                        borderRadius: 999,
                        textTransform: 'capitalize',
                      }}>
                        {selectedEvent.type}
                      </span>
                    </div>
                  </div>
                </div>
              ) : (
                <p style={{
                  fontSize: 13,
                  color: 'var(--text-tertiary)',
                  fontFamily: 'Inter', margin: 0,
                }}>
                  {MONTH_NAMES[month]} {selected} — No events scheduled
                </p>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Legend */}
      <div style={{
        display: 'flex',
        gap: 12,
        padding: '10px 16px',
        borderTop: '1px solid var(--border-light)',
        flexWrap: 'wrap',
      }}>
        {[
          { color: '#F04438', label: 'High disruption risk' },
          { color: '#F79009', label: 'Medium risk' },
          { color: '#12B76A', label: 'Low risk' },
        ].map(l => (
          <div key={l.label} style={{
            display: 'flex',
            alignItems: 'center',
            gap: 5,
          }}>
            <div style={{
              width: 6, height: 6,
              borderRadius: 999,
              background: l.color,
            }} />
            <span style={{
              fontSize: 10,
              fontFamily: 'Inter',
              color: 'var(--text-tertiary)',
            }}>
              {l.label}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

export default IndiaCalendar
