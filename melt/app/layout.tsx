import type { Metadata } from 'next';
import './globals.css';
import { Sidebar } from '@/components/Sidebar';
import { BottomNav } from '@/components/BottomNav';

export const metadata: Metadata = {
  title: 'Melt — Lock In This Summer',
  description: 'Melt the summer. Lock in.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen" style={{ backgroundColor: '#0a0a0f', color: '#e2e8f0' }}>
        <div className="flex min-h-screen">
          {/* Desktop sidebar */}
          <Sidebar />
          {/* Main content */}
          <main className="flex-1 md:ml-56 pb-20 md:pb-0">
            <div className="max-w-4xl mx-auto px-4 py-6">
              {children}
            </div>
          </main>
        </div>
        {/* Mobile bottom nav */}
        <BottomNav />
      </body>
    </html>
  );
}
