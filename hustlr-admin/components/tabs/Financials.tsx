'use client';
import { fmt } from '@/lib/utils';
import { useAdminData } from '@/components/AdminContext';

const B2B2C = [
  { workers: '10,000',   rev: '₹4.4L',  arr: '₹52.8L'  },
  { workers: '50,000',   rev: '₹22L',   arr: '₹2.64Cr' },
  { workers: '1,00,000', rev: '₹44L',   arr: '₹5.28Cr' },
  { workers: '5,00,000', rev: '₹2.2Cr', arr: '₹26.4Cr' },
];

const ACTUARIAL = [
  { tier: 'Basic',    actuarial: 48,  charged: 35, subsidy: -27 },
  { tier: 'Standard', actuarial: 106, charged: 49, subsidy: -54 },
  { tier: 'Full',     actuarial: 172, charged: 79, subsidy: -54 },
];

const TH = 'px-4 py-3 text-xs font-bold tracking-wider uppercase text-left';
const TD = 'px-4 py-3 text-sm border-b';
const thStyle = { color: 'rgba(255,255,255,0.28)' };
const rowBorder = { borderColor: 'rgba(255,255,255,0.07)' };

export default function Financials() {
  const { analytics, poolSummary } = useAdminData();

  // Blended ARPU: weighted avg of Basic(₹35)×30% + Standard(₹49)×50% + Full(₹79)×20% ≈ ₹50.30/wk
  // But Hustlr's full ARPU model (incl. B2B SaaS + platform fee) is ~₹85.40/wk
  // We derive it directly from the real weekly pool ÷ active policies to stay grounded in live data
  const activePolicies = Number(poolSummary?.activePolicies ?? 0);
  const weeklyPool = Number(poolSummary?.weeklyPool ?? 0);

  // Per-worker weekly premium from live pool data; fall back to ₹85.40 blended ARPU if no data
  const weeklyARPU = activePolicies > 0 && weeklyPool > 0
    ? weeklyPool / activePolicies
    : 85.40;

  // Annual premium pool = active workers × weekly ARPU × 52 weeks
  const premiums = Math.round(activePolicies * weeklyARPU * 52);

  // Claims from analytics: totalPayout is cumulative, not weekly — use BCR to derive annual claims
  const bcr = Number(poolSummary?.bcr ?? 0) / 100; // bcr is stored as percent (e.g. 43.0)
  const grossClaims = bcr > 0 ? Math.round(premiums * bcr) : Math.round(Number(analytics?.summary?.totalPayout ?? 0) * 52);

  const fraudSavings = Math.round(grossClaims * 0.12);
  const capSavings = Math.round(grossClaims * 0.04);
  const netClaims = -(grossClaims - fraudSavings - capSavings);
  const operatingCosts = Math.round(premiums * 0.25);
  const reserveFund = Number(
    poolSummary?.reserve ?? Math.round((poolSummary?.weeklyPool ?? 0) * 2),
  );
  const reinsurancePremium = Math.round(premiums * 0.03);
  const platformFee = Math.round(premiums * 0.03);
  const insurerMargin =
    premiums +
    netClaims -
    operatingCosts -
    reserveFund -
    reinsurancePremium -
    platformFee;
  const netProfit = insurerMargin;

  const claimsRatio = premiums > 0 ? ((Math.abs(netClaims) / premiums) * 100).toFixed(1) : '0.0';
  const netMargin = premiums > 0 ? ((netProfit / premiums) * 100).toFixed(1) : '0.0';

  const pnl = [
    { label: 'Premium Pool (Annualized)', value: premiums,            color: '#3FFF8B',   bold: false },
    { label: 'Gross Claims Paid',        value: -grossClaims,        color: '#E24B4A',   bold: false },
    { label: '+ Fraud Detection Savings', value: fraudSavings,        color: '#3FFF8B88', bold: false },
    { label: '+ Cap Savings',            value: capSavings,           color: '#3FFF8B66', bold: false },
    { label: `Net Claims (${claimsRatio}%)`, value: netClaims,       color: '#E24B4A88', bold: false },
    { label: 'Operating Costs',          value: -operatingCosts,      color: '#FF980088', bold: false },
    { label: 'Reserve Fund (Static)',    value: -reserveFund,         color: '#2196F388', bold: false },
    { label: 'Reinsurance Premium',      value: -reinsurancePremium,  color: '#9C27B088', bold: false },
    { label: 'Guidewire Platform Fee',   value: -platformFee,         color: '#FF572288', bold: false },
    { label: 'Insurer Margin',           value: insurerMargin,        color: '#3FFF8B',   bold: false },
    { label: `Net Profit (${netMargin}%)`, value: netProfit,          color: '#3FFF8B',   bold: true  },
  ];

  return (
    <div className="space-y-6">
      {/* P&L */}
      <div className="card overflow-hidden">
        <div className="px-6 py-4 border-b" style={rowBorder}>
          <p className="text-xs font-bold tracking-widest uppercase" style={{ color: '#91938D' }}>
            ANNUAL P&L SUMMARY — {(poolSummary?.activePolicies ?? 0).toLocaleString('en-IN')} WORKERS
          </p>
        </div>
        <div>
          {pnl.map(row => (
            <div
              key={row.label}
              className={`flex justify-between px-6 py-3.5 border-b ${row.bold ? 'border-t' : ''}`}
              style={{ borderColor: 'rgba(255,255,255,0.07)', background: row.bold ? 'rgba(255,255,255,0.015)' : 'transparent' }}
            >
              <span className={`text-sm ${row.bold ? 'font-black' : 'font-medium'}`} style={{ color: row.bold ? '#E1E3DE' : 'rgba(255,255,255,0.65)' }}>
                {row.label}
              </span>
              <span className={`text-sm ${row.bold ? 'font-black text-lg' : 'font-bold'}`} style={{ color: row.color }}>
                {row.value < 0 ? `-${fmt(Math.abs(row.value))}` : fmt(row.value)}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* B2B2C */}
        <div className="card overflow-hidden">
          <div className="px-6 py-4 border-b" style={rowBorder}>
            <p className="text-xs font-bold tracking-widest uppercase" style={{ color: '#91938D' }}>
              B2B2C REVENUE PROJECTION
            </p>
          </div>
          <table className="w-full">
            <thead>
              <tr className="border-b" style={rowBorder}>
                {['Workers', 'Hustlr Monthly Rev', 'ARR'].map(h =>
                  <th key={h} className={TH} style={thStyle}>{h}</th>
                )}
              </tr>
            </thead>
            <tbody>
              {B2B2C.map((row, i) => (
                <tr key={i} className="border-b transition-colors hover:bg-white/2" style={rowBorder}>
                  <td className={TD} style={{ borderColor: 'rgba(255,255,255,0.07)', fontWeight: 700 }}>{row.workers}</td>
                  <td className={TD} style={{ borderColor: 'rgba(255,255,255,0.07)', fontWeight: 800, color: '#3FFF8B' }}>{row.rev}</td>
                  <td className={TD} style={{ borderColor: 'rgba(255,255,255,0.07)', fontWeight: 700, color: '#2196F3' }}>{row.arr}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Actuarial subsidy */}
        <div className="card overflow-hidden">
          <div className="px-6 py-4 border-b" style={rowBorder}>
            <p className="text-xs font-bold tracking-widest uppercase" style={{ color: '#91938D' }}>
              ACTUARIAL SUBSIDY TABLE
            </p>
          </div>
          <table className="w-full">
            <thead>
              <tr className="border-b" style={rowBorder}>
                {['Plan', 'Actuarial Fair', 'Charged', 'Subsidy'].map(h =>
                  <th key={h} className={TH} style={thStyle}>{h}</th>
                )}
              </tr>
            </thead>
            <tbody>
              {ACTUARIAL.map(row => (
                <tr key={row.tier} className="border-b hover:bg-white/2" style={rowBorder}>
                  <td className={TD} style={{ borderColor: 'rgba(255,255,255,0.07)', fontWeight: 700 }}>{row.tier}</td>
                  <td className={TD} style={{ borderColor: 'rgba(255,255,255,0.07)', color: 'rgba(255,255,255,0.45)' }}>₹{row.actuarial}/wk</td>
                  <td className={TD} style={{ borderColor: 'rgba(255,255,255,0.07)', fontWeight: 800, color: '#3FFF8B' }}>₹{row.charged}/wk</td>
                  <td className={`${TD}`} style={{ borderColor: 'rgba(255,255,255,0.07)' }}>
                    <span className="badge-red">{row.subsidy}%</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="px-6 py-3 text-xs border-t" style={{ color: 'rgba(255,255,255,0.28)', borderColor: 'rgba(255,255,255,0.07)' }}>
            Subsidy financed by Guidewire reinsurance partnership + operating scale. Closes at 50K+ workers.
          </div>
        </div>
      </div>
    </div>
  );
}
