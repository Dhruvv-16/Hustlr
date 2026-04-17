'use client';
import { useEffect, useState } from 'react';
import DeckGL from '@deck.gl/react';
import { TileLayer } from '@deck.gl/geo-layers';
import { BitmapLayer } from '@deck.gl/layers';
import { H3HexagonLayer } from '@deck.gl/geo-layers';
import { latLngToCell } from 'h3-js';

const ZONES = [
  { name: 'Adyar',           lat: 13.0067, lng: 80.2206, risk: 87, claims: 12, trigger: 'Rain',     workers: 43 },
  { name: 'T. Nagar',        lat: 13.0418, lng: 80.2341, risk: 72, claims: 8,  trigger: 'Rain',     workers: 61 },
  { name: 'Anna Nagar',      lat: 13.0850, lng: 80.2101, risk: 55, claims: 5,  trigger: 'Heat',     workers: 34 },
  { name: 'Velachery',       lat: 12.9780, lng: 80.2209, risk: 91, claims: 18, trigger: 'Flood',    workers: 29 },
  { name: 'Porur',           lat: 13.0357, lng: 80.1566, risk: 46, claims: 3,  trigger: 'AQI',      workers: 22 },
  { name: 'Tambaram',        lat: 12.9249, lng: 80.1000, risk: 38, claims: 2,  trigger: 'Heat',     workers: 18 },
  { name: 'Sholinganallur',  lat: 12.9010, lng: 80.2279, risk: 79, claims: 9,  trigger: 'Rain',     workers: 37 },
  { name: 'Chromepet',       lat: 12.9516, lng: 80.1462, risk: 62, claims: 6,  trigger: 'Rain',     workers: 25 },
  { name: 'Mylapore',        lat: 13.0339, lng: 80.2619, risk: 83, claims: 11, trigger: 'Platform', workers: 55 },
  { name: 'Guindy',          lat: 13.0067, lng: 80.2097, risk: 70, claims: 7,  trigger: 'Heat',     workers: 48 },
  { name: 'Perambur',        lat: 13.1175, lng: 80.2446, risk: 28, claims: 1,  trigger: 'None',     workers: 15 },
  { name: 'Kolathur',        lat: 13.1196, lng: 80.2080, risk: 33, claims: 2,  trigger: 'AQI',      workers: 20 },
  { name: 'Medavakkam',      lat: 12.9173, lng: 80.1948, risk: 68, claims: 5,  trigger: 'Rain',     workers: 32 },
];

const H3_RES = 8;
const hexData = ZONES.map(z => ({ ...z, h3index: latLngToCell(z.lat, z.lng, H3_RES) }));

function riskColor(risk: number, alpha = 200): [number, number, number, number] {
  if (risk >= 81) return [255, 59, 89, alpha];
  if (risk >= 61) return [255, 140, 66, alpha];
  if (risk >= 31) return [255, 224, 102, alpha];
  return [63, 255, 139, alpha];
}

const INITIAL_VIEW_STATE = {
  longitude: 80.2101,
  latitude:  13.0280,
  zoom:      10.8,
  pitch:     52,
  bearing:   -18,
};

export default function H3RiskMap() {
  const [pulseScale, setPulseScale] = useState(100);

  useEffect(() => {
    let tick = 0;
    let animationFrame: number;
    const animate = () => {
      tick += 0.02;
      setPulseScale(100 + Math.sin(tick) * 12);
      animationFrame = requestAnimationFrame(animate);
    };
    animate();
    return () => cancelAnimationFrame(animationFrame);
  }, []);

  const [hoverInfo, setHoverInfo] = useState<any>(null);

  const layers = [
    new TileLayer({
      id: 'basemap',
      data: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      minZoom: 0,
      maxZoom: 19,
      tileSize: 256,
      renderSubLayers: (props: any) => {
        const { boundingBox } = props.tile;
        return new BitmapLayer(props, {
          image: props.data,
          // TileLayer sets bounds correctly
          bounds: [boundingBox[0][0], boundingBox[0][1], boundingBox[1][0], boundingBox[1][1]],
        });
      },
    }),
    new H3HexagonLayer({
      id: 'risk-hexagons',
      data: hexData,
      pickable: true,
      wireframe: false,
      filled: true,
      extruded: true,
      elevationScale: pulseScale,
      getHexagon: (d: any) => d.h3index,
      getFillColor: (d: any) => riskColor(d.risk, 200),
      getLineColor: (d: any) => riskColor(d.risk, 255),
      getElevation: (d: any) => d.risk,
      lineWidthMinPixels: 1,
      onHover: (info: any) => setHoverInfo(info),
    })
  ];

  return (
    <div className="relative w-full h-[500px] rounded-xl overflow-hidden border border-white/10">
      <DeckGL
        initialViewState={INITIAL_VIEW_STATE}
        controller={true}
        layers={layers}
        getTooltip={(info: any) => {
          if (!info || !info.object) return null;
          const { object } = info;
          return {
            html: `
              <div style="font-family: 'Inter', sans-serif;">
                <div style="color: #3fff8b; font-weight: 700; font-size: 13px; margin-bottom: 6px;">${object.name}</div>
                <div style="color: rgba(255,255,255,0.65); margin-bottom: 3px;">Risk score: <span style="color:#fff; font-weight:600;">${object.risk}</span></div>
                <div style="color: rgba(255,255,255,0.65); margin-bottom: 3px;">Active claims: <span style="color:#fff; font-weight:600;">${object.claims}</span></div>
                <div style="color: rgba(255,255,255,0.65); margin-bottom: 3px;">Trigger: <span style="color:#fff; font-weight:600;">${object.trigger}</span></div>
                <div style="color: rgba(255,255,255,0.65); margin-bottom: 3px;">Workers online: <span style="color:#fff; font-weight:600;">${object.workers}</span></div>
              </div>
            `,
            style: {
              backgroundColor: 'rgba(5,10,18,0.92)',
              border: '1px solid rgba(63,255,139,0.28)',
              borderRadius: '10px',
              padding: '10px 14px',
              color: '#fff',
              fontSize: '12px',
              backdropFilter: 'blur(8px)',
            }
          };
        }}
      />
      <div className="absolute top-4 left-1/2 -translate-x-1/2 px-4 py-1.5 rounded-full bg-black/80 border border-emerald-500/30 text-emerald-400 text-xs font-bold tracking-wide backdrop-blur-md">
        ⬡ HUSTLR LIVE RISK MAP — CHENNAI
      </div>
      <div className="absolute bottom-4 left-4 p-3 rounded-xl bg-black/80 border border-emerald-500/20 backdrop-blur-md">
        <h4 className="text-[10px] tracking-wider text-emerald-400 font-bold mb-2">RISK LEVEL</h4>
        <div className="flex flex-col gap-1.5">
          <div className="flex items-center gap-2 text-[10px] text-white/70 font-semibold"><div className="w-3 h-3 rounded-sm bg-[#3fff8b]"></div>Low (0-30)</div>
          <div className="flex items-center gap-2 text-[10px] text-white/70 font-semibold"><div className="w-3 h-3 rounded-sm bg-[#ffe066]"></div>Moderate (31-60)</div>
          <div className="flex items-center gap-2 text-[10px] text-white/70 font-semibold"><div className="w-3 h-3 rounded-sm bg-[#ff8c42]"></div>High (61-80)</div>
          <div className="flex items-center gap-2 text-[10px] text-white/70 font-semibold"><div className="w-3 h-3 rounded-sm bg-[#ff3b59]"></div>Critical (81-100)</div>
        </div>
      </div>
    </div>
  );
}
