import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, Send, Bot, User, Zap } from 'lucide-react'
import { useWorkerStore } from '../../store/workerStore'

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

const QUICK_QUESTIONS = [
  'How does auto-payout work?',
  'What triggers a claim?',
  'How is my premium calculated?',
  'What is my coverage limit?',
  'How fast are payouts sent?',
  'Can I change my plan mid-week?',
]

// Keyword-based fallback answers
const FAQ_ANSWERS = {
  'payout': 'Payouts are sent automatically to your UPI within 2 minutes of a verified trigger event. No claim forms needed — our AI detects floods, outages, and curfews and processes payment instantly.',
  'claim': 'Claims are created automatically when our system detects a trigger event in your zone (flood, platform outage, or curfew). You do not need to file anything manually.',
  'premium': 'Your premium is calculated based on your delivery zone\'s flood/outage risk and your personal risk score. Base premium is ₹49/week. Lower risk score = lower premium!',
  'coverage': 'Your coverage limit is ₹600 per week. All claims in a week are capped at this amount, which covers 1-2 days of lost income during a disaster event.',
  'fast': 'GuidePay payouts are processed within 2 minutes of trigger verification — one of the fastest in the industry. The entire process is automated with no human intervention needed.',
  'plan': 'You can switch plans between coverage cycles (weeks). Active plans cannot be changed mid-week. Visit the Coverage page to see available plans.',
  'flood': 'Flood triggers are detected using IMD SACHET alerts and verified by our AI system. If your zone shows a RED alert and you were active on a delivery platform, you automatically receive a payout.',
  'outage': 'Platform outage triggers are detected via Downdetector monitoring. If your primary delivery app goes down during peak hours in your area, GuidePay automatically compensates you.',
  'curfew': 'Curfew triggers are based on official government notifications. If a curfew prevents you from working in your zone, GuidePay pays you for the lost income.',
  'risk': 'Your risk score (0.0 to 1.0) measures your delivery reliability. A higher score means lower fraud risk and lower premiums. It improves as you maintain consistent delivery activity.',
  'zone': 'Your delivery zone determines your base flood and outage risk. High-risk zones like coastal areas have higher premiums but also more frequent trigger events.',
  'refund': 'Premiums are non-refundable as they provide weekly coverage. However, if you receive more in payouts than you paid in premiums, your ROI is positive — which is common!',
}

function getKeywordAnswer(question) {
  const lower = question.toLowerCase()
  for (const [keyword, answer] of Object.entries(FAQ_ANSWERS)) {
    if (lower.includes(keyword)) return answer
  }
  return null
}

function buildSystemPrompt(worker) {
  return `You are GuidePay Assistant, an AI helper for gig workers using the GuidePay income protection platform.

Worker context:
- Name: ${worker?.name || 'Worker'}
- City: ${worker?.city || 'Unknown'}
- Zone: ${worker?.zone || 'Unknown'}
- Risk Score: ${worker?.riskScore || '0.75'}
- Risk Tier: ${worker?.riskTier || 'MEDIUM'}
- Active Policy: ${worker?.activePolicy ? 'Yes — ' + (worker?.activePolicy?.planName || 'Standard') + ' plan' : 'No active policy'}
- Coverage: ₹600/week
- Premium: ₹${worker?.premium || 58}/week

GuidePay platform info:
- Covers flood, platform outage, and curfew events
- Auto-payouts to UPI within 2 minutes of trigger verification
- AI-powered fraud detection with 7-point check system
- Weekly plans: Basic (₹49), Standard (₹58), Premium (₹69)
- Coverage cap: ₹600/week for all plans
- Monitors IMD SACHET for flood alerts and Downdetector for outages

Be helpful, concise, and friendly. Use ₹ for Indian Rupees. Keep responses under 3 sentences unless the question needs more detail.`
}

