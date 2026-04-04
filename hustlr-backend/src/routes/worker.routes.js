const express = require('express');
const { supabase } = require('../config/supabase');
const { computeZoneDepth, computeZoneDepthAsync } = require('../services/zone_depth_service');
const router = express.Router();

// GET /workers/phone/:phone
router.get('/phone/:phone', async (req, res) => {
  try {
    const { phone } = req.params;
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('phone', phone)
      .maybeSingle();
    if (error && error.code !== 'PGRST116') throw error;
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /workers/register
router.post('/register', async (req, res) => {
  const { name, phone, zone, city, platform } = req.body;

  if (!name || !phone || !zone || !city) {
    return res.status(400).json({ error: 'name, phone, zone and city are required' });
  }

  try {
    // Return existing worker if already registered
    const { data: existing } = await supabase
      .from('users')
      .select('*')
      .eq('phone', phone)
      .maybeSingle();

    if (existing) {
      return res.status(200).json({ user: existing, message: 'Worker already registered' });
    }

    // Create new worker
    const { data: user, error } = await supabase
      .from('users')
      .insert([{ name, phone, zone, city, platform: platform || 'Zepto', iss_score: 75 }])
      .select()
      .single();

    if (error) throw error;

    // Seed first premium debit in wallet
    await supabase
      .from('wallet_transactions')
      .insert([{
        user_id:     user.id,
        amount:      49,
        type:        'debit',
        description: 'Standard Shield Premium — Week 1',
        reference:   'onboarding',
      }]);

    return res.status(201).json({ user });

  } catch (e) {
    console.error('[Workers] Register error:', e.message);
    return res.status(500).json({ error: e.message });
  }
});

// POST /workers/zone-depth/compute — lat/lon → score (no DB write); PostGIS when enabled
router.post('/zone-depth/compute', async (req, res) => {
  const lat = Number(req.body?.lat);
  const lon = Number(req.body?.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return res.status(400).json({ error: 'lat and lon must be finite numbers' });
  }
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    return res.status(400).json({ error: 'lat/lon out of range' });
  }
  try {
    res.json(await computeZoneDepthAsync(lat, lon));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /workers/:id
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single();
    if (userError) throw userError;

    const { data: active_policy } = await supabase
      .from('policies')
      .select('*')
      .eq('user_id', id)
      .eq('status', 'active')
      .maybeSingle();

    res.json({ user, active_policy: active_policy || null });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PATCH /workers/:id/iss
router.patch('/:id/iss', async (req, res) => {
  try {
    const { id } = req.params;
    const { iss_score } = req.body;
    const { data: updated_user, error } = await supabase
      .from('users')
      .update({ iss_score })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    res.json({ updated_user });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PATCH /workers/:id/zone-depth — persist zone_depth_score from lat/lon (PostGIS when USE_POSTGIS_ZONE_DEPTH=true)
router.patch('/:id/zone-depth', async (req, res) => {
  try {
    const { id } = req.params;
    const lat = Number(req.body?.lat);
    const lon = Number(req.body?.lon);
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
      return res.status(400).json({ error: 'lat and lon must be finite numbers' });
    }
    const { zone_depth_score, distance_km, hub, source } = await computeZoneDepthAsync(lat, lon);
    const { data: updated_user, error } = await supabase
      .from('users')
      .update({ zone_depth_score })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    res.json({ updated_user, distance_km, hub, source });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
