'use client';
import { CompactCard } from '@/components/AdminShared';
import dynamic from 'next/dynamic';
const H3RiskMap = dynamic(() => import('@/components/H3RiskMap'), { ssr: false });

export default function MapPage() {
  return (
    <div className="h-full">
      <CompactCard title="Live Risk Map" accent="red">
        <H3RiskMap />
      </CompactCard>
    </div>
  );
}