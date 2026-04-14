import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ShieldCheck, Menu, X } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

const NAV_LINKS = [
  { label: 'How it works', href: '#how-it-works' },
  { label: 'Coverage', href: '#coverage' },
  { label: 'Pricing', href: '#pricing' },
  { label: 'For workers', href: '#workers' },
]

const navStyles = `
  @media (max-width: 768px) {
    .nav-links-desktop { display: none !important; }
    .nav-cta-desktop { display: none !important; }
    .nav-hamburger { display: flex !important; }
  }
  @media (min-width: 769px) {
    .nav-hamburger { display: none !important; }
  }
`

export const LandingNav = () => {
  const navigate = useNavigate()
  const [scrolled, setScrolled] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 60)
    window.addEventListener('scroll', fn, { passive: true })
    return () => window.removeEventListener('scroll', fn)
  }, [])

  return (
    <>
      <style>{navStyles}</style>
      {/* NAVBAR WRAPPER — full width fixed */}
      <div style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 500,
        display: 'flex',
        justifyContent: 'center',
        padding: scrolled ? '12px 20px' : '20px 20px',
        transition: 'padding 0.3s ease',
        pointerEvents: 'none',
      }}>
        {/* PILL NAV — centered, not full width */}
        <motion.nav
          style={{
            pointerEvents: 'all',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 8,
            maxWidth: 900,
            width: '100%',
            height: 52,
            padding: '0 8px 0 16px',
            borderRadius: 999,
            // GLASSMORPHISM — always, not just after scroll
            background: scrolled
              ? 'rgba(255,255,255,0.18)'
              : 'rgba(255,255,255,0.1)',
            backdropFilter: 'blur(20px)',
            WebkitBackdropFilter: 'blur(20px)',
            border: scrolled
              ? '1px solid rgba(255,255,255,0.35)'
              : '1px solid rgba(255,255,255,0.2)',
            boxShadow: scrolled
              ? '0 8px 32px rgba(0,0,0,0.12)'
              : '0 4px 16px rgba(0,0,0,0.08)',
            transition: 'all 0.3s ease',
          }}
        >
          {/* LEFT: Logo */}
          <motion.div
            onClick={() => navigate('/')}
            whileTap={{ scale: 0.96 }}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              cursor: 'pointer',
              flexShrink: 0,
            }}
          >
            <span style={{ fontFamily: 'Barlow, sans-serif', fontSize: 24, fontWeight: 400, color: '#D97757', letterSpacing: '-0.02em' }}>
              GuidePay
            </span>
          </motion.div>

          {/* CENTER: Nav links — desktop */}
          <div
            className="nav-links-desktop"
            style={{
              alignItems: 'center',
              gap: 0,
              flex: 1,
              justifyContent: 'center',
            }}
          >
            {NAV_LINKS.map(link => (
              <motion.a
                key={link.label}
                href={link.href}
                whileHover={{
                  background: 'rgba(255,255,255,0.15)',
                }}
                style={{
                  padding: '6px 14px',
                  borderRadius: 999,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: 500,
                  color: 'rgba(255,255,255,0.9)',
                  textDecoration: 'none',
                  transition: 'background 0.15s',
                  whiteSpace: 'nowrap',
                }}
              >
                {link.label}
              </motion.a>
            ))}
          </div>

          {/* RIGHT: CTAs */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            flexShrink: 0,
          }}>
            <motion.button
              onClick={() => navigate('/login')}
              className="nav-cta-desktop"
              whileTap={{ scale: 0.96 }}
              style={{
                padding: '7px 14px',
                borderRadius: 999,
                border: '1px solid rgba(255,255,255,0.3)',
                background: 'transparent',
                fontSize: 13,
                fontWeight: 600,
                fontFamily: 'Inter',
                color: 'rgba(255,255,255,0.9)',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
              }}
            >
              Sign in
            </motion.button>

            <motion.button
              onClick={() => navigate('/register')}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.96 }}
              style={{
                padding: '8px 16px',
                borderRadius: 999,
                border: 'none',
                background: 'white',
                fontSize: 13,
                fontWeight: 700,
                fontFamily: 'Inter',
                color: '#D97757',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                boxShadow: '0 2px 12px rgba(0,0,0,0.15)',
                animation: 'pulseGlow 2s ease-in-out infinite',
                position: 'relative',
              }}
            >
              {/* Green notification dot */}
              <span style={{
                position: 'absolute',
                top: -2, right: -2,
                width: 8, height: 8,
                borderRadius: 999,
                background: '#12B76A',
                border: '1.5px solid white',
                animation: 'pulse 2s ease-in-out infinite',
              }} />
              Get protected →
            </motion.button>

            {/* Mobile hamburger */}
            <motion.button
              className="nav-hamburger"
              onClick={() => setMobileOpen(true)}
              whileTap={{ scale: 0.9 }}
              style={{
                background: 'rgba(255,255,255,0.15)',
                border: '1px solid rgba(255,255,255,0.25)',
                borderRadius: 999,
                width: 36, height: 36,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Menu size={18} color="white" />
            </motion.button>
          </div>
        </motion.nav>
      </div>

      {/* MOBILE DRAWER */}
      <AnimatePresence>
        {mobileOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileOpen(false)}
              style={{
                position: 'fixed', inset: 0,
                background: 'rgba(0,0,0,0.5)',
                zIndex: 600,
                backdropFilter: 'blur(4px)',
              }}
            />
            <motion.div
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{
                type: 'spring', stiffness: 300, damping: 35
              }}
              style={{
                position: 'fixed',
                top: 0, right: 0, bottom: 0,
                width: 280,
                background: 'rgba(15,15,15,0.95)',
                backdropFilter: 'blur(20px)',
                border: '1px solid rgba(255,255,255,0.1)',
                zIndex: 700,
                padding: 20,
                display: 'flex',
                flexDirection: 'column',
              }}
            >
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 32,
              }}>
                <span style={{ fontFamily: 'Barlow, sans-serif', fontSize: 24, fontWeight: 800, color: 'white', letterSpacing: '-0.02em' }}>
                  GuidePay
                </span>
                <motion.button
                  onClick={() => setMobileOpen(false)}
                  whileTap={{ scale: 0.9 }}
                  style={{
                    background: 'rgba(255,255,255,0.1)',
                    border: 'none',
                    borderRadius: 999,
                    width: 32, height: 32,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <X size={16} color="white" />
                </motion.button>
              </div>

              {NAV_LINKS.map(link => (
                <a
                  key={link.label}
                  href={link.href}
                  onClick={() => setMobileOpen(false)}
                  style={{
                    padding: '14px 0',
                    borderBottom: '1px solid rgba(255,255,255,0.08)',
                    fontSize: 16,
                    fontWeight: 600,
                    fontFamily: 'Inter',
                    color: 'rgba(255,255,255,0.85)',
                    textDecoration: 'none',
                    display: 'block',
                  }}
                >
                  {link.label}
                </a>
              ))}

              <div style={{
                marginTop: 'auto',
                display: 'flex',
                flexDirection: 'column',
                gap: 10,
              }}>
                <motion.button
                  onClick={() => {
                    navigate('/login')
                    setMobileOpen(false)
                  }}
                  whileTap={{ scale: 0.97 }}
                  style={{
                    width: '100%', padding: '13px',
                    borderRadius: 10,
                    border: '1px solid rgba(255,255,255,0.2)',
                    background: 'transparent',
                    fontSize: 15, fontWeight: 600,
                    fontFamily: 'Inter',
                    color: 'white', cursor: 'pointer',
                  }}
                >
                  Sign in
                </motion.button>
                <motion.button
                  onClick={() => {
                    navigate('/register')
                    setMobileOpen(false)
                  }}
                  whileTap={{ scale: 0.97 }}
                  style={{
                    width: '100%', padding: '13px',
                    borderRadius: 10,
                    border: 'none',
                    background: 'white',
                    fontSize: 15, fontWeight: 700,
                    fontFamily: 'Inter',
                    color: '#D97757', cursor: 'pointer',
                  }}
                >
                  Get protected →
                </motion.button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  )
}

export default LandingNav
