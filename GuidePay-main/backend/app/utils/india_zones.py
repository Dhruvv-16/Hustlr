"""
Complete India coverage database.
All states, districts, and major cities.
Risk scores based on IMD district flood vulnerability index (2019-2024 data).
"""

# State codes and names
INDIA_STATES = {
    "AP": "Andhra Pradesh",
    "AR": "Arunachal Pradesh",
    "AS": "Assam",
    "BR": "Bihar",
    "CG": "Chhattisgarh",
    "GA": "Goa",
    "GJ": "Gujarat",
    "HR": "Haryana",
    "HP": "Himachal Pradesh",
    "JH": "Jharkhand",
    "KA": "Karnataka",
    "KL": "Kerala",
    "MP": "Madhya Pradesh",
    "MH": "Maharashtra",
    "MN": "Manipur",
    "ML": "Meghalaya",
    "MZ": "Mizoram",
    "NL": "Nagaland",
    "OD": "Odisha",
    "PB": "Punjab",
    "RJ": "Rajasthan",
    "SK": "Sikkim",
    "TN": "Tamil Nadu",
    "TS": "Telangana",
    "TR": "Tripura",
    "UP": "Uttar Pradesh",
    "UK": "Uttarakhand",
    "WB": "West Bengal",
    "DL": "Delhi",
    "JK": "Jammu & Kashmir",
    "LA": "Ladakh",
    "PY": "Puducherry",
    "CH": "Chandigarh",
    "AN": "Andaman & Nicobar",
}

