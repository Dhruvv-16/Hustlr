import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, ChevronDown } from 'lucide-react'

const PRIVACY_SECTIONS = [
  {
    title: '1. Information We Collect',
    content: `We collect only the minimum data necessary to provide income protection:

• Mobile number — used for login, OTP verification, and account identification
• GPS location — zone-level only (5km radius), used to verify delivery activity and detect trigger events
• Delivery activity timestamps — last order time, used to verify active work status during claims
• Device identifiers — used for fraud prevention and account security
• UPI ID — used exclusively for sending payouts

We do NOT collect:
• Specific delivery addresses or routes
• Customer information
• Personal financial data beyond UPI ID
• Browsing history or app usage outside GuidePay`,
  },
  {
    title: '2. How We Use Your Data',
    content: `Your data is used for:

• Verifying your delivery activity during trigger events
• Processing and sending payouts to your UPI
• Calculating your risk score (based on zone flood history and activity patterns)
• Detecting and preventing fraudulent claims
• Sending you alerts about weather events and coverage status
• Improving our trigger detection algorithms

We never use your data for advertising, marketing to third parties, or any purpose unrelated to your income protection.`,
  },
  {
    title: '3. Data Sharing',
    content: `We share your data only in these specific situations:

• Payment processors — UPI ID and transaction details for payout processing
• Weather data providers — Your zone (not exact location) to provide accurate forecasts
• Fraud prevention — Anonymized activity patterns for multi-worker correlation

We NEVER:
• Sell your data to advertisers or data brokers
• Share your personal information with your delivery platform employer
• Provide individual data to government agencies without a court order
• Transfer data outside India`,
  },
  {
    title: '4. Data Storage & Security',
    content: `• All data is encrypted at rest and in transit (AES-256, TLS 1.3)
• Data is stored on servers located in India
• Access to personal data is restricted to authorized team members only
• We conduct regular security audits
• GPS data older than 90 days is automatically deleted
• Activity logs older than 1 year are anonymized

We follow CERT-In guidelines for data breach notification.`,
  },
  {
    title: '5. Your Rights',
    content: `You have the right to:

• Access — Request a copy of all data we hold about you
• Correction — Update or correct your personal information
• Deletion — Request permanent deletion of your account and data
• Portability — Receive your data in a machine-readable format
• Objection — Object to specific data processing activities
• Withdrawal — Withdraw consent at any time (coverage will cease)

To exercise any of these rights, contact us at guidepay@sentinelx.in. We respond within 72 hours.`,
  },
  {
    title: '6. Cookies & Analytics',
    content: `GuidePay uses minimal cookies:

• Session cookie — keeps you logged in (essential, cannot be disabled)
• Preference cookie — stores your theme and language settings
• Analytics — anonymous usage statistics to improve the app (can be disabled)

We do not use tracking cookies, advertising cookies, or cross-site tracking of any kind.`,
  },
  {
    title: '7. Changes to Privacy Policy',
    content: `We may update this policy from time to time. When we do:

• We will notify you in-app at least 7 days before changes take effect
• Significant changes will require your explicit consent
• You can always access the current version from your Profile page
• Previous versions are available upon request

This policy was last updated in March 2026.

For questions or concerns, contact our Data Protection Officer at guidepay@sentinelx.in.`,
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

const Privacy = () => {
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
          Privacy Policy
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
            Your privacy matters. We collect only what's necessary
            to protect your income. Read how below.
          </p>
        </div>

        {/* Accordion sections */}
        <div style={{
          background: 'var(--bg-card)',
          borderRadius: 14,
          padding: '0 16px',
          border: '1px solid var(--border)',
        }}>
          {PRIVACY_SECTIONS.map((section, i) => (
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
          Questions about your data? Contact us at{' '}
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

export default Privacy
