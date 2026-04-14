export const faqs = [
  {
    id: 1, category: 'coverage',
    question: 'What does GuidePay cover?',
    answer: 'GuidePay covers income lost during three events: IMD flood or heavy rain alerts, platform app outages (Zepto, Swiggy, Blinkit, Amazon), and government curfews. You receive up to ₹600/week automatically — no claim needed.',
    followUps: [2, 4],
  },
  {
    id: 2, category: 'coverage',
    question: 'Why is air pollution (AQI) not covered?',
    answer: 'Platforms like Zepto and Swiggy keep running during pollution events — orders actually go up. Since your income is not directly stopped, we cannot cover it. We only cover events that physically prevent you from earning.',
    followUps: [1, 3],
  },
  {
    id: 3, category: 'coverage',
    question: 'What is NOT covered?',
    answer: 'Health issues, vehicle repairs, accidents, and situations where you choose not to work are not covered. GuidePay only covers external events that stop platform operations entirely.',
    followUps: [1, 4],
  },
  {
    id: 4, category: 'payout',
    question: 'How quickly do I get paid?',
    answer: 'Within 2 hours of a confirmed event. You do not need to do anything — GuidePay detects the event, verifies you were working, and sends money to your UPI automatically.',
    followUps: [5, 6],
  },
  {
    id: 5, category: 'payout',
    question: 'How much will I receive?',
    answer: 'Up to ₹600/week. Flood alerts and curfews pay 100% (₹600). Platform outages pay 75% (₹450) because you might be able to work on another platform. Final amount depends on your activity before the event.',
    followUps: [4, 6],
  },
  {
    id: 6, category: 'payout',
    question: 'How does GuidePay know I was working?',
    answer: 'We check your last completed delivery before the event. If your last order was within 2 hours, you get full payout. 2–6 hours gets partial payout. Over 6 hours and your claim goes to manual review.',
    followUps: [4, 5],
  },
  {
    id: 7, category: 'premium',
    question: 'How is my weekly premium calculated?',
    answer: 'Base ₹49 × zone flood risk × your reliability score. Workers in high flood zones pay more. Consistent, active workers get a discount. Your exact breakdown is shown before you activate.',
    followUps: [8, 9],
  },
  {
    id: 8, category: 'premium',
    question: 'How do I get a lower premium?',
    answer: 'Keep delivering consistently, avoid unverified claims, and maintain high active hours. A risk score above 0.75 gets you a 15% discount automatically — about ₹7/week saved.',
    followUps: [7, 9],
  },
  {
    id: 9, category: 'premium',
    question: 'When is premium deducted?',
    answer: 'Every Sunday via UPI auto-debit. Coverage runs Monday to Sunday. You get a reminder notification before each deduction.',
    followUps: [7, 8],
  },
  {
    id: 10, category: 'claims',
    question: 'What if my claim is flagged?',
    answer: 'You will get one in-app prompt to confirm your location with a single tap. Honest workers are resolved within 4 hours. You will never be told you are suspected of fraud — only that your zone had high activity.',
    followUps: [6, 11],
  },
  {
    id: 11, category: 'general',
    question: 'How do I cancel coverage?',
    answer: 'Go to Profile → Manage Coverage → Cancel. Takes effect at the end of your current week. No cancellation fee.',
    followUps: [9, 12],
  },
  {
    id: 12, category: 'general',
    question: 'Which platforms are covered?',
    answer: 'Zepto, Swiggy, Blinkit, and Amazon delivery. Outages are verified via Downdetector and the platform status page before any payout.',
    followUps: [1, 4],
  },
]

export const categories = [
  { id: 'all',      label: 'All' },
  { id: 'coverage', label: 'Coverage' },
  { id: 'payout',   label: 'Payouts' },
  { id: 'premium',  label: 'Premium' },
  { id: 'claims',   label: 'Claims' },
  { id: 'general',  label: 'General' },
]
