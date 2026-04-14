import { ShieldCheck, Github, Linkedin, Youtube, ArrowUpRight } from 'lucide-react'
import { motion } from 'framer-motion'

const FOOTER_LINKS = {
  Product: [
    { label: 'How it works',    href: '#how-it-works' },
    { label: 'Coverage',        href: '#coverage' },
    { label: 'Pricing',         href: '#pricing' },
    { label: 'AI Forecast',     href: '#forecast' },
    { label: 'Fraud protection',href: '#fraud' },
  ],
  Company: [
    { label: 'About SentinelX', href: '#about' },
    { label: 'DEVTrails 2026',  href: 'https://guidewire.com/devtrails', external: true },
    { label: 'KL University',   href: 'https://kluniversity.in', external: true },
  ],
  Legal: [
    { label: 'Privacy Policy',   href: '/privacy' },
    { label: 'Terms of Service', href: '/terms' },
    { label: 'Cookie Policy',    href: '#' },
  ],
  Support: [
    { label: 'Help center', href: '#' },
    { label: 'Contact us',  href: '#' },
    { label: 'FAQ',         href: '#' },
  ],
}

const SOCIAL = [
  { label: 'GitHub',   icon: Github,   href: 'https://github.com/karthikeyavelivela' },
  { label: 'LinkedIn', icon: Linkedin, href: 'https://linkedin.com/in/karthikeya-velivela' },
  { label: 'YouTube',  icon: Youtube,  href: 'https://youtube.com' },
]

export const LandingFooter = () => (
  <footer style={{ background: '#0F0F0F', color: 'white', paddingTop: 64 }}>
    <div style={{ maxWidth: 1100, margin: '0 auto', padding: '0 max(20px, 5vw)' }}>

      {/* TOP ROW */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
        gap: 40,
        paddingBottom: 48,
        borderBottom: '1px solid rgba(255,255,255,0.08)',
      }}>

        {/* Brand column */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'linear-gradient(135deg, #D97757, #B85C3A)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <ShieldCheck size={16} color="white" />
            </div>
            <span style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 18, fontWeight: 800, color: 'white' }}>
              GuidePay
            </span>
          </div>
          <p style={{
            fontSize: 13, color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter, sans-serif',
            lineHeight: 1.6, marginBottom: 20, maxWidth: 220,
          }}>
            Parametric income insurance for India's 12 million gig delivery workers.
          </p>
          <div style={{ display: 'flex', gap: 10 }}>
            {SOCIAL.map(({ label, icon: Icon, href }) => (
              <motion.a
                key={label}
                href={href}
                target="_blank"
                rel="noreferrer"
                whileHover={{ y: -2 }}
                whileTap={{ scale: 0.9 }}
                style={{
                  width: 36, height: 36, borderRadius: 8,
                  border: '1px solid rgba(255,255,255,0.12)',
                  background: 'rgba(255,255,255,0.05)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: 'rgba(255,255,255,0.7)', textDecoration: 'none',
                }}
              >
                <Icon size={16} />
              </motion.a>
            ))}
          </div>
        </div>

        {/* Link columns */}
        {Object.entries(FOOTER_LINKS).map(([title, links]) => (
          <div key={title}>
            <p style={{
              fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif',
              color: 'rgba(255,255,255,0.4)', letterSpacing: '1.5px',
              textTransform: 'uppercase', marginBottom: 16,
            }}>
              {title}
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {links.map(link => (
                <motion.a
                  key={link.label}
                  href={link.href}
                  target={link.external ? '_blank' : undefined}
                  rel={link.external ? 'noreferrer' : undefined}
                  whileHover={{ x: 2 }}
                  style={{
                    fontSize: 13, color: 'rgba(255,255,255,0.6)',
                    fontFamily: 'Inter, sans-serif', textDecoration: 'none',
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                  }}
                >
                  {link.label}
                  {link.external && <ArrowUpRight size={11} style={{ opacity: 0.5 }} />}
                </motion.a>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* SENTINELX BOTTOM BAND */}
      <div style={{ padding: '24px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
        <p style={{
          fontFamily: 'Bricolage Grotesque, sans-serif',
          fontSize: 'clamp(48px, 10vw, 120px)',
          fontWeight: 800,
          color: 'rgba(255,255,255,0.04)',
          letterSpacing: -4,
          margin: 0, lineHeight: 1,
          userSelect: 'none', textAlign: 'center', width: '100%',
        }}>
          SENTINELX
        </p>

        <div style={{
          display: 'flex', alignItems: 'center',
          justifyContent: 'space-between', width: '100%',
          flexWrap: 'wrap', gap: 8, paddingTop: 16,
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}>
          <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.25)', fontFamily: 'Inter, sans-serif', margin: 0 }}>
            © 2026 GuidePay by Team SentinelX · KL University, Vijayawada · Guidewire DEVTrails 2026
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 6, height: 6, borderRadius: 999, background: '#12B76A' }} />
            <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.25)', fontFamily: 'Inter, sans-serif', margin: 0 }}>
              Phase 2 live · April 2026
            </p>
          </div>
        </div>
      </div>
    </div>
  </footer>
)

export default LandingFooter
