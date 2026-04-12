'use client';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Cell, ResponsiveContainer } from 'recharts';
import { ZONES } from '@/lib/constants';
import { bcrColor, riskBadge } from '@/lib/utils';

export default function ZoneHeatmap() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {ZONES.map(z => (
          <div key={z.name} className="card p-5 space-y-4">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-black text-base">{z.name}</h3>
                <p className="text-xs mt-0.5" style={{ color: 'rgba(255,255,255,0.35)' }}>
                  {z.workers.toLocaleString('en-IN')} active workers
                </p>
              </div>
              <span className={riskBadge(z.risk)}>{z.risk} RISK</span>
            </div>

            {/* BCR bar */}
            <div>
              <div className="flex justify-between mb-1.5">
                <span className="text-xs" style={{ color: 'rgba(255,255,255,0.35)' }}>Zone BCR</span>
                <span className="text-xs font-bold" style={{ color: bcrColor(z.bcr) }}>{z.bcr}%</span>
              </div>
              <div className="w-full rounded-full h-2" style={{ background: 'rgba(255,255,255,0.07)' }}>
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ width: `${z.bcr}%`, background: bcrColor(z.bcr) }}
                />
              </div>
              {z.bcr >= 85 && (
                <p className="text-xs font-bold mt-1.5" style={{ color: '#E24B4A' }}>⚠ Circuit Breaker OPEN</p>
              )}
            </div>

            <div className="flex items-center justify-between">
              {/* Disruption pill */}
              <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full border ${
                z.disruption
                  ? 'bg-amber-500/10 border-amber-500/30'
                  : 'bg-emerald-500/10 border-emerald-500/30'
              }`}>
                <span className={`w-1.5 h-1.5 rounded-full ${z.disruption ? 'bg-amber-400 pulse-red' : 'bg-emerald-400'}`} />
                <span className={`text-xs font-bold ${z.disruption ? 'text-amber-400' : 'text-emerald-400'}`}>
                  {z.disruption ? 'DISRUPTION ACTIVE' : 'CLEAR'}
                </span>
              </div>
              {/* Claims today */}
              <div className="text-right">
                <p className="text-xl font-black">{z.claims_today}</p>
                <p className="text-xs" style={{ color: 'rgba(255,255,255,0.35)' }}>claims today</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Bar chart */}
      <div className="card p-6">
        <p className="text-xs font-bold tracking-widest uppercase mb-4" style={{ color: '#91938D' }}>
          CLAIMS FILED TODAY — BY ZONE
        </p>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={ZONES.map(z => ({ name: z.name, claims: z.claims_today, bcr: z.bcr }))}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
            <XAxis dataKey="name" tick={{ fill: '#91938D', fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fill: '#91938D', fontSize: 10 }} axisLine={false} tickLine={false} />
            <Tooltip
              contentStyle={{ background: '#111311', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8 }}
              labelStyle={{ color: '#E1E3DE' }}
            />
            <Bar dataKey="claims" name="Claims Today" radius={[4,4,0,0]}>
              {ZONES.map((z, i) => <Cell key={i} fill={bcrColor(z.bcr)} />)}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
