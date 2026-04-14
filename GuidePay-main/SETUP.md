# Setup Guide — GuidePay

## Free APIs Required

### 1. MongoDB Atlas (Free)
- **URL:** https://mongodb.com/atlas
- **Plan:** M0 Free Tier
- **Used for:** All application data storage
- **Setup:**
  1. Create account at mongodb.com/atlas
  2. Create free cluster (choose Mumbai region)
  3. Database Access → Add database user
  4. Network Access → Add 0.0.0.0/0 (or Render IP)
  5. Connect → Drivers → Copy connection string
  6. Add to backend `.env` as `MONGODB_URL`
  7. *URL-encode special characters in password:*
     - `#` becomes `%23`
     - `@` becomes `%40`

### 2. Firebase (Free)
- **URL:** https://console.firebase.google.com
- **Plan:** Spark (free)
- **Used for:** Phone OTP authentication
- **Setup:**
  1. Create project at Firebase Console
  2. Authentication → Sign-in method → Enable Phone
  3. Authentication → Sign-in method → Enable Google
  4. Project Settings → Your apps → Add web app
     - Copy config to frontend `.env`
  5. Project Settings → Service accounts
     - Generate new private key → Download JSON
     - Copy values to backend `.env`

### 3. OpenWeatherMap (Free)
- **URL:** https://openweathermap.org/api
- **Plan:** Free (1000 calls/day)
- **Used for:** AQI alerts and rainfall forecasts
- **Setup:**
  1. Create account at openweathermap.org
  2. My API Keys → Copy default key
  3. Add to backend `.env` as `OPENWEATHER_API_KEY`

### 4. Google Maps (Free tier)
- **URL:** https://console.cloud.google.com
- **Plan:** $200 monthly credit (more than enough)
- **Used for:** Zone selection map
- **Setup:**
  1. Create project at Google Cloud Console
  2. Enable Maps JavaScript API
  3. Enable Geocoding API
  4. APIs & Services → Credentials → Create API Key
  5. Restrict key to your domain
  6. Add to frontend `.env` as `VITE_GOOGLE_MAPS_KEY`

### 5. IMD SACHET RSS (Free, no key needed)
- **URL:** https://sachet.ndma.gov.in
- **Used for:** Real flood alerts
- **Setup:** No pickup required.

---

## Deployment

### Frontend → Vercel
1. Connect GitHub repo at vercel.com
2. Root directory: `frontend`
3. Add all `VITE_` environment variables
4. Deploy

### Backend → Render
1. Connect GitHub repo at render.com
2. Root directory: `backend`
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add all environment variables
6. Deploy

---

> **Note:** Never commit `.env` files. All secrets go in environment variables only. See `.env.example` files for required variables.
