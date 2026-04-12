const express = require('express');
const router = express.Router();
const axios = require('axios');

const ML_URL = process.env.ML_SERVICE_URL || 'https://hustlr-2ppj.onrender.com';
const TIMEOUT = 60000; // 60s — allows for Render free tier cold start (~30-50s)

// Pass-through proxy routes so the UI ML Data Tester works without direct access to ML url
router.post('/nlp', async (req, res) => {
  try {
    const { data } = await axios.post(`${ML_URL}/nlp`, req.body, { timeout: TIMEOUT });
    res.json(data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

router.post('/traffic', async (req, res) => {
  try {
    const { data } = await axios.post(`${ML_URL}/traffic`, req.body, { timeout: TIMEOUT });
    res.json(data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

router.post('/fraud', async (req, res) => {
  try {
    const { data } = await axios.post(`${ML_URL}/fraud-score`, req.body, { timeout: TIMEOUT });
    res.json(data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

module.exports = router;
