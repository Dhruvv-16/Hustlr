import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { MessageCircle, X, ChevronRight, ArrowLeft } from 'lucide-react'
import { faqs, categories } from './faqData'

export const ChatWidget = () => {
  const [isOpen, setIsOpen] = useState(false)
  const [view, setView] = useState('list')
  const [activeCategory, setActiveCategory] = useState('all')
  const [activeFaq, setActiveFaq] = useState(null)

  const filtered = activeCategory === 'all'
    ? faqs
    : faqs.filter(f => f.category === activeCategory)

  const handleFaqClick = (faq) => {
    setActiveFaq(faq)
    setView('answer')
  }

  return (
    <>
      {/* FLOATING BUTTON */}
      <motion.button
        id="chat-btn"
        onClick={() => setIsOpen(true)}
        style={{
          position: 'fixed',
          bottom: 80,
          right: 16,
          zIndex: 90,
          width: 52,
          height: 52,
          borderRadius: 999,
          background: 'var(--brand, #D97757)',
          border: 'none',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 4px 20px rgba(217,119,87,0.4)',
        }}
        whileHover={{ scale: 1.08 }}
        whileTap={{ scale: 0.92 }}
        animate={{ y: isOpen ? 100 : 0, opacity: isOpen ? 0 : 1 }}
        aria-label="Open support chat"
      >
        <MessageCircle size={22} color="white" />
        <div style={{
          position: 'absolute',
          top: 10, right: 10,
          width: 8, height: 8,
          borderRadius: 999,
          background: '#12B76A',
          border: '2px solid white',
        }} />
      </motion.button>

      {/* BACKDROP */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsOpen(false)}
            style={{
              position: 'fixed',
              inset: 0,
              background: 'rgba(0,0,0,0.3)',
              zIndex: 95,
            }}
          />
        )}
      </AnimatePresence>

      {/* CHAT PANEL */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 300, damping: 35 }}
            style={{
              position: 'fixed',
              bottom: 0,
              left: 0,
              right: 0,
              height: '70vh',
              maxHeight: 560,
              background: 'var(--bg-card, #FFFFFF)',
              borderRadius: '20px 20px 0 0',
              zIndex: 100,
              display: 'flex',
              flexDirection: 'column',
              overflow: 'hidden',
              boxShadow: '0 -8px 40px rgba(0,0,0,0.15)',
            }}
          >
            {/* Drag handle */}
            <div style={{
              width: 40, height: 4,
              background: 'var(--border, #E4E4E7)',
              borderRadius: 999,
              margin: '12px auto 0',
              flexShrink: 0,
            }} />

            {/* HEADER */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '12px 16px',
              borderBottom: '1px solid var(--border-light, #F4F4F5)',
              flexShrink: 0,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                {view === 'answer' && (
                  <motion.button
                    onClick={() => setView('list')}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, display: 'flex' }}
                    whileTap={{ scale: 0.9 }}
                  >
                    <ArrowLeft size={18} style={{ color: 'var(--text-primary)' }} />
                  </motion.button>
                )}
                <div style={{
                  width: 32, height: 32,
                  borderRadius: 999,
                  background: 'var(--brand-light, #FDF1ED)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <MessageCircle size={16} style={{ color: 'var(--brand, #D97757)' }} />
                </div>
                <div>
                  <p style={{
                    fontSize: 15,
                    fontWeight: 600,
                    fontFamily: 'Bricolage Grotesque, sans-serif',
                    color: 'var(--text-primary)',
                    margin: 0,
                  }}>Support</p>
                  <p style={{
                    fontSize: 11,
                    color: 'var(--success, #12B76A)',
                    margin: 0,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 4,
                  }}>
                    <span style={{
                      width: 6, height: 6,
                      borderRadius: 999,
                      background: '#12B76A',
                      display: 'inline-block',
                    }} />
                    Online
                  </p>
                </div>
              </div>
              <motion.button
                onClick={() => setIsOpen(false)}
                style={{
                  background: 'var(--bg-secondary, #F7F7F8)',
                  border: 'none',
                  borderRadius: 999,
                  width: 32, height: 32,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
                whileTap={{ scale: 0.9 }}
              >
                <X size={16} style={{ color: 'var(--text-secondary)' }} />
              </motion.button>
            </div>

            {/* BODY */}
            <div style={{ flex: 1, overflowY: 'auto' }}>

              {/* LIST VIEW */}
              {view === 'list' && (
                <div>
                  <div style={{ padding: '16px 16px 8px' }}>
                    <div style={{
                      background: 'var(--bg-secondary, #F7F7F8)',
                      borderRadius: '4px 12px 12px 12px',
                      padding: '10px 14px',
                      display: 'inline-block',
                      maxWidth: '85%',
                    }}>
                      <p style={{ fontSize: 14, color: 'var(--text-primary)', margin: 0, lineHeight: 1.5 }}>
                        Hi 👋 What can I help you with today?
                      </p>
                    </div>
                  </div>

                  {/* Category pills */}
                  <div style={{
                    display: 'flex',
                    gap: 8,
                    padding: '8px 16px',
                    overflowX: 'auto',
                    scrollbarWidth: 'none',
                  }}>
                    {categories.map(cat => (
                      <motion.button
                        key={cat.id}
                        onClick={() => setActiveCategory(cat.id)}
                        style={{
                          flexShrink: 0,
                          padding: '6px 14px',
                          borderRadius: 999,
                          fontSize: 12,
                          fontWeight: 500,
                          fontFamily: 'Inter, sans-serif',
                          cursor: 'pointer',
                          border: activeCategory === cat.id
                            ? '1px solid var(--brand, #D97757)'
                            : '1px solid var(--border, #E4E4E7)',
                          background: activeCategory === cat.id
                            ? 'var(--brand-light, #FDF1ED)'
                            : 'var(--bg-secondary, #F7F7F8)',
                          color: activeCategory === cat.id
                            ? 'var(--brand, #D97757)'
                            : 'var(--text-secondary)',
                          transition: 'all 0.15s',
                        }}
                        whileTap={{ scale: 0.95 }}
                      >
                        {cat.label}
                      </motion.button>
                    ))}
                  </div>

                  {/* FAQ items */}
                  <div style={{ padding: '0 16px 80px' }}>
                    {filtered.map((faq, i) => (
                      <motion.div
                        key={faq.id}
                        onClick={() => handleFaqClick(faq)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '14px 0',
                          borderBottom: i < filtered.length - 1
                            ? '1px solid var(--border-light, #F4F4F5)'
                            : 'none',
                          cursor: 'pointer',
                          gap: 12,
                        }}
                        whileTap={{ x: 4 }}
                      >
                        <p style={{
                          fontSize: 14,
                          color: 'var(--text-primary)',
                          margin: 0,
                          lineHeight: 1.4,
                          fontFamily: 'Inter, sans-serif',
                        }}>
                          {faq.question}
                        </p>
                        <ChevronRight size={16} style={{ color: 'var(--text-tertiary)', flexShrink: 0 }} />
                      </motion.div>
                    ))}
                  </div>
                </div>
              )}

              {/* ANSWER VIEW */}
              {view === 'answer' && (
                <div style={{ padding: 16 }}>
                  <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
                    <div style={{
                      background: 'var(--brand-light, #FDF1ED)',
                      borderRadius: '12px 12px 4px 12px',
                      padding: '10px 14px',
                      maxWidth: '85%',
                    }}>
                      <p style={{
                        fontSize: 14,
                        color: 'var(--brand-dark, #B85C3A)',
                        margin: 0,
                        lineHeight: 1.5,
                        fontFamily: 'Inter, sans-serif',
                      }}>
                        {activeFaq?.question}
                      </p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
                    <div style={{
                      width: 28, height: 28,
                      borderRadius: 999,
                      background: 'var(--brand-light, #FDF1ED)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}>
                      <MessageCircle size={14} style={{ color: 'var(--brand, #D97757)' }} />
                    </div>
                    <div style={{
                      background: 'var(--bg-secondary, #F7F7F8)',
                      borderRadius: '4px 12px 12px 12px',
                      padding: '12px 14px',
                      flex: 1,
                    }}>
                      <p style={{
                        fontSize: 14,
                        color: 'var(--text-primary)',
                        margin: 0,
                        lineHeight: 1.6,
                        fontFamily: 'Inter, sans-serif',
                      }}>
                        {activeFaq?.answer}
                      </p>
                    </div>
                  </div>

                  {activeFaq?.followUps?.length > 0 && (
                    <div>
                      <p style={{
                        fontSize: 12,
                        color: 'var(--text-tertiary)',
                        marginBottom: 8,
                        fontFamily: 'Inter, sans-serif',
                      }}>
                        Related questions
                      </p>
                      {activeFaq.followUps.map(id => {
                        const f = faqs.find(q => q.id === id)
                        if (!f) return null
                        return (
                          <motion.div
                            key={id}
                            onClick={() => handleFaqClick(f)}
                            style={{
                              padding: '10px 14px',
                              border: '1px solid var(--border, #E4E4E7)',
                              borderRadius: 10,
                              marginBottom: 8,
                              cursor: 'pointer',
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center',
                              background: 'var(--bg-card, #FFFFFF)',
                            }}
                            whileTap={{ scale: 0.98 }}
                          >
                            <p style={{
                              fontSize: 13,
                              color: 'var(--text-primary)',
                              margin: 0,
                              fontFamily: 'Inter, sans-serif',
                            }}>
                              {f.question}
                            </p>
                            <ChevronRight size={14} style={{ color: 'var(--text-tertiary)', flexShrink: 0, marginLeft: 8 }} />
                          </motion.div>
                        )
                      })}
                    </div>
                  )}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}

export default ChatWidget