export default function CoverageAssistant() {
  const navigate = useNavigate()
  const worker = useWorkerStore(s => s.worker)
  const activePolicy = useWorkerStore(s => s.activePolicy)
  const messagesEndRef = useRef(null)

  const workerWithPolicy = { ...worker, activePolicy }

  const [messages, setMessages] = useState([
    {
      id: '0',
      role: 'assistant',
      text: `Hi ${worker?.name?.split(' ')[0] || 'there'}! 👋 I'm your GuidePay assistant. Ask me anything about your coverage, payouts, or how the platform works.`,
      timestamp: new Date().toISOString(),
    }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const sendMessage = async (text) => {
    if (!text.trim() || loading) return
    const userMsg = { id: Date.now().toString(), role: 'user', text: text.trim(), timestamp: new Date().toISOString() }
    setMessages(prev => [...prev, userMsg])
    setInput('')
    setLoading(true)

    try {
      // Try keyword-based answer first (always available)
      const keywordAnswer = getKeywordAnswer(text)

      // Try Anthropic API via backend proxy if available
      const token = localStorage.getItem('gp-access-token') || localStorage.getItem('gp-token')
      let aiResponse = null

      if (token) {
        try {
          const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000'
          const resp = await fetch(`${apiUrl}/api/v1/assistant/chat`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
              message: text,
              system_prompt: buildSystemPrompt(workerWithPolicy),
            }),
            signal: AbortSignal.timeout(8000),
          })
          if (resp.ok) {
            const data = await resp.json()
            aiResponse = data.response
          }
        } catch {
          // Fallback to keyword matching
        }
      }

      const finalAnswer = aiResponse || keywordAnswer || generateFallback(text)
      const assistantMsg = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        text: finalAnswer,
        timestamp: new Date().toISOString(),
      }
      setMessages(prev => [...prev, assistantMsg])
    } catch {
      setMessages(prev => [...prev, {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        text: 'Sorry, I had trouble answering that. Please try again or contact support.',
        timestamp: new Date().toISOString(),
      }])
    }
    setLoading(false)
  }

  const generateFallback = (question) => {
    const lower = question.toLowerCase()
    if (lower.includes('hello') || lower.includes('hi')) return `Hello! How can I help you with your GuidePay coverage today?`
    if (lower.includes('thank')) return `You're welcome! Is there anything else you'd like to know about your coverage?`
    if (lower.includes('how') && lower.includes('work')) return `GuidePay automatically monitors your delivery zone for flood, outage, and curfew events. When one is detected, payouts go directly to your UPI — no forms required!`
    return `Great question! For detailed help, you can also check the Coverage page or contact GuidePay support. Your coverage is active and protecting you right now. 🛡️`
  }

  return (
    <motion.div
      className="min-h-screen flex flex-col"
      style={{ background: 'var(--bg-secondary)' }}
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      {/* Header */}
      <div style={{
        background: 'linear-gradient(135deg, #D97757, #B85C3A)',
        padding: '16px 16px 20px',
        flexShrink: 0,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <button
            onClick={() => navigate(-1)}
            style={{
              background: 'rgba(255,255,255,0.15)',
              border: '1px solid rgba(255,255,255,0.25)',
              borderRadius: 999,
              width: 36, height: 36,
              cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <ArrowLeft size={18} color="white" />
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 999,
              background: 'rgba(255,255,255,0.15)',
              border: '1.5px solid rgba(255,255,255,0.3)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Bot size={20} color="white" />
            </div>
            <div>
              <h1 style={{ fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: 800, color: 'white', margin: 0 }}>
                Coverage Assistant
              </h1>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 2 }}>
                <div style={{ width: 6, height: 6, borderRadius: 999, background: '#12B76A' }} />
                <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.8)', fontFamily: 'Inter' }}>
                  Online · Ask me anything
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Quick questions */}
      <div style={{ padding: '12px 16px 0', flexShrink: 0 }}>
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
          {QUICK_QUESTIONS.map((q) => (
            <button
              key={q}
              onClick={() => sendMessage(q)}
              style={{
                flexShrink: 0,
                padding: '6px 12px',
                borderRadius: 999,
                border: '1px solid var(--border-light)',
                background: 'var(--bg-card)',
                fontSize: 12, fontFamily: 'Inter', fontWeight: 600,
                color: 'var(--text-secondary)',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
              }}
            >
              {q}
            </button>
          ))}
        </div>
      </div>

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {messages.map((msg) => (
          <motion.div
            key={msg.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            style={{
              display: 'flex',
              justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
              gap: 8,
              alignItems: 'flex-end',
            }}
          >
            {msg.role === 'assistant' && (
              <div style={{
                width: 28, height: 28, borderRadius: 999,
                background: 'linear-gradient(135deg, #D97757, #B85C3A)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>
                <Bot size={14} color="white" />
              </div>
            )}
            <div style={{
              maxWidth: '75%',
              padding: '10px 14px',
              borderRadius: msg.role === 'user' ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
              background: msg.role === 'user'
                ? 'linear-gradient(135deg, #D97757, #B85C3A)'
                : 'var(--bg-card)',
              border: msg.role === 'user' ? 'none' : '1px solid var(--border-light)',
              boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
            }}>
              <p style={{
                fontSize: 14, fontFamily: 'Inter', lineHeight: 1.5, margin: 0,
                color: msg.role === 'user' ? 'white' : 'var(--text-primary)',
              }}>
                {msg.text}
              </p>
            </div>
            {msg.role === 'user' && (
              <div style={{
                width: 28, height: 28, borderRadius: 999,
                background: 'var(--bg-card)',
                border: '1px solid var(--border-light)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>
                <User size={14} color="var(--text-secondary)" />
              </div>
            )}
          </motion.div>
        ))}

        {/* Typing indicator */}
        <AnimatePresence>
          {loading && (
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 8 }}
              style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}
            >
              <div style={{
                width: 28, height: 28, borderRadius: 999,
                background: 'linear-gradient(135deg, #D97757, #B85C3A)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Bot size={14} color="white" />
              </div>
              <div style={{
                padding: '12px 16px',
                borderRadius: '18px 18px 18px 4px',
                background: 'var(--bg-card)',
                border: '1px solid var(--border-light)',
                display: 'flex', gap: 4, alignItems: 'center',
              }}>
                {[0, 1, 2].map(i => (
                  <motion.div
                    key={i}
                    animate={{ y: [0, -4, 0] }}
                    transition={{ duration: 0.6, repeat: Infinity, delay: i * 0.15 }}
                    style={{ width: 6, height: 6, borderRadius: 999, background: '#D97757' }}
                  />
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div style={{
        padding: '12px 16px 24px',
        background: 'var(--bg-card)',
        borderTop: '1px solid var(--border-light)',
        flexShrink: 0,
      }}>
        <div style={{
          display: 'flex', gap: 10, alignItems: 'center',
          background: 'var(--bg-secondary)',
          borderRadius: 999,
          padding: '8px 8px 8px 16px',
          border: '1.5px solid var(--border-light)',
        }}>
          <input
            type="text"
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && sendMessage(input)}
            placeholder="Ask about your coverage..."
            style={{
              flex: 1, border: 'none', outline: 'none',
              background: 'transparent',
              fontSize: 14, fontFamily: 'Inter',
              color: 'var(--text-primary)',
            }}
          />
          <motion.button
            onClick={() => sendMessage(input)}
            disabled={!input.trim() || loading}
            whileTap={{ scale: 0.9 }}
            style={{
              width: 36, height: 36,
              borderRadius: 999,
              border: 'none',
              background: input.trim() && !loading
                ? 'linear-gradient(135deg, #D97757, #B85C3A)'
                : 'var(--border-light)',
              cursor: input.trim() && !loading ? 'pointer' : 'default',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <Send size={15} color={input.trim() && !loading ? 'white' : 'var(--text-tertiary)'} />
          </motion.button>
        </div>
        <p style={{ fontSize: 11, color: 'var(--text-tertiary)', fontFamily: 'Inter', textAlign: 'center', marginTop: 8 }}>
          <Zap size={10} style={{ display: 'inline', marginRight: 3 }} />
          Powered by GuidePay AI
        </p>
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </motion.div>
  )
}
