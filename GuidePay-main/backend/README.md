# Guide-Pay Backend API

FastAPI backend for GuidePay parametric income insurance platform.

## Deploy to Render (Free Tier)

### Step 1: Push to GitHub
```bash
git add .
git commit -m "feat: complete Phase 2 backend"
git push origin main
```

### Step 2: Create Render account
Go to render.com → Sign up with GitHub

### Step 3: Create Web Service
1. New → Web Service
2. Connect GitHub repo
3. Settings:
   - Root Directory: backend
   - Environment: Python 3
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 1`
   - Plan: Free

### Step 4: Add Environment Variables
In Render dashboard → Environment tab:

```
MONGODB_URL = mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/guidepay
MONGODB_DB_NAME = guidepay
FIREBASE_PROJECT_ID = your-firebase-project-id
FIREBASE_PRIVATE_KEY_ID = your-private-key-id
FIREBASE_PRIVATE_KEY = (paste entire private key with \n)
FIREBASE_CLIENT_EMAIL = firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID = your-client-id
RAZORPAY_KEY_ID = rzp_test_your_key_here
RAZORPAY_KEY_SECRET = your_secret_here
RAZORPAY_MOCK_MODE = true
SECRET_KEY = generate-a-random-64-char-string-here
FRONTEND_URL = https://your-app.vercel.app
ENVIRONMENT = production
TRIGGER_POLL_INTERVAL_MINUTES = 15
```

### Step 5: Deploy
Click "Create Web Service" — wait 3-5 minutes.

### Step 6: Test
- Health: https://your-app.onrender.com/health
- Docs: https://your-app.onrender.com/docs

### Step 7: Connect Frontend
In Vercel dashboard for guidepayklu.vercel.app:
Settings → Environment Variables:
- VITE_API_URL = https://your-render-url.onrender.com
- VITE_USE_MOCK = false

Then Vercel → Deployments → Redeploy.

## Local Development

```bash
cd backend
python -m venv venv
venv\Scripts\activate     # Windows
pip install -r requirements.txt
cp .env.example .env
# Fill in .env values

# Train ML models (first time only)
python -m app.ml.train_models

# Start server
uvicorn app.main:app --reload --port 8000
# Docs: http://localhost:8000/docs
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| POST | /api/v1/auth/login | Firebase auth |
| GET | /api/v1/workers/me | Worker profile |
| GET | /api/v1/workers/me/premium-breakdown | ML premium |
| GET | /api/v1/workers/premium-compare | Zone comparison |
| GET | /api/v1/policies/my/active | Active policy |
| POST | /api/v1/payments/create-order | Create Razorpay order |
| POST | /api/v1/payments/verify | Verify payment |
| GET | /api/v1/claims/my | My claims |
| GET | /api/v1/triggers/active | Active triggers |
| GET | /api/v1/triggers/types | All 5 trigger types |
| GET | /api/v1/forecast/zones | Zone flood forecasts |
| GET | /api/v1/admin/stats | Admin stats |
| POST | /api/v1/admin/simulate-trigger | Simulate trigger |

## ML Architecture

Models trained on startup using synthetic data based on real NDMA/IMD flood statistics 2019-2024:
- **Fraud model**: GradientBoostingClassifier (6 features)
- **Flood model**: GradientBoostingClassifier (8 features)
- **Premium model**: RandomForestRegressor (9 features)
- **Anomaly model**: IsolationForest (unsupervised)
