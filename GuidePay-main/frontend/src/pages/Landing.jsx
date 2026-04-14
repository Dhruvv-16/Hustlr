import { motion } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { LandingNav } from '../components/layout/LandingNav'
import { LandingFooter } from '../components/layout/LandingFooter'

// ── Video background for hero ──────────────────────────────────────────
const VideoBackground = () => (
  <div style={{ position: 'absolute', inset: 0, zIndex: 0, overflow: 'hidden' }}>
    <video
      autoPlay muted loop playsInline
      style={{
        position: 'absolute',
        top: '50%', left: '50%',
        transform: 'translate(-50%, -50%)',
        minWidth: '100%', minHeight: '100%',
        objectFit: 'cover', opacity: 0.35,
      }}
    >
      <source
        src="https://res.cloudinary.com/dqwm8wgg8/video/upload/v1774194675/m3wmgks3mlvhur17jybt.mp4"
        type="video/mp4"
      />
    </video>
    <div style={{
      position: 'absolute', inset: 0,
      background: 'linear-gradient(180deg, rgba(15,15,15,0.55) 0%, rgba(15,15,15,0.7) 60%, rgba(15,15,15,0.85) 100%)',
    }} />
  </div>
)

// ── AI News data ───────────────────────────────────────────────────────
const AI_NEWS = [
  { tag: '🌊 Flood',      color: '#2E90FA', title: 'IMD Red Alert — Hyderabad flooding',           source: 'IMD SACHET',    time: 'Live',      impact: '32 workers auto-covered' },
  { tag: '📱 Outage',     color: '#F79009', title: 'Zepto app down — Mumbai zone',                 source: 'Downdetector',  time: '2h ago',    impact: '18 payout claims processed' },
  { tag: '🚫 Curfew',     color: '#7C3AED', title: 'Section 144 — North Bengaluru',               source: 'District Admin', time: '5h ago',    impact: '9 workers covered' },
  { tag: '🌧️ Alert',      color: '#2E90FA', title: 'Orange alert — Chennai coastal zones',         source: 'IMD SACHET',    time: '8h ago',    impact: '14 workers pre-covered' },
  { tag: '⚡ Outage',     color: '#F79009', title: 'Swiggy partial outage — Delhi',               source: 'Downdetector',  time: '12h ago',   impact: 'Monitoring active' },
  { tag: '🔬 Research',   color: '#D97757', title: '12M gig workers face zero income protection', source: 'NASSCOM 2024',  time: '3 days ago', impact: 'The problem we solve' },
]

