export const PLANS = [
  {
    id: "daily",
    name: "Daily Shield",
    price: 12,
    period: "day",
    display: "₹12 / day",
    badge: "MOST AFFORDABLE",
    badgeColor: "green",
    coverageHours: 24,
    payouts: { bronze: 400, silver: 600, gold: 900 },
    features: [
      "24-hour protection window",
      "Income-based payout (₹400–₹900)",
      "All 5 trigger types covered",
      "Instant UPI payout",
    ],
  },
  {
    id: "basic",
    name: "Basic Shield",
    price: 49,
    period: "week",
    display: "₹49 / week",
    badge: null,
    coverageHours: 168,
    payouts: { bronze: 400, silver: 600, gold: 900 },
    features: [
      "7-day protection window",
      "Income-based payout (₹400–₹900)",
      "Flood + Air Quality triggers",
      "Instant UPI payout",
    ],
  },
  {
    id: "standard",
    name: "Standard Shield",
    price: 62,
    period: "week",
    display: "₹62 / week",
    badge: "MOST POPULAR",
    badgeColor: "orange",
    coverageHours: 168,
    payouts: { bronze: 400, silver: 600, gold: 900 },
    features: [
      "7-day protection window",
      "Income-based payout (₹400–₹900)",
      "All 5 trigger types covered",
      "Priority claim processing",
      "Instant UPI payout",
    ],
  },
  {
    id: "premium",
    name: "Premium Shield",
    price: 89,
    period: "week",
    display: "₹89 / week",
    badge: "FULL PROTECTION",
    badgeColor: "blue",
    coverageHours: 168,
    payouts: { bronze: 400, silver: 600, gold: 900 },
    features: [
      "7-day protection window",
      "Income-based payout (₹400–₹900)",
      "All 5 trigger types covered",
      "Dedicated support",
      "Earnings analytics",
      "Instant UPI payout",
    ],
  },
];

export const PAYOUT_TIERS = {
  bronze: { label: "Bronze", min: 0, max: 7, payout: 400, color: "#CD7F32" },
  silver: { label: "Silver", min: 8, max: 14, payout: 600, color: "#A8A9AD" },
  gold:   { label: "Gold",   min: 15, max: 999, payout: 900, color: "#FFD700" },
};

export function getTierForOrders(dailyOrders) {
  if (dailyOrders >= 15) return "gold";
  if (dailyOrders >= 8) return "silver";
  return "bronze";
}

export function getPayoutForOrders(dailyOrders) {
  return PAYOUT_TIERS[getTierForOrders(dailyOrders)].payout;
}

export const getPlanById = (id) => PLANS.find(p => p.id === id) || PLANS[2];

export const getAdjustedPrice = (basePrice, mlPremium, standardBase = 62) => {
  if (!mlPremium) return basePrice;
  const ratio = mlPremium / standardBase;
  return Math.max(35, Math.round(basePrice * ratio));
};

export default PLANS;
