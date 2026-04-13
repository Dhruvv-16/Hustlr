import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import cron from 'node-cron';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

cron.schedule('*/15 * * * *', () => {
  console.log('[CRON] Running disruption monitoring check...');
});

app.listen(PORT, () => {
  console.log(`SurakshaAI Backend running on port ${PORT}`);
});

export default app;
