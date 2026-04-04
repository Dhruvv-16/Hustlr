import pandas as pd
import joblib
from pathlib import Path
from xgboost import XGBClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

PROJECT_ROOT = Path(__file__).parent.parent.parent
MODELS_DIR   = PROJECT_ROOT / "outputs" / "trained_models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

def train_nlp_model():
    print("Training Model 4 — NLP Disruption Parser")
    
    heavy_rain_texts = [
        ("IMD issues orange alert for Chennai. Heavy rain expected with 68mm recorded in Adyar.", "heavy_rain"),
        ("Waterlogging reported in Velachery and T Nagar after 70mm rainfall overnight.", "heavy_rain"),
        ("Heavy rainfall warning for Chennai district. Tambaram residents advised to stay indoors.", "heavy_rain"),
        ("Downpour brings 65mm of rain to Guindy in 3 hours. Roads flooded near Anna Salai.", "heavy_rain"),
        ("IMD alert: intense rain with thunderstorm likely in Chennai tonight. 64.5mm threshold crossed.", "heavy_rain"),
        ("Chromepet neighbourhood flooded after 72mm rainfall. Anna Nagar also affected.", "heavy_rain"),
        ("Heavy rain disrupts delivery operations across Chennai. Velachery hardest hit with 80mm.", "heavy_rain"),
        ("Orange alert issued. Heavy rainfall of 66mm expected from 8 PM onwards in Chennai.", "heavy_rain"),
        ("Porur lake overflow fear as 75mm rain in 6 hours. IMD alert in place.", "heavy_rain"),
        ("Sholinganallur and Perungudi submerged. 69mm rainfall recorded at Meenambakkam station.", "heavy_rain"),
        ("Thunderstorm with heavy rain hits Chennai. Most areas receive over 65mm in 12 hours.", "heavy_rain"),
        ("Gig workers urged to stay safe as 71mm rainfall causes waterlogging in T Nagar.", "heavy_rain"),
        ("IMD heavy rainfall warning. Adyar river level rising after 78mm overnight rain.", "heavy_rain"),
        ("Delivery routes blocked in Tambaram, Pallavaram due to heavy rain and flooding.", "heavy_rain"),
        ("Orange alert active. 67mm rain recorded at Chennai airport. Low-lying areas warned.", "heavy_rain"),
    ]

    extreme_rain_texts = [
        ("IMD red alert: extremely heavy rainfall expected in Chennai. 200mm possible in 24 hours.", "extreme_rain"),
        ("NDMA advisory issued as cyclone watch announced for Tamil Nadu coast. Emergency teams deployed.", "extreme_rain"),
        ("Cyclone Michaung landfall near Chennai coast. Red alert issued. All services suspended.", "extreme_rain"),
        ("Extremely heavy rain of 120mm recorded in Velachery. Emergency advisory by Chennai corporation.", "extreme_rain"),
        ("Red alert for Tamil Nadu. Cyclone watch in effect. Very heavy rainfall expected 115mm+.", "extreme_rain"),
        ("115mm rainfall in Adyar in just 4 hours. NDMA emergency protocols activated.", "extreme_rain"),
        ("Chennai under red alert. Extremely heavy precipitation forecast. 200mm in 24 hours possible.", "extreme_rain"),
        ("Cyclone warning: residents in coastal Chennai asked to evacuate. Extreme precipitation expected.", "extreme_rain"),
        ("Very heavy rainfall of 130mm triggers emergency advisory. Chennai airport shut down.", "extreme_rain"),
        ("NDMA emergency: cyclone approaching Tamil Nadu coast. Red alert in all Chennai districts.", "extreme_rain"),
        ("Disaster management teams deployed as extremely heavy rain causes landslides near Tambaram.", "extreme_rain"),
        ("125mm rainfall in 6 hours breaks 50-year record for Guindy. Red alert still in effect.", "extreme_rain"),
    ]

    bandh_texts = [
        ("Tamil Nadu bandh called by AIADMK. All commercial activities halted across Chennai.", "bandh"),
        ("Section 144 imposed in Chennai after protest turns violent. Roads blocked in T Nagar.", "bandh"),
        ("Statewide strike by DMK workers disrupts delivery services across Tamil Nadu.", "bandh"),
        ("Bandh in Chennai today following political unrest. Shops shut, auto services suspended.", "bandh"),
        ("Hartal declared in parts of Tamil Nadu. Roads blocked by protestors near Guindy.", "bandh"),
        ("Curfew imposed in Tambaram and Velachery after communal tensions. Section 144 in effect.", "bandh"),
        ("Tamil Nadu shutdown: roads blocked, commercial halted. AIADMK, CPI, DMK coalition strike.", "bandh"),
        ("Complete shutdown in Chennai today due to AIADMK protest. Police deployed at key junctions.", "bandh"),
        ("Section 144 curfew in Anna Nagar, T Nagar. Delivery platforms pause operations.", "bandh"),
        ("All-party bandh observed in Tamil Nadu. Gig workers unable to operate across Chennai.", "bandh"),
        ("Political parties call shutdown. Streets empty in Adyar, Chromepet. Services suspended.", "bandh"),
        ("CPI-led strike disrupts morning deliveries. Section 144 imposed in several Chennai zones.", "bandh"),
    ]

    heat_texts = [
        ("IMD red alert for extreme heat. Temperature in Chennai reaches 44°C. Heat wave advisory.", "heat_wave"),
        ("Extreme heat warning for Tamil Nadu. Chennai records 43°C. Heat stroke risk high.", "heat_wave"),
        ("Heatwave conditions in Chennai. Temperature hits 45°C in Guindy and Anna Salai area.", "heat_wave"),
        ("IMD temperature advisory: 43 degrees expected this week. Outdoor workers at risk.", "heat_wave"),
        ("Heat stroke deaths reported in Tamil Nadu. Government issues heat wave warning. 44°C expected.", "heat_wave"),
        ("Extreme heat advisory for delivery workers. Temperature crosses 43 degrees in Chennai.", "heat_wave"),
        ("Summer heatwave hits Chennai. 44°C recorded at Meenambakkam. IMD issues red alert.", "heat_wave"),
        ("Dangerous heat wave conditions. Chennai city at 43°C. Workers advised to hydrate.", "heat_wave"),
        ("Temperature advisory issued: 45° in some parts of Tamil Nadu. Extreme heat risk.", "heat_wave"),
        ("IMD warns of severe heatwave. Chennai likely to see 43-44°C this week.", "heat_wave"),
        ("Heat wave emergency in Chennai. 44 degree temperatures affect outdoor delivery riders.", "heat_wave"),
    ]

    normal_texts = [
        ("Traffic moving smoothly on ECR highway. No disruptions reported this morning.", "normal"),
        ("Clear skies in Chennai today. Sunny with 28°C. Good conditions for outdoor work.", "normal"),
        ("Light drizzle reported in some parts of Chennai. No major disruptions expected.", "normal"),
        ("Normal weather conditions in Tamil Nadu. Delivery services operating at full capacity.", "normal"),
        ("Road widening work on OMR causes minor slowdown near Sholinganallur toll.", "normal"),
        ("Power outage in small area of Perambur restored within 30 minutes. No wider impact.", "normal"),
        ("Chennai weekend traffic slightly higher than usual. All roads functional.", "normal"),
        ("Mild cloudy conditions in Chennai. 32°C. Occasional light showers possible.", "normal"),
        ("Some congestion near Koyambedu market due to vegetable supply trucks.", "normal"),
        ("Intermittent light rain in Anna Nagar this morning. Roads passable. No alert.", "normal"),
        ("Festival celebrations slow traffic near Mylapore. Delivery rerouting advised.", "normal"),
        ("Maintenance work on water supply line near Adyar. Minor inconvenience expected.", "normal"),
        ("No weather alerts issued for Chennai today. Partly cloudy, 30°C.", "normal"),
        ("Moderate traffic on GST road near Guduvancherry tollgate. No incidents.", "normal"),
        ("Swiggy platform operating normally. No outages reported. Deliveries on time.", "normal"),
        ("Zomato services functioning normally. No platform disruptions.", "normal"),
        ("Metro rail operations normal. No delays on key Chennai routes.", "normal"),
        ("Light fog in some areas this morning. Visibility improving. No alerts.", "normal"),
        ("Sunny weather expected for next 3 days. No rain advisory from IMD.", "normal"),
        ("Small electrical fire near Taramani quickly doused. No service disruption.", "normal"),
    ]

    negation_traps = [
        "No heavy rain expected in Chennai today. IMD says conditions improving.",
        "Bandh called off after talks. Roads open in Tamil Nadu. Normal operations resume.",
        "Cyclone weakened to a depression before landfall. Red alert lifted.",
        "Heat wave advisory withdrawn. Temperature drops to 36°C in Chennai.",
        "Strike suspended after government intervention. Chennai back to normal.",
        "Orange alert cancelled. Rain subsiding in Chennai. Services resuming.",
        "NDMA advisory lifted. No longer a cyclone threat for Chennai coast.",
        "IMD downgraded to yellow alert. Heavy rain did not materialise.",
    ]
    
    corpus = [{"text": t, "label": l} for t, l in heavy_rain_texts + extreme_rain_texts + bandh_texts + heat_texts + normal_texts]
    corpus += [{"text": t, "label": "normal"} for t in negation_traps]
    
    df = pd.DataFrame(corpus)
    tfidf = TfidfVectorizer(max_features=2000, ngram_range=(1, 3), sublinear_tf=True, min_df=1, strip_accents="unicode", analyzer="word")
    X = tfidf.fit_transform(df["text"])
    y = df["label"]
    
    # Map labels to integers for XGBoost
    label_map = {l: i for i, l in enumerate(df["label"].unique())}
    y_encoded = df["label"].map(label_map)
    
    X_tr, X_te, y_tr, y_te = train_test_split(X, y_encoded, test_size=0.2, random_state=42, stratify=(df["label"] != "normal").astype(int))
    
    xgb_clf = XGBClassifier(
        n_estimators=300, 
        learning_rate=0.05, 
        max_depth=6, 
        random_state=42, 
        n_jobs=-1,
        tree_method='hist',
        device='cuda',
        objective='multi:softprob',
        num_class=len(label_map)
    )
    xgb_clf.fit(X_tr, y_tr)
    
    print(f"Test Accuracy (CUDA): {accuracy_score(y_te, xgb_clf.predict(X_te)):.4f}")
    
    # Save the label mapping inside the model meta or a separate file so inference works
    joblib.dump(label_map, MODELS_DIR / "model4_label_map.pkl")
    xgb_clf.save_model(MODELS_DIR / "model4_rf_nlp.json")
    joblib.dump(tfidf, MODELS_DIR / "model4_tfidf.pkl")
    print("Saved NLP model successfully.")

if __name__ == "__main__":
    train_nlp_model()
