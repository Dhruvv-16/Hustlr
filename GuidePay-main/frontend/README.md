# GuidePay — Income Protection for Delivery Workers

Parametric income insurance for gig delivery workers in India. Think PhonePe meets Swiggy.

## Quick Start

```bash
cd frontend
npm install
npm run dev
```

App runs at **http://localhost:5173**

## Demo Login

Enter any 10-digit number → OTP screen → enter **1234** → full app with mock data

## Screens

### Worker Flow
| Route | Screen |
|---|---|
| `/` | Login — phone + OTP trigger |
| `/otp` | OTP verification (enter 1234) |
| `/zone` | Zone & platform selection |
| `/risk-score` | AI risk score with animated ring |
| `/forecast` | 24-hour flood/disruption forecast |
| `/premium` | Weekly premium breakdown |
| `/dashboard` | Home — policy, alerts, stats, payouts |
| `/claim/cl-001` | Claim status with verification timeline |
| `/payout-success` | Payout confirmation |
| `/profile` | Profile, settings, logout |

### Admin Flow
| Route | Screen |
|---|---|
| `/admin` | Dashboard — KPIs, loss ratio, events |
| `/admin/claims` | Claims queue with fraud scores |
| `/admin/analytics` | 4 Recharts analytics charts |

## Tech Stack

- **React 18 + Vite 8** — framework
- **TailwindCSS 3** — utility styling
- **Framer Motion** — spring animations throughout
- **Zustand** — persisted state management
- **Recharts** — admin analytics charts
- **Lucide React** — icons
- **React Router v7** — routing with AnimatePresence page transitions

## Environment Variables

```
VITE_API_URL=https://your-backend.railway.app
VITE_USE_MOCK=true          # false = hit real API
VITE_GOOGLE_MAPS_KEY=       # for zone map on ZoneSelect
VITE_RAZORPAY_KEY=          # for payment on Premium screen
```

## Mock Mode

`VITE_USE_MOCK=true` (default) — all API calls return instant mock data. No backend needed to run.

## Design System

- **Fonts**: Bricolage Grotesque (headings/numbers) + Inter (body)
- **Brand**: `#D97757` warm orange — used sparingly
- **Background**: Always white `#FFFFFF`, never dark
- **Cards**: `shadow-card` soft shadow, no borders
- **Touch targets**: 48px minimum, 52px buttons
- **Max width**: 430px centered, shown as phone frame on desktop
