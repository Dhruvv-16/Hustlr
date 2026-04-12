'use client';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Cell, ResponsiveContainer, LineChart, Line, AreaChart, Area } from 'recharts';
import { ZONES } from '@/lib/constants';
import { bcrColor, riskBadge } from '@/lib/utils';
import { fetchProphetForecast } from '@/lib/api';
import { useState, useEffect } from 'react';

export default function ZoneHeatmap() {
  const [prophetData, setProphetData] = useState<any[]>([]);
  const [prophetLoading, setProphetLoading] = useState(true);

  useEffect(() => {
    fetchProphetForecast('Adyar Dark Store Zone', 7)
      .then(res => setProphetData(res.forecasts || []))
      .catch(console.error)
      .finally(() => setProphetLoading(false));
  }, []);
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

      {/* Prophet Forecasting API Chart */}
      <div className="card p-6 border-emerald-500/30 shadow-[0_0_30px_rgba(63,255,139,0.05)]">
        <div className="flex justify-between items-start mb-6">
          <div>
            <h3 className="font-black text-lg text-emerald-400">Prophet AI: 7-Day Forecasting</h3>
            <p className="text-sm text-white/50">Predicting heavy rain probability for Adyar Dark Store Zone.</p>
          </div>
          {prophetLoading && <span className="text-xs text-white/40 animate-pulse">Computing ML Vectors...</span>}
        </div>
        
        {prophetData.length > 0 ? (
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={prophetData}>
              <defs>
                <linearGradient id="colorRisk" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3FFF8B" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#3FFF8B" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fill: '#91938D', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis domain={[0, 1]} tick={{ fill: '#91938D', fontSize: 10 }} axisLine={false} tickLine={false} tickFormatter={val => `${val*100}%`} />
              <Tooltip
                contentStyle={{ background: '#111311', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8 }}
              />
              <Area type="monotone" dataKey="disruption_probability" name="Rain Risk" stroke="#3FFF8B" fillOpacity={1} fill="url(#colorRisk)" />
            </AreaChart>
          </ResponsiveContainer>
        ) : !prophetLoading && (
          <div className="text-center text-white/30 text-sm py-10">No Prophet data returned. AI engine may be offline.</div>
        )}
      </div>
    </div>
  );
}
