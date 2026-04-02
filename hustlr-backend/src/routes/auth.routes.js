const express = require('express');
const { supabase } = require('../config/supabase');
const router = express.Router();

router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    const { error } = await supabase.auth.signInWithOtp({ phone });
    if (error) throw error;
    res.json({ message: 'OTP sent', phone });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, token } = req.body;
    const { data, error } = await supabase.auth.verifyOtp({ phone, token, type: 'sms' });
    if (error) throw error;
    res.json({ access_token: data.session?.access_token, user: data.user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
