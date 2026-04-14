import { motion } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'

const ZERO_TOUCH_STEPS = [
  {
    step: 1,
    icon: '🌧️',
    title: 'Trigger Detected',
    subtitle: 'Automatic',
    description: "Our engine polls IMD SACHET, platform status pages, and government feeds every 15 minutes. When a trigger fires, it's detected instantly.",
    time: '0 seconds',
    sources: ['IMD SACHET RSS', 'Downdetector', 'Govt feeds', 'OpenWeatherMap'],
    color: '#2E90FA',
  },
  {
    step: 2,
    icon: '📍',
    title: 'Activity Verified',
    subtitle: 'Automatic',
    description: 'We check your last delivery timestamp. If you were working in the last 6 hours, you qualify. No photos, no forms, no calls.',
    time: '< 30 seconds',
    sources: ['Platform last_order_timestamp', 'GPS zone check'],
    color: '#D97757',
  },
  {
    step: 3,
    icon: '🛡️',
    title: '7-Signal Fraud Check',
    subtitle: 'AI-powered',
    description: 'Our Isolation Forest ML model runs 7 simultaneous fraud checks. 89% of claims pass automatically. Only 11% need manual review.',
    time: '< 60 seconds',
    sources: ['GPS verification', 'Claim frequency', 'Zone correlation', 'Account age', 'Activity history', 'Risk score', 'Duplicate check'],
    color: '#7C3AED',
  },
  {
    step: 4,
    icon: '⚡',
    title: 'Auto-Approved',
    subtitle: 'No human needed',
    description: 'If fraud score < 0.70, the claim is automatically approved. Our target is 89% auto-approval rate. No manager reviews, no waiting.',
    time: '< 2 minutes',
    sources: ['Fraud score threshold 0.70', 'Zone correlation > 60%'],
    color: '#12B76A',
  },
  {
    step: 5,
    icon: '💰',
    title: 'UPI Payout',
    subtitle: 'Instant transfer',
    description: '₹600 sent directly to your registered UPI ID. You get a notification on your phone. No bank forms, no NEFT delays.',
    time: '< 2 hours',
    sources: ['Razorpay Payouts API', 'UPI instant transfer'],
    color: '#12B76A',
  },
]

const TRIGGER_TYPES = [
  {
    id: 'flood',
    icon: '🌧️',
    name: 'IMD Flood Alert',
    payout: '100%',
    api: 'IMD SACHET RSS (Free)',
    description: 'Red/Orange level flood alert for your district',
    example: 'Heavy rainfall warning issued for Hyderabad district',
  },
  {
    id: 'outage',
    icon: '⚡',
    name: 'Platform Outage',
    payout: '75%',
    api: 'Downdetector + Status Pages',
    description: 'Zepto, Swiggy, Blinkit, Amazon down 2+ hours',
    example: 'Zepto app shows 2,400 reports on Downdetector',
  },
  {
    id: 'curfew',
    icon: '🚨',
    name: 'Govt Curfew',
    payout: '100%',
    api: 'State Govt RSS + News',
    description: 'Section 144 or curfew order in your city',
    example: 'Section 144 imposed in Hyderabad district',
  },
  {
    id: 'aqi',
    icon: '😷',
    name: 'Air Quality Alert',
    payout: '50%',
    api: 'OpenWeatherMap AQI (Free)',
    description: 'AQI Very Poor (4/5) or extreme heat 43°C+',
    example: 'AQI reaches 312 in Delhi — platform pauses deliveries',
  },
  {
    id: 'festival',
    icon: '🎊',
    name: 'Festival Disruption',
    payout: '40%',
    api: 'Internal Calendar Engine',
    description: 'Major festival causing 40%+ delivery drop',
    example: 'Holi — platforms report 60% order drop nationwide',
  },
]

