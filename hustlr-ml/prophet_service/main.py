from fastapi import FastAPI, HTTPException
from datetime import date
import joblib
import pandas as pd
import json
from prophet_model import forecast
from nudge_engine import run_wednesday_nudge
from monsoon_surcharge import calculate_surcharge

app = FastAPI(title="Hustlr Prophet Forecasting Engine")

@app.get("/forecast/{trigger_type}/{zone}")
def get_forecast(trigger_type: str, zone: str, days: int = 28):
    try:
        fcst = forecast(trigger_type, zone, forecast_horizon_days=days)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Model not found for trigger_type. Train first.")
    
    # Process for output
    # Convert dates for JSON
    fcst['ds'] = fcst['ds'].dt.strftime("%Y-%m-%d")
    
    peak_row = fcst.loc[fcst['probability_above_threshold'].idxmax()]
    peak_risk_date = peak_row['ds']
    peak_probability = float(peak_row['probability_above_threshold'])
    
    high_risk_days = int((fcst['probability_above_threshold'] > 0.60).sum())
    
    return {
        "forecast": fcst.to_dict(orient="records"),
        "summary": {
            "peak_risk_date": peak_risk_date,
            "peak_probability": round(peak_probability, 3),
            "high_risk_days": high_risk_days
        }
    }

@app.get("/nudge/{zone}/{plan_tier}")
def get_nudge(zone: str, plan_tier: str):
    if plan_tier not in ["Basic", "Standard", "Full"]:
        raise HTTPException(status_code=400, detail="Invalid plan tier")
    
    today = date.today()
    nudges = run_wednesday_nudge(today, zone, plan_tier)
    
    return {"nudges": nudges}

@app.get("/monsoon-surcharge")
def get_monsoon_surcharge(premium: int, date: str):
    try:
        d = pd.to_datetime(date).date()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
        
    return calculate_surcharge(premium, d)

@app.get("/forecast/health")
def forecast_health():
    # Only try to report on what is built
    TRIGGERS = ["heavy_rain", "extreme_rain", "platform_outage", "bandh", "heatwave"]
    health = {}
    
    for trig in TRIGGERS:
        try:
            m = joblib.load(f"prophet_{trig}.pkl")
            # Prophet doesn't natively store MAE metadata unless we hack it in,
            # but we can verify it loads. Real validation MAE reported during training.
            health[trig] = {
                "status": "loaded",
                "model_version": "1.0",
                "training_period": "2023-01-01 to 2025-06-30"
            }
        except FileNotFoundError:
            health[trig] = {"status": "not_found"}
            
    return {"models": health}