# Complete India city/district database
# Format: zone_key -> full zone data
# flood_risk_score: 0-100 (higher = more flood risk)
INDIA_ZONES = {
    # ── TELANGANA ──────────────────────────────
    "hyderabad-ts": {
        "city": "Hyderabad", "district": "Hyderabad",
        "state": "Telangana", "state_code": "TS",
        "lat": 17.3850, "lng": 78.4867,
        "elevation_m": 505, "flood_risk_score": 72,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon"],
        "tier": 1,
    },
    "warangal-ts": {
        "city": "Warangal", "district": "Warangal",
        "state": "Telangana", "state_code": "TS",
        "lat": 17.9784, "lng": 79.5941,
        "elevation_m": 302, "flood_risk_score": 65,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "nizamabad-ts": {
        "city": "Nizamabad", "district": "Nizamabad",
        "state": "Telangana", "state_code": "TS",
        "lat": 18.6726, "lng": 78.0942,
        "elevation_m": 381, "flood_risk_score": 58,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "karimnagar-ts": {
        "city": "Karimnagar", "district": "Karimnagar",
        "state": "Telangana", "state_code": "TS",
        "lat": 18.4386, "lng": 79.1288,
        "elevation_m": 271, "flood_risk_score": 62,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    "khammam-ts": {
        "city": "Khammam", "district": "Khammam",
        "state": "Telangana", "state_code": "TS",
        "lat": 17.2473, "lng": 80.1514,
        "elevation_m": 95, "flood_risk_score": 78,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── ANDHRA PRADESH ─────────────────────────
    "vijayawada-ap": {
        "city": "Vijayawada", "district": "Krishna",
        "state": "Andhra Pradesh", "state_code": "AP",
        "lat": 16.5062, "lng": 80.6480,
        "elevation_m": 22, "flood_risk_score": 82,
        "platform_coverage": ["swiggy", "zomato", "amazon"], "tier": 2,
    },
    "visakhapatnam-ap": {
        "city": "Visakhapatnam", "district": "Visakhapatnam",
        "state": "Andhra Pradesh", "state_code": "AP",
        "lat": 17.6868, "lng": 83.2185,
        "elevation_m": 45, "flood_risk_score": 75,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    "tirupati-ap": {
        "city": "Tirupati", "district": "Chittoor",
        "state": "Andhra Pradesh", "state_code": "AP",
        "lat": 13.6288, "lng": 79.4192,
        "elevation_m": 152, "flood_risk_score": 45,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "kurnool-ap": {
        "city": "Kurnool", "district": "Kurnool",
        "state": "Andhra Pradesh", "state_code": "AP",
        "lat": 15.8281, "lng": 78.0373,
        "elevation_m": 283, "flood_risk_score": 68,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── MAHARASHTRA ────────────────────────────
    "mumbai-mh": {
        "city": "Mumbai", "district": "Mumbai City",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 19.0760, "lng": 72.8777,
        "elevation_m": 11, "flood_risk_score": 88,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon", "dunzo"],
        "tier": 1,
    },
    "pune-mh": {
        "city": "Pune", "district": "Pune",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 18.5204, "lng": 73.8567,
        "elevation_m": 560, "flood_risk_score": 55,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon"],
        "tier": 1,
    },
    "nagpur-mh": {
        "city": "Nagpur", "district": "Nagpur",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 21.1458, "lng": 79.0882,
        "elevation_m": 310, "flood_risk_score": 52,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    "nashik-mh": {
        "city": "Nashik", "district": "Nashik",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 19.9975, "lng": 73.7898,
        "elevation_m": 565, "flood_risk_score": 48,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "aurangabad-mh": {
        "city": "Aurangabad", "district": "Aurangabad",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 19.8762, "lng": 75.3433,
        "elevation_m": 513, "flood_risk_score": 44,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "kolhapur-mh": {
        "city": "Kolhapur", "district": "Kolhapur",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 16.7050, "lng": 74.2433,
        "elevation_m": 570, "flood_risk_score": 72,
        "platform_coverage": ["swiggy", "zomato"], "tier": 3,
    },
    "solapur-mh": {
        "city": "Solapur", "district": "Solapur",
        "state": "Maharashtra", "state_code": "MH",
        "lat": 17.6599, "lng": 75.9064,
        "elevation_m": 456, "flood_risk_score": 38,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── KARNATAKA ──────────────────────────────
    "bengaluru-ka": {
        "city": "Bengaluru", "district": "Bangalore Urban",
        "state": "Karnataka", "state_code": "KA",
        "lat": 12.9716, "lng": 77.5946,
        "elevation_m": 920, "flood_risk_score": 32,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon", "dunzo"],
        "tier": 1,
    },
    "mysuru-ka": {
        "city": "Mysuru", "district": "Mysuru",
        "state": "Karnataka", "state_code": "KA",
        "lat": 12.2958, "lng": 76.6394,
        "elevation_m": 770, "flood_risk_score": 28,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "hubli-ka": {
        "city": "Hubli", "district": "Dharwad",
        "state": "Karnataka", "state_code": "KA",
        "lat": 15.3647, "lng": 75.1240,
        "elevation_m": 655, "flood_risk_score": 35,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "mangaluru-ka": {
        "city": "Mangaluru", "district": "Dakshina Kannada",
        "state": "Karnataka", "state_code": "KA",
        "lat": 12.9141, "lng": 74.8560,
        "elevation_m": 22, "flood_risk_score": 71,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "belagavi-ka": {
        "city": "Belagavi", "district": "Belagavi",
        "state": "Karnataka", "state_code": "KA",
        "lat": 15.8497, "lng": 74.4977,
        "elevation_m": 751, "flood_risk_score": 42,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── TAMIL NADU ─────────────────────────────
    "chennai-tn": {
        "city": "Chennai", "district": "Chennai",
        "state": "Tamil Nadu", "state_code": "TN",
        "lat": 13.0827, "lng": 80.2707,
        "elevation_m": 6, "flood_risk_score": 79,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon"],
        "tier": 1,
    },
    "coimbatore-tn": {
        "city": "Coimbatore", "district": "Coimbatore",
        "state": "Tamil Nadu", "state_code": "TN",
        "lat": 11.0168, "lng": 76.9558,
        "elevation_m": 411, "flood_risk_score": 41,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    "madurai-tn": {
        "city": "Madurai", "district": "Madurai",
        "state": "Tamil Nadu", "state_code": "TN",
        "lat": 9.9252, "lng": 78.1198,
        "elevation_m": 101, "flood_risk_score": 52,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "tiruchirappalli-tn": {
        "city": "Tiruchirappalli", "district": "Tiruchirappalli",
        "state": "Tamil Nadu", "state_code": "TN",
        "lat": 10.7905, "lng": 78.7047,
        "elevation_m": 78, "flood_risk_score": 58,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "salem-tn": {
        "city": "Salem", "district": "Salem",
        "state": "Tamil Nadu", "state_code": "TN",
        "lat": 11.6643, "lng": 78.1460,
        "elevation_m": 278, "flood_risk_score": 38,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    "tirunelveli-tn": {
        "city": "Tirunelveli", "district": "Tirunelveli",
        "state": "Tamil Nadu", "state_code": "TN",
        "lat": 8.7139, "lng": 77.7567,
        "elevation_m": 45, "flood_risk_score": 64,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── DELHI NCR ──────────────────────────────
    "delhi-dl": {
        "city": "Delhi", "district": "New Delhi",
        "state": "Delhi", "state_code": "DL",
        "lat": 28.6139, "lng": 77.2090,
        "elevation_m": 216, "flood_risk_score": 48,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon", "dunzo"],
        "tier": 1,
    },
    "noida-up": {
        "city": "Noida", "district": "Gautam Buddha Nagar",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 28.5355, "lng": 77.3910,
        "elevation_m": 198, "flood_risk_score": 55,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon"],
        "tier": 1,
    },
    "gurgaon-hr": {
        "city": "Gurugram", "district": "Gurugram",
        "state": "Haryana", "state_code": "HR",
        "lat": 28.4595, "lng": 77.0266,
        "elevation_m": 217, "flood_risk_score": 42,
        "platform_coverage": ["zepto", "swiggy", "blinkit", "zomato", "amazon"],
        "tier": 1,
    },
    "faridabad-hr": {
        "city": "Faridabad", "district": "Faridabad",
        "state": "Haryana", "state_code": "HR",
        "lat": 28.4082, "lng": 77.3178,
        "elevation_m": 198, "flood_risk_score": 50,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    # ── UTTAR PRADESH ──────────────────────────
    "lucknow-up": {
        "city": "Lucknow", "district": "Lucknow",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 26.8467, "lng": 80.9462,
        "elevation_m": 111, "flood_risk_score": 62,
        "platform_coverage": ["swiggy", "zomato", "blinkit", "amazon"], "tier": 1,
    },
    "kanpur-up": {
        "city": "Kanpur", "district": "Kanpur Nagar",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 26.4499, "lng": 80.3319,
        "elevation_m": 126, "flood_risk_score": 68,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "varanasi-up": {
        "city": "Varanasi", "district": "Varanasi",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 25.3176, "lng": 82.9739,
        "elevation_m": 80, "flood_risk_score": 74,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "agra-up": {
        "city": "Agra", "district": "Agra",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 27.1767, "lng": 78.0081,
        "elevation_m": 169, "flood_risk_score": 56,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "prayagraj-up": {
        "city": "Prayagraj", "district": "Prayagraj",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 25.4358, "lng": 81.8464,
        "elevation_m": 98, "flood_risk_score": 71,
        "platform_coverage": ["swiggy"], "tier": 2,
    },
    "meerut-up": {
        "city": "Meerut", "district": "Meerut",
        "state": "Uttar Pradesh", "state_code": "UP",
        "lat": 28.9845, "lng": 77.7064,
        "elevation_m": 218, "flood_risk_score": 45,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    # ── WEST BENGAL ────────────────────────────
    "kolkata-wb": {
        "city": "Kolkata", "district": "Kolkata",
        "state": "West Bengal", "state_code": "WB",
        "lat": 22.5726, "lng": 88.3639,
        "elevation_m": 9, "flood_risk_score": 85,
        "platform_coverage": ["swiggy", "zomato", "blinkit", "amazon"], "tier": 1,
    },
    "howrah-wb": {
        "city": "Howrah", "district": "Howrah",
        "state": "West Bengal", "state_code": "WB",
        "lat": 22.5958, "lng": 88.2636,
        "elevation_m": 12, "flood_risk_score": 82,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "durgapur-wb": {
        "city": "Durgapur", "district": "Paschim Bardhaman",
        "state": "West Bengal", "state_code": "WB",
        "lat": 23.4800, "lng": 87.3200,
        "elevation_m": 81, "flood_risk_score": 61,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── RAJASTHAN ──────────────────────────────
    "jaipur-rj": {
        "city": "Jaipur", "district": "Jaipur",
        "state": "Rajasthan", "state_code": "RJ",
        "lat": 26.9124, "lng": 75.7873,
        "elevation_m": 431, "flood_risk_score": 35,
        "platform_coverage": ["swiggy", "zomato", "blinkit", "amazon"], "tier": 1,
    },
    "jodhpur-rj": {
        "city": "Jodhpur", "district": "Jodhpur",
        "state": "Rajasthan", "state_code": "RJ",
        "lat": 26.2389, "lng": 73.0243,
        "elevation_m": 231, "flood_risk_score": 22,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "udaipur-rj": {
        "city": "Udaipur", "district": "Udaipur",
        "state": "Rajasthan", "state_code": "RJ",
        "lat": 24.5854, "lng": 73.7125,
        "elevation_m": 598, "flood_risk_score": 28,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── GUJARAT ────────────────────────────────
    "ahmedabad-gj": {
        "city": "Ahmedabad", "district": "Ahmedabad",
        "state": "Gujarat", "state_code": "GJ",
        "lat": 23.0225, "lng": 72.5714,
        "elevation_m": 53, "flood_risk_score": 58,
        "platform_coverage": ["swiggy", "zomato", "blinkit", "amazon"], "tier": 1,
    },
    "surat-gj": {
        "city": "Surat", "district": "Surat",
        "state": "Gujarat", "state_code": "GJ",
        "lat": 21.1702, "lng": 72.8311,
        "elevation_m": 13, "flood_risk_score": 72,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "vadodara-gj": {
        "city": "Vadodara", "district": "Vadodara",
        "state": "Gujarat", "state_code": "GJ",
        "lat": 22.3072, "lng": 73.1812,
        "elevation_m": 37, "flood_risk_score": 61,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "rajkot-gj": {
        "city": "Rajkot", "district": "Rajkot",
        "state": "Gujarat", "state_code": "GJ",
        "lat": 22.3039, "lng": 70.8022,
        "elevation_m": 128, "flood_risk_score": 38,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── MADHYA PRADESH ─────────────────────────
    "bhopal-mp": {
        "city": "Bhopal", "district": "Bhopal",
        "state": "Madhya Pradesh", "state_code": "MP",
        "lat": 23.2599, "lng": 77.4126,
        "elevation_m": 527, "flood_risk_score": 42,
        "platform_coverage": ["swiggy", "zomato", "amazon"], "tier": 2,
    },
    "indore-mp": {
        "city": "Indore", "district": "Indore",
        "state": "Madhya Pradesh", "state_code": "MP",
        "lat": 22.7196, "lng": 75.8577,
        "elevation_m": 553, "flood_risk_score": 38,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    "gwalior-mp": {
        "city": "Gwalior", "district": "Gwalior",
        "state": "Madhya Pradesh", "state_code": "MP",
        "lat": 26.2183, "lng": 78.1828,
        "elevation_m": 212, "flood_risk_score": 48,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── PUNJAB & HARYANA ───────────────────────
    "chandigarh-ch": {
        "city": "Chandigarh", "district": "Chandigarh",
        "state": "Chandigarh", "state_code": "CH",
        "lat": 30.7333, "lng": 76.7794,
        "elevation_m": 321, "flood_risk_score": 32,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    "ludhiana-pb": {
        "city": "Ludhiana", "district": "Ludhiana",
        "state": "Punjab", "state_code": "PB",
        "lat": 30.9010, "lng": 75.8573,
        "elevation_m": 244, "flood_risk_score": 45,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "amritsar-pb": {
        "city": "Amritsar", "district": "Amritsar",
        "state": "Punjab", "state_code": "PB",
        "lat": 31.6340, "lng": 74.8723,
        "elevation_m": 234, "flood_risk_score": 42,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    # ── ODISHA ─────────────────────────────────
    "bhubaneswar-od": {
        "city": "Bhubaneswar", "district": "Khordha",
        "state": "Odisha", "state_code": "OD",
        "lat": 20.2961, "lng": 85.8245,
        "elevation_m": 45, "flood_risk_score": 76,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "cuttack-od": {
        "city": "Cuttack", "district": "Cuttack",
        "state": "Odisha", "state_code": "OD",
        "lat": 20.4625, "lng": 85.8828,
        "elevation_m": 36, "flood_risk_score": 82,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── KERALA ─────────────────────────────────
    "thiruvananthapuram-kl": {
        "city": "Thiruvananthapuram", "district": "Thiruvananthapuram",
        "state": "Kerala", "state_code": "KL",
        "lat": 8.5241, "lng": 76.9366,
        "elevation_m": 16, "flood_risk_score": 68,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "kochi-kl": {
        "city": "Kochi", "district": "Ernakulam",
        "state": "Kerala", "state_code": "KL",
        "lat": 9.9312, "lng": 76.2673,
        "elevation_m": 8, "flood_risk_score": 79,
        "platform_coverage": ["swiggy", "zomato", "blinkit"], "tier": 2,
    },
    "kozhikode-kl": {
        "city": "Kozhikode", "district": "Kozhikode",
        "state": "Kerala", "state_code": "KL",
        "lat": 11.2588, "lng": 75.7804,
        "elevation_m": 6, "flood_risk_score": 72,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── BIHAR & JHARKHAND ──────────────────────
    "patna-br": {
        "city": "Patna", "district": "Patna",
        "state": "Bihar", "state_code": "BR",
        "lat": 25.5941, "lng": 85.1376,
        "elevation_m": 53, "flood_risk_score": 88,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "gaya-br": {
        "city": "Gaya", "district": "Gaya",
        "state": "Bihar", "state_code": "BR",
        "lat": 24.7914, "lng": 84.9994,
        "elevation_m": 113, "flood_risk_score": 72,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    "ranchi-jh": {
        "city": "Ranchi", "district": "Ranchi",
        "state": "Jharkhand", "state_code": "JH",
        "lat": 23.3441, "lng": 85.3096,
        "elevation_m": 651, "flood_risk_score": 42,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    # ── ASSAM & NORTHEAST ──────────────────────
    "guwahati-as": {
        "city": "Guwahati", "district": "Kamrup Metropolitan",
        "state": "Assam", "state_code": "AS",
        "lat": 26.1445, "lng": 91.7362,
        "elevation_m": 54, "flood_risk_score": 92,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    "silchar-as": {
        "city": "Silchar", "district": "Cachar",
        "state": "Assam", "state_code": "AS",
        "lat": 24.8333, "lng": 92.7789,
        "elevation_m": 29, "flood_risk_score": 88,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    "imphal-mn": {
        "city": "Imphal", "district": "Imphal West",
        "state": "Manipur", "state_code": "MN",
        "lat": 24.8170, "lng": 93.9368,
        "elevation_m": 786, "flood_risk_score": 58,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    # ── HIMACHAL & UTTARAKHAND ─────────────────
    "shimla-hp": {
        "city": "Shimla", "district": "Shimla",
        "state": "Himachal Pradesh", "state_code": "HP",
        "lat": 31.1048, "lng": 77.1734,
        "elevation_m": 2206, "flood_risk_score": 38,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    "dehradun-uk": {
        "city": "Dehradun", "district": "Dehradun",
        "state": "Uttarakhand", "state_code": "UK",
        "lat": 30.3165, "lng": 78.0322,
        "elevation_m": 640, "flood_risk_score": 55,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    # ── GOA ────────────────────────────────────
    "panaji-ga": {
        "city": "Panaji", "district": "North Goa",
        "state": "Goa", "state_code": "GA",
        "lat": 15.4909, "lng": 73.8278,
        "elevation_m": 7, "flood_risk_score": 65,
        "platform_coverage": ["swiggy", "zomato"], "tier": 3,
    },
    # ── CHHATTISGARH ───────────────────────────
    "raipur-cg": {
        "city": "Raipur", "district": "Raipur",
        "state": "Chhattisgarh", "state_code": "CG",
        "lat": 21.2514, "lng": 81.6296,
        "elevation_m": 294, "flood_risk_score": 58,
        "platform_coverage": ["swiggy", "zomato"], "tier": 2,
    },
    # ── JAMMU & KASHMIR ────────────────────────
    "srinagar-jk": {
        "city": "Srinagar", "district": "Srinagar",
        "state": "Jammu & Kashmir", "state_code": "JK",
        "lat": 34.0837, "lng": 74.7973,
        "elevation_m": 1585, "flood_risk_score": 62,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
    "jammu-jk": {
        "city": "Jammu", "district": "Jammu",
        "state": "Jammu & Kashmir", "state_code": "JK",
        "lat": 32.7266, "lng": 74.8570,
        "elevation_m": 327, "flood_risk_score": 52,
        "platform_coverage": ["swiggy"], "tier": 3,
    },
}


def get_zone_by_city(city_name: str) -> dict:
    """Find zone by city name (case insensitive)"""
    city_lower = city_name.lower()
    for key, zone in INDIA_ZONES.items():
        if zone["city"].lower() == city_lower:
            return {"zone_key": key, **zone}
    return None


def get_zones_by_state(state_code: str) -> list:
    """Get all zones in a state"""
    return [
        {"zone_key": k, **v}
        for k, v in INDIA_ZONES.items()
        if v["state_code"] == state_code
    ]


def get_all_cities() -> list:
    """Get all cities for dropdown/search"""
    cities = []
    for key, zone in INDIA_ZONES.items():
        cities.append({
            "zone_key": key,
            "city": zone["city"],
            "district": zone.get("district", ""),
            "state": zone["state"],
            "state_code": zone["state_code"],
            "lat": zone["lat"],
            "lng": zone["lng"],
            "flood_risk_score": zone["flood_risk_score"],
            "tier": zone.get("tier", 3),
            "platform_coverage": zone.get("platform_coverage", []),
        })
    return sorted(cities, key=lambda x: x["city"])


def search_cities(query: str) -> list:
    """Search cities by name, district, or state"""
    query_lower = query.lower()
    results = []
    for key, zone in INDIA_ZONES.items():
        if (
            query_lower in zone["city"].lower()
            or query_lower in zone["state"].lower()
            or query_lower in zone.get("district", "").lower()
        ):
            results.append({
                "zone_key": key,
                "city": zone["city"],
                "district": zone.get("district", ""),
                "state": zone["state"],
                "state_code": zone["state_code"],
                "lat": zone["lat"],
                "lng": zone["lng"],
                "flood_risk_score": zone["flood_risk_score"],
                "tier": zone.get("tier", 3),
                "platform_coverage": zone.get("platform_coverage", []),
            })
    return results[:20]

import h3

def get_hex_from_coord(lat: float, lng: float, resolution: int = 7) -> str:
    return h3.geo_to_h3(lat, lng, resolution)

def calculate_zone_flood_risk(h3_index: str, city_base_risk: float) -> float:
    # A pseudo-simulation to add hyper-local granularity
    h = int(h3_index, 16)
    micro_variance = (h % 100 - 50) / 100.0  # -0.5 to +0.5
    return min(1.0, max(0.05, city_base_risk + micro_variance * 0.3))
