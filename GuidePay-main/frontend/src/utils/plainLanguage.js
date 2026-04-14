export const CLAIM_STATUS_PLAIN = {
  // Status labels
  "PENDING":         "Checking your claim...",
  "PROCESSING":      "Processing your claim...",
  "FRAUD_CHECK":     "Running safety checks...",
  "AUTO_APPROVED":   "✅ Approved — money on the way",
  "MANUAL_REVIEW":   "Being reviewed by our team",
  "APPROVED":        "✅ Approved",
  "PAID":            "💸 Money sent to your UPI",
  "REJECTED":        "❌ Could not process this time",
};

export const CLAIM_STATUS_SUBTITLE = {
  "PENDING":         "We received your claim. Checking details now.",
  "PROCESSING":      "Verifying your location and activity. Usually takes 1 minute.",
  "FRAUD_CHECK":     "Our system is checking 9 safety signals. Almost done.",
  "AUTO_APPROVED":   "No issues found. Your money is being sent to your UPI.",
  "MANUAL_REVIEW":   "A team member will review this within 2 hours.",
  "APPROVED":        "Everything verified. Money transfer in progress.",
  "PAID":            "Check your UPI app — the money has arrived.",
  "REJECTED":        "This claim did not pass our checks. Contact support if you think this is wrong.",
};

export const AUDIT_EVENT_PLAIN = {
  "trigger_received":   "🌊 Flood detected in your area",
  "worker_verified":    "📍 Your location and policy confirmed",
  "activity_verified":  "✅ Your recent delivery activity confirmed",
  "fraud_scored":       "🔍 9 safety signals checked — all clear",
  "auto_approved":      "✅ Automatically approved — no issues found",
  "manual_review":      "👤 Sent for team review",
  "payout_initiated":   "💸 Money transfer started",
  "payout_completed":   "✅ Money arrived in your UPI",
};

export const FRAUD_SCORE_PLAIN = (score) => {
  if (score < 0.30) return "✅ Excellent — no concerns found";
  if (score < 0.50) return "✅ Good — passed all checks";
  if (score < 0.70) return "✅ Verified — auto-approved";
  if (score < 0.85) return "⚠️ Under review — a team member is checking";
  return "❌ Flagged for manual review";
};

export const ZONE_CORRELATION_PLAIN = (score) => {
  const pct = Math.round(score * 100);
  if (pct >= 60) return `${pct}% of workers in your area also affected — confirms the event is real`;
  if (pct >= 30) return `${pct}% of nearby workers also affected`;
  return "Checking area-wide impact";
};

export function getTimeEstimate(status) {
  const estimates = {
    "PENDING":       "1–2 minutes",
    "PROCESSING":    "Less than 1 minute",
    "FRAUD_CHECK":   "30 seconds",
    "AUTO_APPROVED": "Transfer starting now",
    "APPROVED":      "Money arriving in 30–60 minutes",
    "PAID":          "Check your UPI app now",
  };
  return estimates[status] || "";
}
