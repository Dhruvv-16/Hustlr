import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, ChevronDown } from 'lucide-react'

const TERMS_SECTIONS = [
  {
    title: '1. What GuidePay covers',
    content: `GuidePay provides parametric income insurance for platform-based delivery workers in India. Coverage is activated automatically when any of these trigger events occur in your registered delivery zone:

• IMD Flood or Heavy Rain Alert (Orange/Red level)
• Platform Application Outage (Zepto, Swiggy, Blinkit, Amazon) lasting more than 2 hours
• Government-issued Curfew or Section 144 orders

Coverage is strictly limited to income loss during these events. Health, accident, vehicle repair, and voluntary work stoppages are explicitly excluded.`,
  },
  {
    title: '2. What is NOT covered',
    content: `The following are explicitly excluded:
• Health issues, illness, or medical emergencies
• Vehicle breakdowns, repairs, or accidents
• Situations where you choose not to work
• Air quality (AQI) events — platforms do not halt operations during pollution
• Income loss from reasons within your control
• Claims where you were not actively delivering in the 6 hours before the trigger event`,
  },
  {
    title: '3. Premium & Payments',
    content: `Your weekly premium (₹49–69) is automatically debited from your registered UPI ID every Sunday. Coverage runs Monday 00:00 to Sunday 23:59.

If premium payment fails, coverage pauses until payment is successful. There are no grace periods.

You may cancel anytime from your Profile page. Cancellation takes effect at the end of the current coverage week. No refunds for partial weeks.`,
  },
  {
    title: '4. Payout Process',
    content: `When a trigger event is detected:
1. We verify you were actively delivering (last order within 6 hours of event)
2. We run fraud detection (7-signal check)
3. We confirm event via multi-worker correlation
4. Payout is sent to your UPI within 2 hours

Payout amounts:
• Flood Alert: 100% of weekly coverage cap (₹600)
• Platform Outage: 75% of cap (₹450)
• Curfew: 100% of cap (₹600)

Claims may be flagged for manual review if fraud signals exceed threshold. Resolution within 24 hours.`,
  },
  {
    title: '5. Fraud Prevention',
    content: `GuidePay uses a 7-signal fraud detection system including GPS verification, activity checks, multi-worker correlation, and device consistency.

Workers found to have submitted fraudulent claims will have their accounts suspended permanently.

Honest workers are never penalised for network connectivity issues during genuine events.`,
  },
  {
    title: '6. Data & Privacy',
    content: `We collect: mobile number, GPS location (zone-level only), delivery activity timestamps, and device identifiers.

We do NOT collect: specific delivery addresses, customer information, or personal financial data beyond UPI ID for payouts.

Your data is never sold to third parties. See our Privacy Policy for full details.`,
  },
  {
    title: '7. Governing Law',
    content: `These terms are governed by the laws of India. Any disputes shall be subject to the jurisdiction of courts in Vijayawada, Andhra Pradesh.

GuidePay is a product of Team SentinelX, built as part of Guidewire DEVTrails 2026. This is a prototype product and not currently regulated by IRDAI. Full regulatory compliance is being pursued through the IRDAI Regulatory Sandbox.`,
  },
]

const AccordionItem = ({ section, index }) => {
  const [open, setOpen] = useState(index === 0)
  return (
    <div style={{
      borderBottom: '1px solid var(--border-light)',
    }}>
      <motion.button
        onClick={() => setOpen(!open)}
        whileTap={{ opacity: 0.7 }}
        style={{
          width: '100%',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '16px 0',
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          textAlign: 'left',
          gap: 12,
        }}
      >
        <span style={{
          fontSize: 15, fontWeight: 600,
          fontFamily: 'Inter',
          color: 'var(--text-primary)',
          lineHeight: 1.4,
        }}>
          {section.title}
        </span>
        <motion.div
          animate={{ rotate: open ? 180 : 0 }}
          transition={{ duration: 0.2 }}
          style={{ flexShrink: 0 }}
        >
          <ChevronDown size={18} color="var(--text-tertiary)" />
        </motion.div>
      </motion.button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            style={{ overflow: 'hidden' }}
          >
            <p style={{
              fontSize: 14, color: 'var(--text-secondary)',
              fontFamily: 'Inter', lineHeight: 1.8,
              margin: '0 0 16px',
              whiteSpace: 'pre-line',
            }}>
              {section.content}
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

const Terms = () => {
  const navigate = useNavigate()
  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--bg-secondary)',
    }}>
      {/* TopBar */}
      <div style={{
        background: 'var(--bg-card)',
        borderBottom: '1px solid var(--border-light)',
        padding: '16px',
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        position: 'sticky', top: 0, zIndex: 50,
      }}>
        <motion.button
          onClick={() => navigate(-1)}
          whileTap={{ scale: 0.9 }}
          style={{
            background: 'none', border: 'none',
            cursor: 'pointer', padding: 0,
            display: 'flex',
          }}
        >
          <ArrowLeft size={22} color="var(--text-primary)" />
        </motion.button>
        <h1 style={{
          fontFamily: 'Bricolage Grotesque',
          fontSize: 18, fontWeight: 800,
          color: 'var(--text-primary)', margin: 0,
        }}>
          Terms of Service
        </h1>
      </div>

      <div style={{ padding: '16px 16px 80px' }}>
        {/* Header card */}
        <div style={{
          background: '#FDF1ED',
          border: '1px solid rgba(217,119,87,0.2)',
          borderRadius: 14,
          padding: '14px 16px',
          marginBottom: 20,
        }}>
          <p style={{
            fontSize: 13, fontFamily: 'Inter',
            color: '#B85C3A', margin: '0 0 4px',
            fontWeight: 600,
          }}>
            Last updated: March 2026
          </p>
          <p style={{
            fontSize: 13, fontFamily: 'Inter',
            color: '#B85C3A', margin: 0, lineHeight: 1.5,
            opacity: 0.8,
          }}>
            By using GuidePay, you agree to these terms.
            Read them carefully before activating coverage.
          </p>
        </div>

        {/* Accordion sections */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 14,
          padding: '0 16px',
          border: '1px solid var(--border)',
        }}>
          {TERMS_SECTIONS.map((section, i) => (
            <AccordionItem
              key={i}
              section={section}
              index={i}
            />
          ))}
        </div>

        <p style={{
          textAlign: 'center',
          fontSize: 12,
          color: 'var(--text-tertiary)',
          fontFamily: 'Inter',
          marginTop: 20,
          lineHeight: 1.5,
        }}>
          Questions? Contact us at{' '}
          <a
            href="mailto:guidepay@sentinelx.in"
            style={{ color: '#D97757' }}
          >
            guidepay@sentinelx.in
          </a>
        </p>
      </div>
    </div>
  )
}

export default Terms
