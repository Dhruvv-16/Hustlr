const express = require('express');
const { supabase } = require('../config/supabase');
const { buildClaimPayload, forwardToGuidewire } = require('../services/guidewire_service');

const router = express.Router();

// GET /guidewire/sample-payload/:claimId
router.get('/sample-payload/:claimId', async (req, res) => {
  if (process.env.ENABLE_GUIDEWIRE_ROUTES !== 'true') {
    return res.status(404).json({ error: 'Guidewire routes disabled' });
  }
  try {
    const { claimId } = req.params;
    const { data: claim, error } = await supabase
      .from('claims')
      .select('*')
      .eq('id', claimId)
      .maybeSingle();

    if (error) throw error;
    if (!claim) return res.status(404).json({ error: 'Claim not found' });

    const { data: userRow } = await supabase
      .from('users')
      .select('name, phone, zone')
      .eq('id', claim.user_id)
      .maybeSingle();

    const payload = buildClaimPayload({ ...claim, users: userRow || {} });
    return res.json(payload);
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

// POST /guidewire/forward/:claimId  — optional webhook test
router.post('/forward/:claimId', async (req, res) => {
  if (process.env.ENABLE_GUIDEWIRE_ROUTES !== 'true') {
    return res.status(404).json({ error: 'Guidewire routes disabled' });
  }
  try {
    const { claimId } = req.params;
    const { data: claim, error } = await supabase
      .from('claims')
      .select('*')
      .eq('id', claimId)
      .maybeSingle();

    if (error) throw error;
    if (!claim) return res.status(404).json({ error: 'Claim not found' });

    const { data: userRow } = await supabase
      .from('users')
      .select('name, phone, zone')
      .eq('id', claim.user_id)
      .maybeSingle();

    const payload = buildClaimPayload({ ...claim, users: userRow || {} });
    const forward = await forwardToGuidewire(payload);
    return res.json({ payload, forward });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

module.exports = router;
