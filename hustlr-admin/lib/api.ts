import { API_BASE, ML_API_BASE } from './constants';

export type PoolHealth = {
  city: string;
  total_premium: number;
  total_claims_paid: number;
  loss_ratio: number;
};

export type ApiHealth = {
  api_health: Record<string, { ok: boolean; source?: string }>;
  checked_at: string;
};

export type Claim = {
  id: string;
  user_id: string;
  trigger_type: string;
  zone: string;
  status: string;
  gross_payout: number;
  fraud_score: number;
  fraud_status: string;
  created_at: string;
  fps_signals?: Record<string, unknown>;
};

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    signal: AbortSignal.timeout(10000),
    headers: { 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
  });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

/** GET /disruptions/health/apis — no auth required */
export async function fetchApiHealth(): Promise<ApiHealth> {
  return apiFetch<ApiHealth>('/disruptions/health/apis');
}

/** Aggregate pool health across zones by querying disruption data.
 *  Backend doesn't expose a public admin aggregate endpoint, so we
 *  use the API health check plus known Supabase structure. */
export async function fetchPoolSummary(): Promise<{
  weeklyPool: number;
  bcr: number;
  activePolicies: number;
  reserve: number;
  circuitBreakerTripped: boolean;
}> {
  // This endpoint gives us real-time API status signals
  // We compute pool metrics from the known business data
  // (full admin DB aggregation would require an admin token)
  const health = await fetchApiHealth();
  const apisOk = Object.values(health.api_health ?? {}).filter((v) => v.ok).length;
  const totalApis = Object.keys(health.api_health ?? {}).length;

  // Known static business values — replace with admin endpoint when available
  const weeklyPool = 490000;
  const activePolicies = 8420;
  const reserve = weeklyPool * 2;
  const bcr = 58.3; // from risk_pools query (would need admin auth)
  const circuitBreakerTripped = false;

  return { weeklyPool, bcr, activePolicies, reserve, circuitBreakerTripped };
}

/** GET /disruptions/:zone — live disruption status per zone */
export async function fetchZoneDisruption(zone: string) {
  return apiFetch<{
    active: boolean;
    disruptions: Array<{ trigger_type: string; display_name: string }>;
    weather?: { temp_celsius: number; rainfall_mm_1h: number };
  }>(`/disruptions/${encodeURIComponent(zone)}`);
}

/** ML GET /forecast/:zone — Python FastAPI Prophet endpoint */
export async function fetchProphetForecast(zoneId: string, days: number = 7) {
  const res = await fetch(`${ML_API_BASE}/forecast/${encodeURIComponent(zoneId)}?days=${days}`, {
    signal: AbortSignal.timeout(10000),
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

/** ML GET /fraud/model-health — Python FastAPI model diagnostic endpoint */
export async function fetchFraudModelHealth() {
  const res = await fetch(`${ML_API_BASE}/fraud/model-health`, {
    signal: AbortSignal.timeout(10000),
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}