const HowItWorks = () => {
  const navigate = useNavigate()

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-secondary)', paddingBottom: 80 }}>
      {/* TopBar */}
      <div style={{
        background: 'var(--bg-card)',
        borderBottom: '1px solid var(--border-light)',
        padding: '16px',
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        position: 'sticky',
        top: 0,
        zIndex: 50,
      }}>
        <button
          onClick={() => navigate(-1)}
          style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
        >
          <ArrowLeft size={22} color="var(--text-primary)" />
        </button>
        <div>
          <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
            How GuidePay Works
          </h1>
          <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: 0 }}>
            Zero-touch claim process
          </p>
        </div>
      </div>

      <div style={{ padding: 16 }}>
        {/* Hero */}
        <div style={{
          background: 'linear-gradient(135deg, #D97757, #B85C3A)',
          borderRadius: 18,
          padding: 22,
          marginBottom: 20,
          textAlign: 'center',
        }}>
          <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'rgba(255,255,255,0.7)', letterSpacing: '2px', textTransform: 'uppercase', margin: '0 0 8px' }}>
            Zero-touch guarantee
          </p>
          <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 26, fontWeight: 800, color: 'white', margin: '0 0 8px', lineHeight: 1.2 }}>
            Flood detected at 2:14 PM
          </p>
          <p style={{ fontFamily: 'Bricolage Grotesque', fontSize: 26, fontWeight: 800, color: 'rgba(255,255,255,0.9)', margin: '0 0 14px', lineHeight: 1.2 }}>
            ₹600 in your UPI by 4:00 PM
          </p>
          <p style={{ fontSize: 13, fontFamily: 'Inter', color: 'rgba(255,255,255,0.8)', margin: 0 }}>
            No form filled. No call made. No document uploaded.
          </p>
        </div>

        {/* 5-step timeline */}
        <div style={{ marginBottom: 20 }}>
          <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '2px', textTransform: 'uppercase', margin: '0 0 12px' }}>
            Claim Process
          </p>

          {ZERO_TOUCH_STEPS.map((step, i) => (
            <motion.div
              key={step.step}
              initial={{ opacity: 0, x: -12 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.08 }}
              style={{ display: 'flex', gap: 14, position: 'relative' }}
            >
              {/* Timeline line */}
              {i < ZERO_TOUCH_STEPS.length - 1 && (
                <div style={{
                  position: 'absolute',
                  left: 17,
                  top: 44,
                  bottom: -8,
                  width: 2,
                  background: 'var(--border)',
                  zIndex: 0,
                }} />
              )}

              {/* Step icon */}
              <div style={{
                width: 36,
                height: 36,
                borderRadius: 999,
                background: `${step.color}15`,
                border: `2px solid ${step.color}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 16,
                flexShrink: 0,
                zIndex: 1,
              }}>
                {step.icon}
              </div>

              {/* Content */}
              <div style={{
                background: 'var(--bg-card)',
                border: '1px solid var(--border)',
                borderRadius: 14,
                padding: '14px 16px',
                flex: 1,
                marginBottom: 8,
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
                  <div>
                    <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 2px' }}>
                      {step.title}
                    </p>
                    <span style={{ fontSize: 10, fontWeight: 700, fontFamily: 'Inter', color: step.color, background: `${step.color}12`, padding: '2px 7px', borderRadius: 999 }}>
                      {step.subtitle}
                    </span>
                  </div>
                  <span style={{ fontSize: 11, fontFamily: 'Inter', color: '#12B76A', fontWeight: 700, background: 'rgba(18,183,106,0.08)', padding: '3px 8px', borderRadius: 999, whiteSpace: 'nowrap', marginLeft: 8 }}>
                    {step.time}
                  </span>
                </div>
                <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)', margin: '6px 0 8px', lineHeight: 1.6 }}>
                  {step.description}
                </p>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                  {step.sources.map(s => (
                    <span key={s} style={{ fontSize: 9, fontWeight: 600, fontFamily: 'Inter', color: 'var(--text-tertiary)', background: 'var(--bg-secondary)', padding: '2px 7px', borderRadius: 999, border: '1px solid var(--border)' }}>
                      {s}
                    </span>
                  ))}
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* 5 Trigger Types */}
        <div>
          <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-tertiary)', letterSpacing: '2px', textTransform: 'uppercase', margin: '0 0 12px' }}>
            5 Automated Triggers
          </p>
          {TRIGGER_TYPES.map(trigger => (
            <div key={trigger.id} style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 14, padding: '14px 16px', marginBottom: 8 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 6 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 22 }}>{trigger.icon}</span>
                  <div>
                    <p style={{ fontSize: 14, fontWeight: 700, fontFamily: 'Inter', color: 'var(--text-primary)', margin: '0 0 2px' }}>
                      {trigger.name}
                    </p>
                    <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: 0 }}>
                      via {trigger.api}
                    </p>
                  </div>
                </div>
                <div style={{ background: 'var(--brand-light)', border: '1px solid var(--brand-border)', borderRadius: 8, padding: '4px 10px', textAlign: 'center', flexShrink: 0 }}>
                  <p style={{ fontSize: 14, fontWeight: 800, fontFamily: 'Bricolage Grotesque', color: 'var(--brand)', margin: 0 }}>
                    {trigger.payout}
                  </p>
                  <p style={{ fontSize: 9, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: 0, fontWeight: 600 }}>
                    payout
                  </p>
                </div>
              </div>
              <p style={{ fontSize: 12, fontFamily: 'Inter', color: 'var(--text-secondary)', margin: '0 0 6px', lineHeight: 1.5 }}>
                {trigger.description}
              </p>
              <p style={{ fontSize: 11, fontFamily: 'Inter', color: 'var(--text-tertiary)', margin: 0, fontStyle: 'italic' }}>
                Example: {trigger.example}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default HowItWorks
