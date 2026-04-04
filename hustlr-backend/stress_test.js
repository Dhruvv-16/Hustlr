const axios = require('axios');
const fs = require('fs');
const BASE = 'http://localhost:3000';
const log = [];

async function run(name, fn) {
  try {
    const result = await fn();
    log.push({ test: name, status: 'PASS', detail: result });
    console.log('PASS:', name, '-', result);
  } catch(e) {
    const err = e.response?.data || e.message;
    log.push({ test: name, status: 'FAIL', detail: err });
    console.log('FAIL:', name, '-', JSON.stringify(err));
  }
}

async function main() {
  console.log('\n=== HUSTLR STRESS TEST ===\n');

  // Register user 1
  let user1, user2, user3;
  await run('T1 - Register user', async () => {
    const r = await axios.post(`${BASE}/workers/register`, {
      name: 'Stress Test 1', phone: '7777700001', zone: 'adyar', city: 'Chennai', platform: 'Zepto'
    });
    user1 = r.data.user;
    return `id=${user1.id}`;
  });

  // Create policy
  let policy;
  await run('T2 - Create policy (full tier)', async () => {
    const r = await axios.post(`${BASE}/policies/create`, { user_id: user1?.id, plan_tier: 'full' });
    policy = r.data.policy;
    return `tier=${policy.plan_tier}, max_payout=${policy.max_weekly_payout}`;
  });

  // Single claim
  await run('T3 - Single claim + fraud score', async () => {
    const r = await axios.post(`${BASE}/claims/create`, {
      user_id: user1?.id, trigger_type: 'rain_heavy', severity: 1.0, duration_hours: 3.0
    });
    const c = r.data.claim;
    return `payout=Rs.${c.gross_payout}, fraud_score=${c.fraud_score}, status=${c.fraud_status}`;
  });

  // Circuit breaker test
  await run('T4 - Circuit breaker (flood zone)', async () => {
    const ru = await axios.post(`${BASE}/workers/register`, {
      name: 'CB Test', phone: '7777700002', zone: 'tambaram', city: 'Chennai', platform: 'Zepto'
    });
    user2 = ru.data.user;
    await axios.post(`${BASE}/policies/create`, { user_id: user2.id, plan_tier: 'standard' });

    let trippedAt = -1;
    for (let i = 1; i <= 55; i++) {
      try {
        await axios.post(`${BASE}/claims/create`, {
          user_id: user2.id, trigger_type: 'rain_heavy', severity: 1.0, duration_hours: 3.0
        });
      } catch(e) {
        if (e.response?.status === 429) { trippedAt = i; break; }
      }
    }
    if (trippedAt === -1) throw new Error('Circuit breaker did not trip in 55 requests');
    return `Tripped at request #${trippedAt} - 429 returned`;
  });

  // Parallel claims
  await run('T5 - Parallel claims (10 simultaneous)', async () => {
    const ru = await axios.post(`${BASE}/workers/register`, {
      name: 'Parallel Test', phone: '7777700003', zone: 'anna_nagar', city: 'Chennai', platform: 'Zepto'
    });
    user3 = ru.data.user;
    await axios.post(`${BASE}/policies/create`, { user_id: user3.id, plan_tier: 'full' });

    const results = await Promise.allSettled(
      Array.from({ length: 10 }, () =>
        axios.post(`${BASE}/claims/create`, {
          user_id: user3.id, trigger_type: 'aqi_severe', severity: 0.8, duration_hours: 2.0
        })
      )
    );
    const ok = results.filter(r => r.status === 'fulfilled').length;
    const fail = results.filter(r => r.status === 'rejected').length;
    return `${ok}/10 fulfilled, ${fail}/10 rejected`;
  });

  // Disruption endpoint
  await run('T6 - Disruption endpoint + trust score', async () => {
    const r = await axios.get(`${BASE}/disruptions/adyar`);
    const d = r.data;
    const hasTs = d.disruptions?.every(x => x.trust_score !== undefined);
    return `disruptions=${d.disruptions?.length}, trust_scored=${hasTs ?? 'n/a (none active)'}`;
  });

  // Wallet balance
  await run('T7 - Wallet balance', async () => {
    const r = await axios.get(`${BASE}/wallet/${user1?.id}`);
    return `balance=Rs.${r.data.balance}`;
  });

  // Summary
  const passed = log.filter(x => x.status === 'PASS').length;
  const failed = log.filter(x => x.status === 'FAIL').length;
  console.log(`\n=== RESULTS: ${passed} passed / ${failed} failed ===\n`);
  fs.writeFileSync('stress_result.json', JSON.stringify(log, null, 2), 'utf8');
  console.log('Full results written to stress_result.json');
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
