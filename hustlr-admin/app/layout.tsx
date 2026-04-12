import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Hustlr — Insurer Admin Dashboard',
  description: 'Parametric income insurance admin panel — Guidewire DEVTrails 2026',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-screen" style={{ background: '#0A0B0A', color: '#E1E3DE' }}>
        {children}
      </body>
    </html>
  );
}
