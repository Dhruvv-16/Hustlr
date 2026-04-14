import { useEffect, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import { Plus, ArrowLeft, Send, MessageSquare, ChevronRight } from 'lucide-react'
import {
  createSupportTicket,
  getMySupportTickets,
  sendSupportMessage,
} from '../../services/api'

const CATEGORIES = [
  'Claim not processed',
  'Payment issue',
  'Coverage question',
  'App problem',
  'Premium concern',
  'Other',
]

const STATUS_COLORS = {
  open: { bg: '#FFFAEB', text: '#F79009', border: '#FDE68A' },
  resolved: { bg: '#ECFDF3', text: '#12B76A', border: '#A7F3D0' },
  pending: { bg: '#EFF8FF', text: '#2E90FA', border: '#BFDBFE' },
}

const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit: { opacity: 0, y: -8, transition: { duration: 0.12 } },
}

export default function Support() {
  const [view, setView] = useState('list')
  const [tickets, setTickets] = useState([])
  const [activeTicket, setActiveTicket] = useState(null)
  const [newMsg, setNewMsg] = useState('')
  const [loading, setLoading] = useState(true)
  const messagesEndRef = useRef(null)

  const [category, setCategory] = useState(CATEGORIES[0])
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')

  const refresh = async (keepSelection = true) => {
    try {
      const data = await getMySupportTickets()
      const nextTickets = data.tickets || []
      setTickets(nextTickets)
      if (keepSelection && activeTicket) {
        const nextActive = nextTickets.find((ticket) => ticket.id === activeTicket.id)
        setActiveTicket(nextActive || null)
      }
    } catch (error) {
      console.error('[Support] Failed to load tickets:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    refresh(false)
  }, [])

  useEffect(() => {
    const interval = setInterval(() => refresh(true), 6000)
    return () => clearInterval(interval)
  }, [activeTicket?.id])

  useEffect(() => {
    if (view === 'chat') {
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
    }
  }, [view, activeTicket?.messages])

  const createTicket = async (event) => {
    event.preventDefault()
    try {
      const ticket = await createSupportTicket({ category, subject, body })
      setSubject('')
      setBody('')
      setCategory(CATEGORIES[0])
      await refresh(false)
      setActiveTicket(ticket)
      setView('chat')
    } catch (error) {
      console.error('[Support] Create ticket failed:', error)
    }
  }

  const submitMessage = async (event) => {
    event.preventDefault()
    if (!newMsg.trim() || !activeTicket) return
    try {
      const updated = await sendSupportMessage(activeTicket.id, newMsg.trim())
      setActiveTicket(updated)
      setTickets((prev) => prev.map((ticket) => (ticket.id === updated.id ? updated : ticket)))
      setNewMsg('')
    } catch (error) {
      console.error('[Support] Send message failed:', error)
    }
  }

  const openTicket = (ticket) => {
    setActiveTicket(ticket)
    setView('chat')
  }

  if (view === 'new') {
    return (
      <motion.div variants={pageVariants} initial="initial" animate="animate" exit="exit" style={{ padding: '16px 16px 100px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button onClick={() => setView('list')} style={{ background: 'var(--bg-tertiary)', border: 'none', borderRadius: 8, width: 34, height: 34, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <ArrowLeft size={18} style={{ color: 'var(--text-primary)' }} />
          </button>
          <h2 style={{ fontFamily: 'Bricolage Grotesque', fontWeight: 700, fontSize: 18, color: 'var(--text-primary)', margin: 0 }}>
            New Ticket
          </h2>
        </div>

        <form onSubmit={createTicket} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div>
            <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-tertiary)', display: 'block', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.8 }}>
              Category
            </label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {CATEGORIES.map((item) => (
                <button
                  type="button"
                  key={item}
                  onClick={() => setCategory(item)}
                  style={{
                    padding: '6px 12px',
                    borderRadius: 999,
                    border: `1px solid ${category === item ? 'var(--brand)' : 'var(--border)'}`,
                    background: category === item ? 'var(--brand-light)' : 'var(--bg-card)',
                    color: category === item ? 'var(--brand)' : 'var(--text-secondary)',
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  {item}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-tertiary)', display: 'block', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.8 }}>
              Subject
            </label>
            <input
              type="text"
              value={subject}
              onChange={(event) => setSubject(event.target.value)}
              placeholder="Brief description of your issue"
              required
              style={{ width: '100%', height: 46, borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg-card)', padding: '0 14px', fontSize: 14, fontFamily: 'Inter', color: 'var(--text-primary)', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-tertiary)', display: 'block', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.8 }}>
              Description
            </label>
            <textarea
              value={body}
              onChange={(event) => setBody(event.target.value)}
              placeholder="Describe your issue in detail..."
              required
              rows={5}
              style={{ width: '100%', borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg-card)', padding: '12px 14px', fontSize: 14, fontFamily: 'Inter', color: 'var(--text-primary)', outline: 'none', resize: 'vertical' }}
            />
          </div>

          <motion.button type="submit" whileTap={{ scale: 0.97 }} style={{ height: 50, borderRadius: 12, background: 'var(--brand)', border: 'none', color: 'white', fontSize: 15, fontWeight: 700, fontFamily: 'Inter', cursor: 'pointer' }}>
            Submit Ticket
          </motion.button>
        </form>
      </motion.div>
    )
  }

  if (view === 'chat' && activeTicket) {
    const colors = STATUS_COLORS[activeTicket.status] || STATUS_COLORS.open
    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 120px)' }}>
        <div style={{ padding: '16px', borderBottom: '1px solid var(--border-light)', background: 'var(--bg-card)', display: 'flex', alignItems: 'center', gap: 12 }}>
          <button onClick={() => { setView('list'); refresh(true) }} style={{ background: 'var(--bg-tertiary)', border: 'none', borderRadius: 8, width: 34, height: 34, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <ArrowLeft size={18} style={{ color: 'var(--text-primary)' }} />
          </button>
          <div style={{ flex: 1, minWidth: 0 }}>
            <p style={{ fontWeight: 700, fontSize: 15, color: 'var(--text-primary)', fontFamily: 'Bricolage Grotesque', margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {activeTicket.subject}
            </p>
            <p style={{ fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: 0 }}>
              {activeTicket.id} · {activeTicket.category}
            </p>
          </div>
          <span style={{ padding: '4px 10px', borderRadius: 999, background: colors.bg, color: colors.text, border: `1px solid ${colors.border}`, fontSize: 11, fontWeight: 700, fontFamily: 'Inter', textTransform: 'capitalize' }}>
            {activeTicket.status}
          </span>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {(activeTicket.messages || []).map((msg) => {
            const isWorker = msg.from === 'worker'
            return (
              <div key={msg.id || `${msg.from}-${msg.time}`} style={{ display: 'flex', justifyContent: isWorker ? 'flex-end' : 'flex-start' }}>
                <div style={{ maxWidth: '78%', background: isWorker ? 'var(--brand)' : 'var(--bg-card)', border: isWorker ? 'none' : '1px solid var(--border-light)', borderRadius: isWorker ? '14px 14px 4px 14px' : '14px 14px 14px 4px', padding: '10px 14px' }}>
                  <p style={{ fontSize: 14, fontFamily: 'Inter', color: isWorker ? 'white' : 'var(--text-primary)', margin: 0, lineHeight: 1.5 }}>
                    {msg.text}
                  </p>
                  <p style={{ fontSize: 11, color: isWorker ? 'rgba(255,255,255,0.65)' : 'var(--text-tertiary)', margin: '4px 0 0', fontFamily: 'Inter' }}>
                    {(msg.sender_name || (isWorker ? 'You' : 'GuidePay Support'))} · {new Date(msg.time).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
              </div>
            )
          })}
          <div ref={messagesEndRef} />
        </div>

        {activeTicket.status !== 'resolved' && (
          <form onSubmit={submitMessage} style={{ padding: '12px 16px', borderTop: '1px solid var(--border-light)', background: 'var(--bg-card)', display: 'flex', gap: 10, alignItems: 'flex-end' }}>
            <input
              value={newMsg}
              onChange={(event) => setNewMsg(event.target.value)}
              placeholder="Type a message..."
              style={{ flex: 1, height: 44, borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg-secondary)', padding: '0 14px', fontSize: 14, fontFamily: 'Inter', color: 'var(--text-primary)', outline: 'none' }}
            />
            <motion.button type="submit" whileTap={{ scale: 0.94 }} style={{ width: 44, height: 44, borderRadius: 10, background: 'var(--brand)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Send size={18} color="white" />
            </motion.button>
          </form>
        )}
      </div>
    )
  }

  return (
    <motion.div variants={pageVariants} initial="initial" animate="animate" exit="exit" style={{ padding: '16px 16px 100px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <h2 style={{ fontFamily: 'Bricolage Grotesque', fontWeight: 700, fontSize: 20, color: 'var(--text-primary)', margin: 0 }}>
          Support
        </h2>
        <motion.button whileTap={{ scale: 0.95 }} onClick={() => setView('new')} style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'var(--brand)', border: 'none', borderRadius: 10, padding: '8px 14px', cursor: 'pointer', color: 'white', fontSize: 13, fontWeight: 700, fontFamily: 'Inter' }}>
          <Plus size={15} />
          New Ticket
        </motion.button>
      </div>

      {loading ? (
        <div style={{ padding: 20, color: 'var(--text-tertiary)', fontFamily: 'Inter' }}>Loading support tickets...</div>
      ) : tickets.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '60px 20px', background: 'var(--bg-card)', borderRadius: 16, border: '1px solid var(--border-light)' }}>
          <MessageSquare size={36} style={{ color: 'var(--text-tertiary)', marginBottom: 12 }} />
          <p style={{ fontSize: 15, fontWeight: 600, color: 'var(--text-primary)', fontFamily: 'Bricolage Grotesque', margin: '0 0 6px' }}>
            No support tickets yet
          </p>
          <p style={{ fontSize: 13, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: 0 }}>
            Tap "New Ticket" to get help from the admin support team
          </p>
        </div>
      ) : (
        <div style={{ background: 'var(--bg-card)', borderRadius: 16, border: '1px solid var(--border-light)', overflow: 'hidden' }}>
          {tickets.map((ticket, index) => {
            const colors = STATUS_COLORS[ticket.status] || STATUS_COLORS.open
            return (
              <motion.button
                key={ticket.id}
                whileTap={{ scale: 0.99 }}
                onClick={() => openTicket(ticket)}
                style={{ width: '100%', textAlign: 'left', padding: '14px 16px', borderBottom: index < tickets.length - 1 ? '1px solid var(--border-light)' : 'none', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 12 }}
              >
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ fontSize: 14, fontWeight: 600, color: 'var(--text-primary)', fontFamily: 'Inter', margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {ticket.subject}
                  </p>
                  <p style={{ fontSize: 12, color: 'var(--text-tertiary)', fontFamily: 'Inter', margin: '3px 0 0' }}>
                    {ticket.id} · {ticket.category}
                  </p>
                </div>
                <span style={{ padding: '3px 8px', borderRadius: 999, flexShrink: 0, background: colors.bg, color: colors.text, border: `1px solid ${colors.border}`, fontSize: 11, fontWeight: 700, fontFamily: 'Inter', textTransform: 'capitalize' }}>
                  {ticket.status}
                </span>
                <ChevronRight size={16} style={{ color: 'var(--text-tertiary)', flexShrink: 0 }} />
              </motion.button>
            )
          })}
        </div>
      )}
    </motion.div>
  )
}
