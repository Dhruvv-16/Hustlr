require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const workerRoutes = require('./routes/worker.routes');
const policyRoutes = require('./routes/policy.routes');
const claimsRoutes = require('./routes/claims.routes');
const walletRoutes = require('./routes/wallet.routes');
const disruptionRoutes = require('./routes/disruption.routes');

const app = express();

app.use(cors());
app.use(express.json());

// Mount routes
app.use('/auth', authRoutes);
app.use('/workers', workerRoutes);
app.use('/policies', policyRoutes);
app.use('/claims', claimsRoutes);
app.use('/wallet', walletRoutes);
app.use('/disruptions', disruptionRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'hustlr-backend' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`hustlr-backend listening on port ${PORT}`);
});