const NewsCard = ({ item }) => (
  <div style={{
    width: 260, flexShrink: 0,
    background: 'white', borderRadius: 16,
    padding: '16px 18px',
    boxShadow: '0 2px 16px rgba(0,0,0,0.06)',
    border: '1px solid #F4F4F5',
  }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
      <span style={{
        fontSize: 11, fontWeight: 700, fontFamily: 'Inter, sans-serif',
        color: item.color, background: `${item.color}15`,
        padding: '3px 8px', borderRadius: 999,
      }}>{item.tag}</span>
      <span style={{ fontSize: 10, color: '#9B9B9B', fontFamily: 'Inter, sans-serif' }}>{item.time}</span>
    </div>
    <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', margin: '0 0 8px', lineHeight: 1.4 }}>{item.title}</p>
    <p style={{ fontSize: 11, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', margin: '0 0 10px' }}>{item.source}</p>
    <div style={{ background: '#FDF1ED', borderRadius: 8, padding: '6px 10px', display: 'flex', gap: 6 }}>
      <span style={{ fontSize: 10 }}>🛡️</span>
      <p style={{ fontSize: 11, color: '#B85C3A', fontFamily: 'Inter, sans-serif', fontWeight: 600, margin: 0 }}>{item.impact}</p>
    </div>
  </div>
)

const NewsRow = ({ items, direction = -1 }) => (
  <div style={{ overflow: 'hidden', marginBottom: 16 }}>
    <motion.div
      style={{ display: 'flex', gap: 16, width: 'max-content' }}
      animate={{ x: direction === -1 ? ['0%', '-50%'] : ['-50%', '0%'] }}
      transition={{ duration: 35, repeat: Infinity, ease: 'linear' }}
    >
      {[...items, ...items].map((item, i) => <NewsCard key={i} item={item} />)}
    </motion.div>
  </div>
)

// ── Pricing plans ──────────────────────────────────────────────────────
const PLANS = [
  {
    name: 'Daily Shield', price: 12, period: 'day', badge: 'MOST AFFORDABLE', badgeColor: 'green',
    zone: 'Perfect for workers who want flexible daily protection',
    features: ['24-hour protection window', 'Income-based payout (₹400–₹900)', 'All 5 trigger types covered', 'Instant UPI payout'],
    cta: 'Get Daily →',
  },
  {
    name: 'Basic', price: 49, period: 'week', zone: 'Low risk zone', popular: false,
    features: ['Up to ₹600/week coverage', 'IMD flood trigger', 'Platform outage trigger', 'Govt curfew trigger', 'UPI instant payout', 'AI 24h flood forecast', 'Basic risk score'],
    cta: 'Get Basic',
  },
  {
    name: 'Standard', price: 62, period: 'week', badge: 'MOST POPULAR', badgeColor: 'orange', zone: 'Medium risk zone', popular: true,
    features: ['Up to ₹600/week coverage', 'All 3 triggers included', 'UPI instant payout < 2hrs', 'AI 24h flood forecast', 'Worker risk score tracking', 'Activity verification', 'Priority claim review', 'Flood alert notifications'],
    cta: 'Get Standard →',
  },
  {
    name: 'Premium', price: 89, period: 'week', zone: 'High risk zone', popular: false,
    features: ['Up to ₹600/week coverage', 'All 3 triggers included', 'UPI instant payout < 1hr', 'AI 7-day forecast', 'Auto coverage extension', 'Priority fraud protection', 'Dedicated claim tracking', 'WhatsApp alerts', '24/7 support priority'],
    cta: 'Get Premium',
  },
]

// ── Main Landing ───────────────────────────────────────────────────────
const Landing = () => {
  const navigate = useNavigate()

  return (
    <div style={{ minHeight: '100vh', background: '#FAFAFA' }}>
      <LandingNav />

      {/* ── HERO ── */}
      <section style={{
        position: 'relative', minHeight: '100vh',
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        textAlign: 'center', padding: '100px max(20px, 5vw) 80px',
        overflow: 'hidden',
        background: 'linear-gradient(135deg, #1a0a00 0%, #0F0F0F 50%, #0a0a1a 100%)',
      }}>
        <VideoBackground />

        <div style={{ position: 'relative', zIndex: 1, maxWidth: 900, width: '100%' }}>
          {/* LIVE badge */}
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            style={{
              display: 'inline-flex', alignItems: 'center', gap: 8,
              background: 'rgba(255,255,255,0.15)',
              backdropFilter: 'blur(12px)',
              border: '1px solid rgba(255,255,255,0.25)',
              borderRadius: 999, padding: '6px 16px 6px 8px',
              marginBottom: 28,
            }}
          >
            <span style={{
              background: '#12B76A', color: 'white',
              fontSize: 10, fontWeight: 700, fontFamily: 'Inter, sans-serif',
              padding: '2px 8px', borderRadius: 999, letterSpacing: '0.5px',
            }}>LIVE</span>
            <span style={{ fontSize: 13, fontFamily: 'Inter, sans-serif', fontWeight: 500, color: 'white' }}>
              Guidewire DEVTrails 2026 · Team SentinelX
            </span>
          </motion.div>

          {/* Headline */}
          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.15, type: 'spring', stiffness: 200, damping: 25 }}
            style={{
              fontFamily: 'Bricolage Grotesque, sans-serif',
              fontSize: 'clamp(40px, 7vw, 80px)',
              fontWeight: 800, color: 'white',
              lineHeight: 1.05, letterSpacing: -2,
              maxWidth: 900, margin: '0 auto 24px',
              textShadow: '0 2px 40px rgba(0,0,0,0.3)',
            }}
          >
            India's delivery workers<br />
            <span style={{
              background: 'linear-gradient(135deg, #FFD700, #FFA040)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}>
              deserve a safety net.
            </span>
          </motion.h1>

          {/* Sub */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
            style={{
              fontSize: 'clamp(16px, 2.5vw, 20px)',
              color: 'rgba(255,255,255,0.8)',
              fontFamily: 'Inter, sans-serif', lineHeight: 1.6,
              maxWidth: 540, margin: '0 auto 40px', fontWeight: 400,
            }}
          >
            GuidePay automatically protects your income during floods, outages, and curfews — so you can keep delivering with confidence.
          </motion.p>

          {/* CTAs */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.35 }}
            style={{ display: 'flex', gap: 12, flexWrap: 'wrap', justifyContent: 'center' }}
          >
            <motion.button
              onClick={() => navigate('/register')}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.97 }}
              style={{
                padding: '15px 32px', borderRadius: 12, border: 'none',
                background: 'linear-gradient(135deg, #D97757, #B85C3A)',
                color: 'white', fontSize: 16, fontWeight: 700,
                fontFamily: 'Inter, sans-serif', cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 8,
                boxShadow: '0 4px 24px rgba(217,119,87,0.45)',
              }}
            >
              Get protected for ₹49/week <ArrowRight size={18} />
            </motion.button>
            <motion.button
              onClick={() => document.getElementById('how-it-works')?.scrollIntoView({ behavior: 'smooth' })}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.97 }}
              style={{
                padding: '15px 32px', borderRadius: 12,
                border: '1.5px solid rgba(255,255,255,0.3)',
                background: 'rgba(255,255,255,0.1)',
                backdropFilter: 'blur(8px)',
                color: 'white', fontSize: 16, fontWeight: 600,
                fontFamily: 'Inter, sans-serif', cursor: 'pointer',
              }}
            >
              See how it works
            </motion.button>
          </motion.div>

          {/* Trust signals */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            style={{ display: 'flex', gap: 24, justifyContent: 'center', flexWrap: 'wrap', marginTop: 32 }}
          >
            {['🔒 UPI instant payout', '⚡ Under 2 hours', '📋 Zero claims to file'].map(t => (
              <span key={t} style={{ fontSize: 13, color: 'rgba(255,255,255,0.6)', fontFamily: 'Inter, sans-serif' }}>{t}</span>
            ))}
          </motion.div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.6 }}
            style={{ display: 'flex', gap: 'clamp(24px, 5vw, 64px)', flexWrap: 'wrap', justifyContent: 'center', marginTop: 48 }}
          >
            {[
              { value: '12M+', label: 'Workers uninsured' },
              { value: '₹4,200Cr', label: 'Annual income lost' },
              { value: '< 2hrs', label: 'Payout speed' },
              { value: '₹0', label: 'Claims to file' },
            ].map((stat, i) => (
              <div key={i} style={{ textAlign: 'center' }}>
                <p style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(24px, 3vw, 32px)', fontWeight: 800, color: 'white', margin: 0 }}>{stat.value}</p>
                <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter, sans-serif', margin: '4px 0 0' }}>{stat.label}</p>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* ── PROBLEM SECTION — dark ── */}
      <section style={{ background: '#0F0F0F', padding: 'clamp(80px,10vw,120px) max(24px,8vw)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto' }}>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            style={{ marginBottom: 64 }}
          >
            <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '3px', textTransform: 'uppercase', marginBottom: 16 }}>
              The problem
            </p>
            <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(32px,5vw,56px)', fontWeight: 800, color: 'white', letterSpacing: -1.5, lineHeight: 1.1, maxWidth: 700, margin: 0 }}>
              12 million workers.
              <span style={{ color: '#6B6B6B' }}> Zero protection.</span>
            </h2>
          </motion.div>

          {/* Stat cards */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 2, marginBottom: 80 }}>
            {[
              { number: '12M+',     label: 'Uninsured workers',    sub: 'Across Zepto, Swiggy, Blinkit, Amazon', color: '#D97757', bg: 'rgba(217,119,87,0.08)', r: '16px 0 0 16px' },
              { number: '₹640',     label: 'Lost per flood day',   sub: 'Average daily income wiped out',          color: '#F04438', bg: 'rgba(240,68,56,0.08)',  r: 0 },
              { number: '₹4,200Cr', label: 'Annual income lost',   sub: 'Uninsured exposure across India',         color: '#F79009', bg: 'rgba(247,144,9,0.08)',  r: 0 },
              { number: '0',        label: 'Products exist',       sub: 'No parametric insurance for gig workers', color: '#9B9B9B', bg: 'rgba(155,155,155,0.08)', r: '0 16px 16px 0' },
            ].map((stat, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                whileHover={{ background: stat.bg, borderColor: `${stat.color}30` }}
                style={{
                  padding: 32,
                  border: '1px solid rgba(255,255,255,0.06)',
                  borderRadius: stat.r,
                  transition: 'all 0.2s',
                }}
              >
                <p style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 52, fontWeight: 800, color: stat.color, margin: '0 0 8px', letterSpacing: -2, lineHeight: 1 }}>{stat.number}</p>
                <p style={{ fontSize: 16, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: 'white', margin: '0 0 6px' }}>{stat.label}</p>
                <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.4)', fontFamily: 'Inter, sans-serif', margin: 0, lineHeight: 1.5 }}>{stat.sub}</p>
              </motion.div>
            ))}
          </div>

          {/* Ravi's story */}
          <motion.div
            initial={{ opacity: 0, scale: 0.97 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            style={{
              background: 'linear-gradient(135deg, #1a0a00, #0F0F0F)',
              border: '1px solid rgba(217,119,87,0.2)',
              borderRadius: 20, padding: 'clamp(32px,5vw,56px)',
              position: 'relative', overflow: 'hidden',
            }}
          >
            <div style={{ position: 'absolute', top: 20, right: 32, fontSize: 180, fontFamily: 'Georgia', color: 'rgba(217,119,87,0.05)', lineHeight: 1, userSelect: 'none' }}>"</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr', gap: 32, alignItems: 'center', position: 'relative', zIndex: 1 }}>
              <div style={{ width: 72, height: 72, borderRadius: 999, background: 'linear-gradient(135deg, #D97757, #B85C3A)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 36, flexShrink: 0 }}>🛵</div>
              <div>
                <p style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(18px,3vw,26px)', fontWeight: 700, color: 'white', lineHeight: 1.4, margin: '0 0 16px' }}>
                  "July 2024. IMD issues Red Alert. Zepto suspends ops. I lose ₹640 in one day with zero recourse."
                </p>
                <p style={{ fontSize: 14, fontFamily: 'Inter, sans-serif', color: 'rgba(255,255,255,0.5)', margin: 0 }}>
                  Ravi Kumar, 27 · Delivery partner · Kondapur, Hyderabad
                </p>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* ── SOLUTION — bento grid ── */}
      <section id="coverage" style={{ background: 'white', padding: 'clamp(80px,10vw,120px) max(24px,8vw)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto' }}>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            style={{ textAlign: 'center', marginBottom: 64 }}
          >
            <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '3px', textTransform: 'uppercase', marginBottom: 16 }}>
              The solution
            </p>
            <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(32px,5vw,52px)', fontWeight: 800, color: '#0F0F0F', letterSpacing: -1.5, lineHeight: 1.1, marginBottom: 16 }}>
              Auto-pays before Ravi<br />knows it happened.
            </h2>
            <p style={{ fontSize: 18, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', maxWidth: 480, margin: '0 auto', lineHeight: 1.6 }}>
              GuidePay monitors 24/7. Detects. Verifies. Pays. Zero action needed from you.
            </p>
          </motion.div>

          {/* Bento grid */}
          <div className="grid grid-cols-1 md:grid-cols-12 gap-4">

            {/* Large left — payout flow */}
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              whileHover={{ y: -4 }}
              className="md:col-span-7"
              style={{ background: '#0F0F0F', borderRadius: 20, padding: 36, overflow: 'hidden', position: 'relative' }}
            >
              <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '2px', textTransform: 'uppercase', marginBottom: 12 }}>Zero-touch payout flow</p>
              <h3 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 28, fontWeight: 800, color: 'white', marginBottom: 8, letterSpacing: -0.5 }}>₹600 in 2 hours.<br />No claim filed.</h3>
              <p style={{ fontSize: 14, color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter, sans-serif', marginBottom: 32, lineHeight: 1.5 }}>From flood alert to UPI credit — fully automated.</p>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
                {[
                  { label: 'Trigger detected',   sub: 'IMD Red Alert · Kondapur', time: '2:19 PM', done: true },
                  { label: 'Activity verified',  sub: 'Last order 38 min ago',    time: '2:20 PM', done: true },
                  { label: 'Fraud check passed', sub: 'Score 0.04 · Auto approved', time: '2:21 PM', done: true },
                  { label: '₹600 to your UPI',  sub: 'ravi.kumar@okaxis',         time: '4:16 PM', done: false, active: true },
                ].map((step, i) => (
                  <div key={i} style={{ display: 'flex', gap: 14, paddingBottom: 16, position: 'relative' }}>
                    {i < 3 && <div style={{ position: 'absolute', left: 11, top: 24, bottom: 0, width: 1, background: step.done ? 'rgba(18,183,106,0.4)' : 'rgba(255,255,255,0.08)' }} />}
                    <div style={{ width: 24, height: 24, borderRadius: 999, background: step.done ? '#12B76A' : step.active ? '#D97757' : 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, zIndex: 1 }}>
                      {step.done ? <span style={{ fontSize: 11, color: 'white' }}>✓</span> : step.active ? (
                        <motion.div animate={{ scale: [1, 1.3, 1] }} transition={{ duration: 1, repeat: Infinity }} style={{ width: 8, height: 8, borderRadius: 999, background: 'white' }} />
                      ) : null}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                        <p style={{ fontSize: 14, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: step.active ? '#D97757' : step.done ? 'white' : 'rgba(255,255,255,0.3)', margin: '0 0 2px' }}>{step.label}</p>
                        <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', fontFamily: 'Inter, sans-serif' }}>{step.time}</span>
                      </div>
                      <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.3)', fontFamily: 'Inter, sans-serif', margin: 0 }}>{step.sub}</p>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* Right top — Premium pricing */}
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.1 }}
              whileHover={{ y: -4 }}
              className="md:col-span-5"
              style={{ background: '#FDF1ED', borderRadius: 20, padding: 28, display: 'flex', flexDirection: 'column' }}
            >
              <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '2px', textTransform: 'uppercase', marginBottom: 16 }}>Weekly premium</p>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginBottom: 8 }}>
                <span style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 72, fontWeight: 800, color: '#0F0F0F', letterSpacing: -3, lineHeight: 1 }}>₹49</span>
                <span style={{ fontSize: 16, color: '#9B9B9B', fontFamily: 'Inter, sans-serif' }}>/week</span>
              </div>
              <p style={{ fontSize: 14, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', margin: '0 0 20px', flex: 1, lineHeight: 1.6 }}>
                Behavior-based pricing. Active workers get up to 15% discount.
              </p>
              <div style={{ background: 'white', borderRadius: 12, padding: '12px 14px' }}>
                <p style={{ fontSize: 12, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', margin: '0 0 4px' }}>Coverage cap</p>
                <p style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 24, fontWeight: 800, color: '#D97757', margin: 0 }}>₹600 / week</p>
              </div>
            </motion.div>

            {/* Bottom row — 3 trigger cards */}
            {[
              { icon: '🌊', title: 'IMD Flood Alerts',    desc: 'Official govt source. Red/Orange alert in your zone = 100% payout.',                    bg: '#EFF8FF', iconBg: '#DBEAFE' },
              { icon: '📱', title: 'Platform Outages',    desc: 'Zepto down? Swiggy offline? Dual-verified via Downdetector + status API.',              bg: '#FFFAEB', iconBg: '#FEF3C7' },
              { icon: '🚫', title: 'Govt Curfews',        desc: 'Section 144 in your area. District admin API + news verification.',                      bg: '#F0FDF4', iconBg: '#DCFCE7' },
            ].map((card, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                whileHover={{ y: -4 }}
                className="md:col-span-4"
                style={{ background: card.bg, borderRadius: 20, padding: 24 }}
              >
                <div style={{ width: 48, height: 48, borderRadius: 12, background: card.iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, marginBottom: 16 }}>{card.icon}</div>
                <h3 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 18, fontWeight: 700, color: '#0F0F0F', marginBottom: 8 }}>{card.title}</h3>
                <p style={{ fontSize: 13, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', margin: 0, lineHeight: 1.5 }}>{card.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS — 5 steps ── */}
      <section id="how-it-works" style={{ background: '#FAFAFA', padding: 'clamp(80px,10vw,120px) max(24px,8vw)' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 64 }}>
            <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(32px,5vw,52px)', fontWeight: 800, color: '#0F0F0F', letterSpacing: -1.5 }}>
              From sign-up to payout<br />in minutes.
            </h2>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 0, position: 'relative' }}>
            {/* Connector line */}
            <div className="hidden md:block" style={{ position: 'absolute', top: 40, left: '10%', right: '10%', height: 1, background: 'linear-gradient(90deg, #D97757, #B85C3A)', zIndex: 0 }} />

            {[
              { step: '01', emoji: '📱', title: 'Sign up',     desc: 'Google login. No documents. 2 minutes.' },
              { step: '02', emoji: '📍', title: 'Set your zone', desc: 'GPS auto-detects your delivery area.' },
              { step: '03', emoji: '💳', title: 'Pay ₹49/week', desc: 'UPI auto-debit every Sunday.' },
              { step: '04', emoji: '🤖', title: 'We monitor',  desc: 'AI checks IMD + platforms 24/7.' },
              { step: '05', emoji: '⚡', title: 'Auto-payout', desc: '₹600 to UPI in under 2 hours.' },
            ].map((step, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.12 }}
                style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '0 16px 32px', position: 'relative', zIndex: 1 }}
              >
                <div style={{ width: 80, height: 80, borderRadius: 999, background: 'white', border: '2px solid #D97757', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 32, marginBottom: 20, boxShadow: '0 4px 24px rgba(217,119,87,0.15)' }}>
                  {step.emoji}
                </div>
                <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '2px', margin: '0 0 6px' }}>STEP {step.step}</p>
                <h3 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 18, fontWeight: 700, color: '#0F0F0F', margin: '0 0 8px' }}>{step.title}</h3>
                <p style={{ fontSize: 13, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', margin: 0, lineHeight: 1.5 }}>{step.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── LIVE INTELLIGENCE — dual news carousel ── */}
      <section style={{ padding: 'clamp(60px,8vw,80px) 0', background: 'white', overflow: 'hidden' }}>
        <div style={{ textAlign: 'center', marginBottom: 36, padding: '0 max(24px,5vw)' }}>
          <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#9B9B9B', letterSpacing: '3px', textTransform: 'uppercase', margin: '0 0 8px' }}>
            Live disruption intelligence
          </p>
          <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(24px,4vw,36px)', fontWeight: 800, color: '#0F0F0F', letterSpacing: -1, margin: 0 }}>
            We never miss an event
          </h2>
        </div>
        <NewsRow items={AI_NEWS} direction={-1} />
        <NewsRow items={[...AI_NEWS].reverse()} direction={1} />
      </section>

      {/* ── PRICING ── */}
      <section id="pricing" style={{ padding: 'clamp(80px,10vw,120px) max(24px,8vw)', background: '#FAFAFA' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: 48 }}>
            <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '3px', textTransform: 'uppercase', marginBottom: 16 }}>Pricing</p>
            <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(28px,4vw,44px)', fontWeight: 800, color: '#0F0F0F', letterSpacing: -1, marginBottom: 12 }}>
              Simple, weekly pricing
            </h2>
            <p style={{ fontSize: 16, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', maxWidth: 440, margin: '0 auto' }}>
              No annual lock-in. Cancel any week. Premium adjusts automatically as your risk score improves.
            </p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 20, alignItems: 'stretch' }}>
            {PLANS.map((plan) => (
              <motion.div
                key={plan.name}
                whileHover={{ y: -4 }}
                style={{
                  background: 'white', borderRadius: 20, padding: 28,
                  border: plan.badgeColor === 'green' ? '2px solid #12B76A' : plan.popular ? '2px solid #D97757' : '1px solid #F4F4F5',
                  boxShadow: plan.badgeColor === 'green' ? '0 8px 40px rgba(18,183,106,0.15)' : plan.popular ? '0 8px 40px rgba(217,119,87,0.15)' : '0 2px 16px rgba(0,0,0,0.06)',
                  position: 'relative', display: 'flex', flexDirection: 'column',
                }}
              >
                {plan.badge && (
                  <div style={{ position: 'absolute', top: -12, left: '50%', transform: 'translateX(-50%)', background: plan.badgeColor === 'green' ? 'linear-gradient(135deg,#12B76A,#027A48)' : 'linear-gradient(135deg,#D97757,#B85C3A)', color: 'white', fontSize: 11, fontWeight: 700, fontFamily: 'Inter, sans-serif', padding: '4px 14px', borderRadius: 999, whiteSpace: 'nowrap' }}>
                    {plan.badge}
                  </div>
                )}
                <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#9B9B9B', letterSpacing: '1px', textTransform: 'uppercase', margin: '0 0 8px' }}>{plan.name}</p>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginBottom: 4 }}>
                  <span style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 48, fontWeight: 800, color: '#0F0F0F', letterSpacing: -2 }}>₹{plan.price}</span>
                  <span style={{ fontSize: 14, color: '#9B9B9B', fontFamily: 'Inter, sans-serif' }}>/{plan.period || 'week'}</span>
                </div>
                <p style={{ fontSize: 12, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', margin: '0 0 20px', lineHeight: 1.4 }}>{plan.zone}</p>
                <div style={{ height: 1, background: '#F4F4F5', margin: '0 0 20px' }} />
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10, flex: 1 }}>
                  {plan.features.map(f => (
                    <div key={f} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                      <div style={{ width: 18, height: 18, borderRadius: 999, background: plan.popular ? '#FDF1ED' : '#ECFDF3', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 1 }}>
                        <span style={{ fontSize: 10, color: plan.popular ? '#D97757' : '#12B76A' }}>✓</span>
                      </div>
                      <span style={{ fontSize: 13, fontFamily: 'Inter, sans-serif', color: '#0F0F0F', lineHeight: 1.4 }}>{f}</span>
                    </div>
                  ))}
                </div>
                <motion.button
                  onClick={() => navigate('/register')}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.97 }}
                  style={{ width: '100%', marginTop: 24, padding: '13px', borderRadius: 10, border: plan.popular ? 'none' : '1.5px solid #E4E4E7', background: plan.popular ? 'linear-gradient(135deg,#D97757,#B85C3A)' : 'white', color: plan.popular ? 'white' : '#0F0F0F', fontSize: 14, fontWeight: 700, fontFamily: 'Inter, sans-serif', cursor: 'pointer', boxShadow: plan.popular ? '0 4px 16px rgba(217,119,87,0.35)' : 'none' }}
                >
                  {plan.cta}
                </motion.button>
              </motion.div>
            ))}
          </div>
          <p style={{ textAlign: 'center', fontSize: 12, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginTop: 24 }}>
            Prices vary by zone flood risk and worker risk score. ₹49 is minimum for low-risk zones.
          </p>
        </div>
      </section>

      {/* ── FOR WORKERS — dark section ── */}
      <section id="workers" style={{ padding: 'clamp(60px,8vw,100px) max(24px,8vw)', background: '#0F0F0F' }}>
        <div style={{ maxWidth: 1100, margin: '0 auto' }}>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            style={{ textAlign: 'center', marginBottom: 56 }}
          >
            <p style={{ fontSize: 12, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '3px', textTransform: 'uppercase', marginBottom: 16 }}>
              For delivery workers
            </p>
            <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(28px,4vw,48px)', fontWeight: 800, color: 'white', letterSpacing: -1.5, lineHeight: 1.1 }}>
              Built for the way you work
            </h2>
          </motion.div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 280px), 1fr))', gap: 2 }}>
            {[
              { emoji: '📍', title: 'Zone-based coverage', desc: '5km radius monitoring. Your area, your coverage.', color: '#D97757' },
              { emoji: '💸', title: 'UPI instant credit',  desc: 'Payout straight to your UPI. No bank forms.',       color: '#12B76A' },
              { emoji: '🤖', title: 'AI fraud protection', desc: 'Honest workers never punished. Fraud caught automatically.', color: '#2E90FA' },
              { emoji: '📊', title: 'Risk score rewards',  desc: 'Consistent workers get lower premiums. Up to 15% off.', color: '#7C3AED' },
              { emoji: '🔔', title: 'Advance warnings',    desc: 'AI predicts floods 24h early. Coverage extends automatically.', color: '#F79009' },
              { emoji: '❌', title: 'Zero paperwork',      desc: 'No forms, no documents, no calls. Ever.', color: '#F04438' },
            ].map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.07 }}
                whileHover={{ background: `${item.color}10`, borderColor: `${item.color}25` }}
                style={{
                  padding: 28,
                  border: '1px solid rgba(255,255,255,0.06)',
                  borderRadius: i === 0 ? '16px 0 0 0' : i === 2 ? '0 16px 0 0' : i === 3 ? '0 0 0 16px' : i === 5 ? '0 0 16px 0' : 0,
                  cursor: 'default',
                  transition: 'all 0.2s',
                }}
              >
                <div style={{
                  width: 44, height: 44, borderRadius: 12,
                  background: `${item.color}18`,
                  border: `1px solid ${item.color}30`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 22, marginBottom: 16,
                }}>
                  {item.emoji}
                </div>
                <h3 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 18, fontWeight: 700, color: 'white', marginBottom: 8, letterSpacing: -0.3 }}>
                  {item.title}
                </h3>
                <p style={{ fontSize: 14, color: 'rgba(255,255,255,0.5)', fontFamily: 'Inter, sans-serif', lineHeight: 1.6, margin: 0 }}>
                  {item.desc}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA ── */}
      <section style={{ padding: 'clamp(60px,8vw,100px) max(24px,8vw)', textAlign: 'center', background: '#FAFAFA' }}>
        <motion.div
          whileHover={{ scale: 1.01 }}
          style={{ maxWidth: 640, margin: '0 auto', background: 'white', borderRadius: 24, padding: 'clamp(40px,6vw,64px)', boxShadow: '0 8px 48px rgba(0,0,0,0.1)', border: '1px solid #F4F4F5' }}
        >
          <h2 style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 'clamp(24px,4vw,36px)', fontWeight: 800, color: '#0F0F0F', letterSpacing: -1, marginBottom: 16 }}>
            Start your protection today
          </h2>
          <p style={{ fontSize: 16, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', marginBottom: 32, lineHeight: 1.5 }}>
            Join thousands of delivery workers already protected by GuidePay. From ₹49/week.
          </p>
          <motion.button
            onClick={() => navigate('/register')}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.97 }}
            style={{ padding: '16px 36px', borderRadius: 12, border: 'none', background: 'linear-gradient(135deg, #D97757, #B85C3A)', color: 'white', fontSize: 16, fontWeight: 700, fontFamily: 'Inter, sans-serif', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 8, boxShadow: '0 4px 20px rgba(217,119,87,0.4)' }}
          >
            Get protected — ₹49/week <ArrowRight size={18} />
          </motion.button>
          <p style={{ fontSize: 12, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginTop: 16 }}>No commitment · Cancel anytime · UPI payment</p>
        </motion.div>
      </section>

      <LandingFooter />
    </div>
  )
}

export default Landing
