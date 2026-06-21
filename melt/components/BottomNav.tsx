'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import clsx from 'clsx';
import { Home, Sun, Apple, Dumbbell, Moon, Shield, Sparkles, BookOpen, Star, BarChart2, Settings } from 'lucide-react';

const navItems = [
  { href: '/', icon: Home, label: 'Today' },
  { href: '/morning', icon: Sun, label: 'Morning' },
  { href: '/nutrition', icon: Apple, label: 'Nutrition' },
  { href: '/lifting', icon: Dumbbell, label: 'Train' },
  { href: '/sleep', icon: Moon, label: 'Sleep' },
  { href: '/discipline', icon: Shield, label: 'Disc.' },
  { href: '/skincare', icon: Sparkles, label: 'Skin' },
  { href: '/ib-prep', icon: BookOpen, label: 'IB' },
  { href: '/fun', icon: Star, label: 'Fun' },
  { href: '/analytics', icon: BarChart2, label: 'Stats' },
  { href: '/settings', icon: Settings, label: 'More' },
];

export function BottomNav() {
  const pathname = usePathname();
  // Show only first 5 items on mobile for cleaner look
  const visibleItems = navItems.slice(0, 5);

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 border-t"
      style={{ backgroundColor: '#0d0d14', borderColor: '#1e1e2e' }}>
      <div className="flex justify-around px-1 py-2">
        {visibleItems.map(({ href, icon: Icon, label }) => {
          const active = pathname === href;
          return (
            <Link key={href} href={href} className="flex flex-col items-center gap-1 px-2 py-1 rounded-lg min-w-0">
              <Icon size={20} color={active ? '#6366f1' : '#64748b'} />
              <span className="text-xs" style={{ color: active ? '#6366f1' : '#64748b' }}>{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
