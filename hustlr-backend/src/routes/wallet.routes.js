const express = require('express');
const { supabase } = require('../config/supabase');
const router = express.Router();

// GET /wallet/:userId
router.get('/:user_id', async (req, res) => {
  const { user_id } = req.params;

  try {
    const { data: txns, error } = await supabase
      .from('wallet_transactions')
      .select('*')
      .eq('user_id', user_id)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) throw error;

    const credits = txns.filter(t => t.type === 'credit');
    const debits  = txns.filter(t => t.type === 'debit');

    const total_payouts  = credits.reduce((s, t) => s + t.amount, 0);
    const total_premiums = debits.reduce((s, t)  => s + t.amount, 0);
    const balance        = total_payouts - total_premiums;

    return res.json({
      balance,
      total_payouts,
      total_premiums,
      transactions: txns,
    });

  } catch (e) {
    console.error('[Wallet] Get error:', e.message);
    return res.status(500).json({ error: e.message });
  }
});

// GET /wallet/cashback-status/:userId
router.get('/cashback-status/:user_id', async (req, res) => {
  const { user_id } = req.params;
  try {
    const { data: policy } = await supabase
      .from('policies')
      .select('*')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .maybeSingle();
      
    // Mocking 15% cashback cron logic for the app.
    // If they have an active policy, simulate an in-progress quarter.
    if (policy) {
      return res.json({
         current_clean_weeks: 11,
         quarter_start: new Date(Date.now() - 11 * 7 * 24 * 60 * 60 * 1000).toISOString(),
         potential_cashback: (policy.weekly_premium || 49) * 13 * 0.15,
         status: 'in_progress'
      });
    }

    return res.json({
       current_clean_weeks: 0,
       quarter_start: new Date().toISOString(),
       potential_cashback: 0.0,
       status: 'reset'
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// POST /wallet/credit
router.post('/credit', async (req, res) => {
  const { user_id, amount, description, reference } = req.body;
  try {
    const { data: transaction, error } = await supabase
      .from('wallet_transactions')
      .insert([{ user_id, amount, type: 'credit', description, reference }])
      .select()
      .single();
    if (error) throw error;
    res.json({ transaction });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /wallet/debit
router.post('/debit', async (req, res) => {
  const { user_id, amount, description, reference } = req.body;
  try {
    const { data: transaction, error } = await supabase
      .from('wallet_transactions')
      .insert([{ user_id, amount, type: 'debit', description, reference }])
      .select()
      .single();
    if (error) throw error;
    res.json({ transaction });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
