import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  Camera, MapPin, ChevronRight, Moon, Sun,
  Shield, FileText, Bell, Globe, ArrowLeft,
} from 'lucide-react'
import ThemeToggle from '../../components/ui/ThemeToggle'
import { useWorkerStore } from '../../store/workerStore'
import { useThemeStore } from '../../store/themeStore'
import { PROFILE_BACKGROUNDS } from '../../components/profile/ProfileBgOptions'
import { getMyProfile } from '../../services/api'
import { formatINR } from '../../utils/formatters'

export default function Profile() {
  const navigate = useNavigate()
  const { worker, logout } = useWorkerStore()
  const profileBg = useWorkerStore(s => s.profileBg) || 'plain'
  const setProfileBg = useWorkerStore(s => s.setProfileBg)
  const { isDark } = useThemeStore()
  const [photo, setPhoto] = useState(worker?.photoURL || null)
  const fileRef = useRef()
  const [realStats, setRealStats] = useState(null)
  const [profileData, setProfileData] = useState(null)
  const [showLangMenu, setShowLangMenu] = useState(false)
  const [selectedLang, setSelectedLang] = useState('en')

  // Fetch real profile stats on mount
  useEffect(() => {
    const fetchStats = async () => {
      try {
        const token = localStorage.getItem('gp-access-token') || localStorage.getItem('gp-token')
        if (!token) return
        const data = await getMyProfile()
        setProfileData(data)
        if (data?.stats) setRealStats(data.stats)
      } catch (e) {
        // Silent — will use fallback values
      }
    }
    fetchStats()
  }, [])

  const w = profileData || worker || {}
  const coverageLabel = w.active_policy?.coverage_cap
    ? `Active - Rs${w.active_policy.coverage_cap}/week`
    : 'Manage protection'

  const initials = (w.name || '?')
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)

  const handlePhotoChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (ev) => setPhoto(ev.target.result)
    reader.readAsDataURL(file)
  }

  const handleSignOut = () => {
    logout()
    navigate('/login')
  }

  const activeBg = PROFILE_BACKGROUNDS.find(g => g.id === profileBg) || PROFILE_BACKGROUNDS[0]
  const isGif = activeBg.type === 'gif'
  // For plain mode, use theme colors; for GIF mode, use white text on dark overlay
  const textPrimary = isGif ? 'white' : 'var(--text-primary)'
  const textSecondary = isGif ? 'rgba(255,255,255,0.8)' : 'var(--text-secondary)'
  const textTertiary = isGif ? 'rgba(255,255,255,0.6)' : 'var(--text-tertiary)'
  const textMuted = isGif ? 'rgba(255,255,255,0.5)' : 'var(--text-tertiary)'
  const cardBg = isGif ? 'rgba(255,255,255,0.12)' : 'var(--bg-card)'
  const cardBorder = isGif ? '1px solid rgba(255,255,255,0.2)' : '1px solid var(--border-light)'
  const iconBg = isGif ? 'rgba(255,255,255,0.15)' : 'var(--bg-secondary)'
  const iconColor = isGif ? 'white' : 'var(--text-secondary)'
  const pageBg = isGif ? 'transparent' : 'var(--bg-secondary)'
  const avatarBg = isGif ? 'rgba(255,255,255,0.25)' : 'var(--brand)'
  const avatarBorder = isGif ? '3px solid white' : '3px solid var(--bg-primary)'

  const SECTIONS = [
    {
      title: 'Coverage',
      items: [
        { icon: Shield, label: 'My coverage plan', sub: coverageLabel, action: () => navigate('/coverage') },
        { icon: Bell, label: 'Notifications', sub: 'Manage alerts' },
      ],
    },
    {
      title: 'Settings',
      items: [
        {
          icon: FileText,
          label: 'Edit profile details',
          sub: w.upi_id ? `UPI: ${w.upi_id}` : 'Update name, phone, region, UPI',
          action: () => navigate('/complete-profile'),
        },
      ],
    },
    {
      title: 'App',
      items: [
        {
          icon: isDark ? Sun : Moon,
          label: 'Dark mode',
          right: <ThemeToggle />,
        },
        {
          icon: Globe,
          label: 'Language',
          sub: selectedLang === 'en' ? 'English' : selectedLang === 'hi' ? 'हिन्दी' : selectedLang === 'te' ? 'తెలుగు' : selectedLang === 'ta' ? 'தமிழ்' : 'English',
          action: () => setShowLangMenu(!showLangMenu),
          right: (
            <span style={{
              fontSize: 12,
              color: textTertiary,
              fontFamily: 'Inter',
            }}>{selectedLang.toUpperCase()} ▾</span>
          ),
        },
      ],
    },
    {
      title: 'Legal',
      items: [
        { icon: FileText, label: 'Terms of Service', action: () => navigate('/terms') },
        { icon: Shield, label: 'Privacy Policy', action: () => navigate('/privacy') },
      ],
    },
  ]

  return (
    <div style={{
      minHeight: '100vh',
      paddingBottom: 100,
      position: 'relative',
      overflow: 'hidden',
      background: pageBg,
    }}>

      {/* FULL PAGE BACKGROUND — only for GIF mode */}
      {isGif && (
        <div style={{
          position: 'fixed',
          inset: 0,
          zIndex: 0,
        }}>
          <img
            key={activeBg.id}
            src={activeBg.src}
            alt=""
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              position: 'absolute',
              inset: 0,
            }}
          />
          {/* Overlay for readability */}
          <div style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(0,0,0,0.45)',
          }} />
        </div>
      )}

      {/* CONTENT — above background */}
      <div style={{
        position: 'relative',
        zIndex: 1,
      }}>

        {/* TOPBAR */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '16px 16px 0',
        }}>
          <button
            onClick={() => navigate(-1)}
            style={{
              background: isGif ? 'rgba(255,255,255,0.2)' : 'var(--bg-card)',
              border: isGif ? '1px solid rgba(255,255,255,0.3)' : '1px solid var(--border-light)',
              borderRadius: 999,
              width: 36, height: 36,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              backdropFilter: isGif ? 'blur(8px)' : 'none',
            }}
          >
            <ArrowLeft size={18} color={isGif ? 'white' : 'var(--text-primary)'} />
          </button>

          <span style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 17, fontWeight: 700,
            color: textPrimary,
            textShadow: isGif ? '0 1px 4px rgba(0,0,0,0.3)' : 'none',
          }}>
            Profile
          </span>

          {/* BG PICKER */}
          <div style={{
            display: 'flex',
            gap: 5,
          }}>
            {PROFILE_BACKGROUNDS.map(opt => (
              <motion.button
                key={opt.id}
                onClick={() => setProfileBg(opt.id)}
                whileTap={{ scale: 0.9 }}
                style={{
                  padding: '4px 10px',
                  borderRadius: 999,
                  fontSize: 10,
                  fontWeight: 700,
                  fontFamily: 'Inter',
                  border: profileBg === opt.id
                    ? isGif ? '2px solid white' : '2px solid var(--brand)'
                    : isGif ? '1px solid rgba(255,255,255,0.4)' : '1px solid var(--border)',
                  background: profileBg === opt.id
                    ? isGif ? 'rgba(255,255,255,0.3)' : 'var(--brand-light)'
                    : isGif ? 'rgba(0,0,0,0.25)' : 'var(--bg-card)',
                  color: isGif ? 'white' : profileBg === opt.id ? 'var(--brand)' : 'var(--text-secondary)',
                  cursor: 'pointer',
                  backdropFilter: isGif ? 'blur(8px)' : 'none',
                }}
              >
                {opt.label}
              </motion.button>
            ))}
          </div>
        </div>

        {/* AVATAR + NAME */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          padding: '28px 16px 24px',
          textAlign: 'center',
        }}>
          {/* Avatar with photo upload */}
          <div style={{ position: 'relative', marginBottom: 14 }}>
            <div style={{
              width: 88, height: 88,
              borderRadius: 999,
              background: avatarBg,
              backdropFilter: isGif ? 'blur(8px)' : 'none',
              border: avatarBorder,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              overflow: 'hidden',
            }}>
              {photo ? (
                <img
                  src={photo}
                  style={{
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover',
                  }}
                />
              ) : (
                <span style={{
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 32, fontWeight: 800,
                  color: 'white',
                  textShadow: isGif ? '0 1px 4px rgba(0,0,0,0.2)' : 'none',
                }}>
                  {initials}
                </span>
              )}
            </div>

            {/* Camera icon */}
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              id="photo-upload"
              style={{ display: 'none' }}
              onChange={handlePhotoChange}
            />
            <label
              htmlFor="photo-upload"
              style={{
                position: 'absolute',
                bottom: 0, right: 0,
                width: 28, height: 28,
                borderRadius: 999,
                background: isGif ? 'white' : 'var(--bg-card)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
                border: isGif ? 'none' : '1px solid var(--border-light)',
              }}
            >
              <Camera size={14} color="#D97757" />
            </label>
          </div>

          {/* NAME */}
          <h2 style={{
            fontFamily: 'Bricolage Grotesque',
            fontSize: 24, fontWeight: 800,
            color: textPrimary,
            margin: '0 0 4px',
            textShadow: isGif ? '0 2px 8px rgba(0,0,0,0.4)' : 'none',
            letterSpacing: -0.5,
          }}>
            {w.name || ''}
          </h2>

          {/* Zone */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: 5,
            marginBottom: 6,
          }}>
            <MapPin size={12} color={textSecondary} />
            <span style={{
              fontSize: 13, fontFamily: 'Inter',
              color: textSecondary,
            }}>
              {w.city || ''}
            </span>
          </div>

          {/* Phone */}
          <span style={{
            fontSize: 13, fontFamily: 'Inter', fontWeight: 500,
            color: textSecondary,
          }}>
            {(() => {
              const raw = w.phone || ''
              const clean = raw.replace(/^\+91/, '').replace(/^91/, '').replace(/\s/g, '').slice(-10)
              return clean ? `+91 ${clean}` : ''
            })()}
          </span>

          {/* Stats row */}
          <div style={{
            display: 'flex',
            gap: 1,
            marginTop: 20,
            background: cardBg,
            backdropFilter: isGif ? 'blur(12px)' : 'none',
            border: cardBorder,
            borderRadius: 16,
            overflow: 'hidden',
            width: '100%',
            maxWidth: 320,
          }}>
            {[
              { label: 'Protected', value: realStats ? formatINR(realStats.total_payouts) : '₹0' },
              { label: 'Claims', value: realStats ? String(realStats.total_claims) : '0' },
              { label: 'Paid', value: realStats ? String(realStats.paid_claims || 0) : '0' },
            ].map((stat, i) => (
              <div key={i} style={{
                flex: 1,
                padding: '14px 8px',
                textAlign: 'center',
                borderRight: i < 2
                  ? isGif ? '1px solid rgba(255,255,255,0.15)' : '1px solid var(--border-light)'
                  : 'none',
              }}>
                <p style={{
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 18, fontWeight: 800,
                  color: textPrimary, margin: '0 0 2px',
                }}>
                  {stat.value}
                </p>
                <p style={{
                  fontSize: 10, fontFamily: 'Inter',
                  color: textTertiary,
                  margin: 0, fontWeight: 600,
                  textTransform: 'uppercase',
                  letterSpacing: '0.5px',
                }}>
                  {stat.label}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* SETTINGS SECTIONS */}
        <div style={{ padding: '0 16px' }}>
          {SECTIONS.map(section => (
            <div key={section.title} style={{ marginBottom: 16 }}>
              <p style={{
                fontSize: 11, fontWeight: 700,
                fontFamily: 'Inter',
                color: textMuted,
                letterSpacing: '2px',
                textTransform: 'uppercase',
                margin: '0 4px 8px',
              }}>
                {section.title}
              </p>
              <div style={{
                background: cardBg,
                backdropFilter: isGif ? 'blur(16px)' : 'none',
                border: cardBorder,
                borderRadius: 14,
                overflow: 'hidden',
              }}>
                {section.items.map((item, i) => {
                  const Icon = item.icon
                  return (
                    <motion.div
                      key={i}
                      onClick={item.action}
                      whileTap={{ opacity: 0.7 }}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 12,
                        padding: '14px 16px',
                        borderBottom: i < section.items.length - 1
                          ? isGif ? '1px solid rgba(255,255,255,0.1)' : '1px solid var(--border-light)'
                          : 'none',
                        cursor: item.action ? 'pointer' : 'default',
                      }}
                    >
                      <div style={{
                        width: 36, height: 36,
                        borderRadius: 10,
                        background: iconBg,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                      }}>
                        <Icon size={17} color={iconColor} />
                      </div>
                      <div style={{ flex: 1 }}>
                        <p style={{
                          fontSize: 14, fontWeight: 600,
                          fontFamily: 'Inter',
                          color: textPrimary, margin: 0,
                        }}>
                          {item.label}
                        </p>
                        {item.sub && (
                          <p style={{
                            fontSize: 12, fontFamily: 'Inter',
                            color: textTertiary,
                            margin: '2px 0 0',
                          }}>
                            {item.sub}
                          </p>
                        )}
                      </div>
                      {item.right || (
                        item.action && (
                          <ChevronRight size={16}
                            color={isGif ? 'rgba(255,255,255,0.4)' : 'var(--text-disabled)'} />
                        )
                      )}
                    </motion.div>
                  )
                })}
              </div>
            </div>
          ))}

          {/* Language dropdown */}
          {showLangMenu && (
            <motion.div
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              style={{
                background: cardBg,
                backdropFilter: isGif ? 'blur(16px)' : 'none',
                border: cardBorder,
                borderRadius: 14,
                overflow: 'hidden',
                marginBottom: 16,
              }}
            >
              {[
                { code: 'en', label: 'English', native: 'English' },
                { code: 'hi', label: 'Hindi', native: 'हिन्दी' },
                { code: 'te', label: 'Telugu', native: 'తెలుగు' },
                { code: 'ta', label: 'Tamil', native: 'தமிழ்' },
              ].map((lang, i, arr) => (
                <motion.div
                  key={lang.code}
                  onClick={() => { setSelectedLang(lang.code); setShowLangMenu(false) }}
                  whileTap={{ opacity: 0.7 }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '12px 16px',
                    cursor: 'pointer',
                    borderBottom: i < arr.length - 1
                      ? isGif ? '1px solid rgba(255,255,255,0.1)' : '1px solid var(--border-light)'
                      : 'none',
                    background: selectedLang === lang.code ? 'rgba(217,119,87,0.1)' : 'transparent',
                  }}
                >
                  <div>
                    <p style={{ fontSize: 14, fontWeight: 600, fontFamily: 'Inter', color: textPrimary, margin: 0 }}>
                      {lang.native}
                    </p>
                    <p style={{ fontSize: 11, fontFamily: 'Inter', color: textTertiary, margin: '2px 0 0' }}>
                      {lang.label}
                    </p>
                  </div>
                  {selectedLang === lang.code && (
                    <span style={{ fontSize: 14, color: '#D97757', fontWeight: 700 }}>✓</span>
                  )}
                </motion.div>
              ))}
            </motion.div>
          )}

          {/* Sign out */}
          <motion.button
            onClick={handleSignOut}
            whileTap={{ scale: 0.97 }}
            style={{
              width: '100%',
              padding: '14px',
              borderRadius: 12,
              border: '1px solid rgba(240,68,56,0.4)',
              background: 'rgba(240,68,56,0.15)',
              color: '#FF6B6B',
              fontSize: 14, fontWeight: 700,
              fontFamily: 'Inter', cursor: 'pointer',
              marginBottom: 16,
              backdropFilter: isGif ? 'blur(8px)' : 'none',
            }}
          >
            Sign out
          </motion.button>

          <p style={{
            textAlign: 'center',
            fontSize: 11,
            color: textMuted,
            fontFamily: 'Inter',
            paddingBottom: 20,
          }}>
            GuidePay v2.0 · Team SentinelX · KL University
          </p>
        </div>
      </div>
    </div>
  )
}
