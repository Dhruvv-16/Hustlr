import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { ShieldCheck } from 'lucide-react'
import { useWorkerStore } from '../../store/workerStore'
import { createUserProfile, loginWithFirebase } from '../../services/api'
import { signInWithEmail, signUpWithEmail } from '../../services/firebase'

const STEPS = [
  { id: 1, label: 'Account' },
  { id: 2, label: 'Coverage' },
  { id: 3, label: 'Payment' },
]

const labelStyle = {
  display: 'block', fontSize: 13, fontWeight: 500,
  fontFamily: 'Inter, sans-serif', color: '#6B6B6B', marginBottom: 6,
}

const inputStyle = {
  width: '100%', padding: '0 14px', height: 52,
  border: '1.5px solid #E4E4E7', borderRadius: 12,
  fontSize: 15, fontFamily: 'Inter, sans-serif', color: '#0F0F0F',
  outline: 'none', background: 'white', boxSizing: 'border-box',
}

export default function Register() {
  const navigate = useNavigate()
  const { login, setActivePolicy } = useWorkerStore()
  const [step, setStep] = useState(1)
  const [form, setForm] = useState({
    name: '', password: '', email: '', dob: '',
    platforms: [], zone: '', city: '',
    experience: '', avgDailyIncome: '', upiId: '',
  })

  const update = (key, val) => setForm(prev => ({ ...prev, [key]: val }))

  const completeWorkerLogin = (data) => {
    localStorage.setItem('gp-access-token', data.access_token)
    localStorage.setItem('gp-token', data.access_token)

    login({
      ...data.worker,
      zone: data.worker?.zone || form.zone || 'kondapur-hyderabad',
      riskScore: data.worker?.risk_score ?? 0.82,
      riskTier: data.worker?.risk_tier || 'LOW',
      premium: data.worker?.premium_amount ?? 58,
      coverageCap: 600,
      policyStatus: 'ACTIVE',
      platforms: data.worker?.platforms?.length ? data.worker.platforms : form.platforms,
    })
    setActivePolicy(true)
    navigate(data.requires_profile ? '/complete-profile' : '/dashboard')
  }

  const isFirebaseEmailAlreadyUsed = (error) =>
    error?.code === 'auth/email-already-in-use'

  const isUserAlreadyCreated = (error) =>
    error?.status === 409
    || error?.response?.status === 409
    || error?.detail === 'User already exists'

  const isBackendNetworkError = (error) =>
    error?.code === 'ERR_NETWORK'
    || /network error/i.test(error?.message || '')

  const canProceed = () => {
    if (step === 1) return form.name.trim().length >= 2 && form.email.length > 5 && form.password.length >= 6
    if (step === 2) return form.platforms.length > 0 && form.city
    if (step === 3) return form.upiId.trim().length > 3
    return true
  }

  const handleNext = async () => {
    if (step < 3) {
      setStep(step + 1)
    } else {
      const doLogin = async () => {
        try {
          let user
          try {
            user = await signUpWithEmail(form.email, form.password, form.name)
          } catch (signupError) {
            if (!isFirebaseEmailAlreadyUsed(signupError)) {
              throw signupError
            }
            user = await signInWithEmail(form.email, form.password)
          }

          try {
            const data = await createUserProfile({
              firebase_token: user.idToken,
              name: form.name,
              phone: '',
              city: form.city,
              zone: form.zone || form.city,
              upi_id: form.upiId || null,
              zone_lat: 0,
              zone_lng: 0,
            })

            completeWorkerLogin(data)
            return
          } catch (profileError) {
            if (isUserAlreadyCreated(profileError)) {
              const data = await loginWithFirebase(user.idToken, form.name, '')
              completeWorkerLogin(data)
              return
            }
            throw profileError
          }
        } catch (error) {
          console.error("Signup failed", error)
          const message = isBackendNetworkError(error)
            ? 'Signup failed: backend is not reachable at http://127.0.0.1:8000. Start the API server and try again.'
            : `Signup failed: ${error?.detail || error?.message || 'Unknown error'}`
          alert(message)
        }
      }

      if (window.Razorpay) {
        const rzp = new window.Razorpay({
          key: import.meta.env.VITE_RAZORPAY_KEY || 'rzp_test_demo',
          amount: 4900,
          currency: 'INR',
          name: 'GuidePay',
          description: 'First Week Income Protection',
          handler: doLogin,
          prefill: { name: form.name, email: form.email },
          theme: { color: '#D97757' },
        })
        rzp.open()
      } else {
        doLogin()
      }
    }
  }

  return (
    <div style={{
      minHeight: '100vh', background: '#FAFAFA',
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', padding: '24px 16px 80px',
    }}>
      {/* Logo */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        width: '100%', maxWidth: 480, margin: '0 auto 32px',
      }}>
        <ShieldCheck size={20} color="#D97757" />
        <span style={{ fontFamily: 'Bricolage Grotesque, sans-serif', fontSize: 16, fontWeight: 800, color: '#0F0F0F' }}>
          GuidePay
        </span>
      </div>

      <div style={{ width: '100%', maxWidth: 480 }}>
        {/* Step indicator */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 28 }}>
          {STEPS.map(s => (
            <div key={s.id} style={{ flex: 1 }}>
              <div style={{
                height: 3, borderRadius: 999,
                background: step >= s.id ? '#D97757' : '#E4E4E7',
                marginBottom: 8, transition: 'background 0.3s',
              }} />
              <p style={{
                fontSize: 11, fontFamily: 'Inter, sans-serif',
                fontWeight: step === s.id ? 600 : 400,
                color: step >= s.id ? '#D97757' : '#9B9B9B', margin: 0,
              }}>
                {s.label}
              </p>
            </div>
          ))}
        </div>

        {/* Heading */}
        <h1 style={{
          fontFamily: 'Bricolage Grotesque, sans-serif',
          fontSize: 26, fontWeight: 800, color: '#0F0F0F', marginBottom: 4,
        }}>
          {step === 1 && 'Create your account'}
          {step === 2 && 'Set up your coverage'}
          {step === 3 && 'Complete payment'}
        </h1>
        <p style={{ fontSize: 14, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', marginBottom: 24 }}>
          {step === 1 && 'Basic details to get you protected'}
          {step === 2 && 'Tell us about your delivery work'}
          {step === 3 && 'Start your first week of protection'}
        </p>

        {/* Step content */}
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.2 }}
          >
            {step === 1 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <div>
                  <label style={labelStyle}>Full name</label>
                  <input style={inputStyle} placeholder="As on your Aadhaar"
                    value={form.name} onChange={e => update('name', e.target.value)} />
                </div>
                <div>
                  <label style={labelStyle}>Email address</label>
                  <input style={inputStyle} placeholder="ravi@example.com" type="email"
                    value={form.email} onChange={e => update('email', e.target.value)} />
                </div>
                <div>
                  <label style={labelStyle}>Password</label>
                  <input style={inputStyle} placeholder="••••••••" type="password"
                    value={form.password} onChange={e => update('password', e.target.value)} />
                  {form.password && form.password.length < 6 && (
                    <p style={{ fontSize: 13, color: '#F04438', fontFamily: 'Inter, sans-serif', marginTop: 4 }}>
                      Password must be at least 6 characters
                    </p>
                  )}
                </div>
                <div>
                  <label style={labelStyle}>Date of birth</label>
                  <input style={inputStyle} type="date"
                    value={form.dob} onChange={e => update('dob', e.target.value)} />
                  <p style={{ fontSize: 11, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginTop: 4 }}>
                    Must be 18+ to get coverage
                  </p>
                </div>
                <div>
                  <label style={labelStyle}>Average daily income (₹)</label>
                  <input style={inputStyle} placeholder="e.g. 800" type="number"
                    value={form.avgDailyIncome} onChange={e => update('avgDailyIncome', e.target.value)} />
                  <p style={{ fontSize: 11, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginTop: 4 }}>
                    Used to calculate your coverage cap accurately
                  </p>
                </div>
                <div>
                  <label style={labelStyle}>How long have you been delivering?</label>
                  <select style={inputStyle} value={form.experience} onChange={e => update('experience', e.target.value)}>
                    <option value="">Select experience</option>
                    <option value="0-3">Less than 3 months</option>
                    <option value="3-6">3–6 months</option>
                    <option value="6-12">6–12 months</option>
                    <option value="1-2">1–2 years</option>
                    <option value="2+">2+ years</option>
                  </select>
                </div>
              </div>
            )}

            {step === 2 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                <div>
                  <label style={labelStyle}>Which platforms do you deliver for?</label>
                  <p style={{ fontSize: 12, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginBottom: 12 }}>
                    Select all that apply
                  </p>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                    {[
                      { id: 'zepto',   name: 'Zepto',   emoji: '🟢', sub: 'Q-commerce' },
                      { id: 'swiggy',  name: 'Swiggy',  emoji: '🟠', sub: 'Food delivery' },
                      { id: 'blinkit', name: 'Blinkit', emoji: '🔴', sub: 'Q-commerce' },
                      { id: 'amazon',  name: 'Amazon',  emoji: '🔵', sub: 'E-commerce' },
                    ].map(p => {
                      const selected = form.platforms.includes(p.id)
                      return (
                        <motion.button
                          key={p.id}
                          onClick={() => update('platforms', selected
                            ? form.platforms.filter(x => x !== p.id)
                            : [...form.platforms, p.id]
                          )}
                          whileTap={{ scale: 0.96 }}
                          style={{
                            padding: 14, borderRadius: 12,
                            border: selected ? '1.5px solid #D97757' : '1.5px solid #E4E4E7',
                            background: selected ? '#FDF1ED' : 'white',
                            cursor: 'pointer', textAlign: 'left',
                            display: 'flex', alignItems: 'center', gap: 10,
                          }}
                        >
                          <span style={{ fontSize: 20 }}>{p.emoji}</span>
                          <div>
                            <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: selected ? '#B85C3A' : '#0F0F0F', margin: 0 }}>
                              {p.name}
                            </p>
                            <p style={{ fontSize: 11, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', margin: 0 }}>
                              {p.sub}
                            </p>
                          </div>
                          {selected && <span style={{ marginLeft: 'auto', fontSize: 14, color: '#D97757' }}>✓</span>}
                        </motion.button>
                      )
                    })}
                  </div>
                </div>

                <div>
                  <label style={labelStyle}>Your delivery city</label>
                  <select style={inputStyle} value={form.city} onChange={e => update('city', e.target.value)}>
                    <option value="">Select your city</option>
                    <option value="hyderabad">Hyderabad</option>
                    <option value="mumbai">Mumbai</option>
                    <option value="bengaluru">Bengaluru</option>
                    <option value="chennai">Chennai</option>
                    <option value="delhi">Delhi</option>
                    <option value="pune">Pune</option>
                    <option value="kolkata">Kolkata</option>
                  </select>
                </div>

                <div>
                  <label style={labelStyle}>Primary delivery area / zone</label>
                  <input style={inputStyle} placeholder="e.g. Kondapur, Banjara Hills..."
                    value={form.zone} onChange={e => update('zone', e.target.value)} />
                  <p style={{ fontSize: 11, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginTop: 4 }}>
                    We'll geofence a 5km radius around your zone
                  </p>
                </div>
              </div>
            )}

            {step === 3 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <div style={{
                  background: '#FDF1ED', borderRadius: 14, padding: 16,
                  border: '1px solid rgba(217,119,87,0.2)',
                }}>
                  <p style={{ fontSize: 11, fontWeight: 700, fontFamily: 'Inter, sans-serif', color: '#D97757', letterSpacing: '1px', textTransform: 'uppercase', margin: '0 0 10px' }}>
                    Your coverage summary
                  </p>
                  {[
                    { label: 'Name',              value: form.name || 'Your name' },
                    { label: 'City',              value: form.city || 'Your city' },
                    { label: 'Platforms',         value: form.platforms.join(', ') || 'None selected' },
                    { label: 'Estimated premium', value: '₹49–69/week' },
                    { label: 'Coverage cap',      value: '₹600/week' },
                  ].map(row => (
                    <div key={row.label} style={{
                      display: 'flex', justifyContent: 'space-between',
                      padding: '6px 0', borderBottom: '1px solid rgba(217,119,87,0.1)',
                    }}>
                      <span style={{ fontSize: 12, color: '#B85C3A', fontFamily: 'Inter, sans-serif' }}>{row.label}</span>
                      <span style={{ fontSize: 12, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#0F0F0F' }}>{row.value}</span>
                    </div>
                  ))}
                </div>

                <div>
                  <label style={labelStyle}>UPI ID for payouts</label>
                  <input style={inputStyle} placeholder="ravi@okaxis or 98765@paytm"
                    value={form.upiId} onChange={e => update('upiId', e.target.value)} />
                  <p style={{ fontSize: 11, color: '#9B9B9B', fontFamily: 'Inter, sans-serif', marginTop: 4 }}>
                    Payouts are credited directly to this UPI ID
                  </p>
                </div>

                <div style={{
                  background: '#ECFDF3', borderRadius: 12, padding: 14,
                  border: '1px solid rgba(18,183,106,0.2)',
                  display: 'flex', gap: 10, alignItems: 'flex-start',
                }}>
                  <span style={{ fontSize: 16 }}>🔒</span>
                  <div>
                    <p style={{ fontSize: 13, fontWeight: 600, fontFamily: 'Inter, sans-serif', color: '#065F46', margin: '0 0 2px' }}>
                      Secure payment via Razorpay
                    </p>
                    <p style={{ fontSize: 12, color: '#065F46', fontFamily: 'Inter, sans-serif', opacity: 0.8, margin: 0 }}>
                      Your premium is auto-debited every Sunday. Cancel anytime from Profile.
                    </p>
                  </div>
                </div>

                <div style={{ padding: 14, borderRadius: 12, border: '1px solid #E4E4E7', background: 'white' }}>
                  <p style={{ fontSize: 12, color: '#6B6B6B', fontFamily: 'Inter, sans-serif', margin: 0, lineHeight: 1.5 }}>
                    By continuing, you agree to our{' '}
                    <a href="/terms" style={{ color: '#D97757' }}>Terms of Service</a>
                    {' '}and{' '}
                    <a href="/privacy" style={{ color: '#D97757' }}>Privacy Policy</a>.
                    Coverage begins immediately after payment.
                  </p>
                </div>
              </div>
            )}
          </motion.div>
        </AnimatePresence>

        {/* Navigation */}
        <div style={{ display: 'flex', gap: 10, marginTop: 28 }}>
          {step > 1 && (
            <motion.button
              onClick={() => setStep(step - 1)}
              whileTap={{ scale: 0.97 }}
              style={{
                padding: '13px 20px', borderRadius: 10,
                border: '1.5px solid #E4E4E7', background: 'white',
                fontSize: 14, fontWeight: 600, fontFamily: 'Inter, sans-serif',
                color: '#0F0F0F', cursor: 'pointer',
              }}
            >
              ← Back
            </motion.button>
          )}
          <motion.button
            onClick={handleNext}
            disabled={!canProceed()}
            whileTap={canProceed() ? { scale: 0.97 } : {}}
            style={{
              flex: 1, padding: '13px', borderRadius: 10, border: 'none',
              background: canProceed() ? 'linear-gradient(135deg, #D97757, #B85C3A)' : '#E4E4E7',
              color: canProceed() ? 'white' : '#9B9B9B',
              fontSize: 15, fontWeight: 700, fontFamily: 'Inter, sans-serif',
              cursor: canProceed() ? 'pointer' : 'not-allowed',
              boxShadow: canProceed() ? '0 4px 16px rgba(217,119,87,0.35)' : 'none',
              transition: 'all 0.2s',
            }}
          >
            {step < 3 ? 'Continue →' : 'Pay & Get Protected →'}
          </motion.button>
        </div>

        <p style={{ textAlign: 'center', marginTop: 20, fontSize: 13, color: '#9B9B9B', fontFamily: 'Inter, sans-serif' }}>
          Already have an account?{' '}
          <span onClick={() => navigate('/login')} style={{ color: '#D97757', fontWeight: 600, cursor: 'pointer' }}>
            Sign in
          </span>
        </p>
      </div>
    </div>
  )
}
