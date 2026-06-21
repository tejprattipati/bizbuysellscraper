'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import clsx from 'clsx';
import {
  Home, Sun, Apple, Dumbbell, Moon, Shield, Sparkles,
  BookOpen, Star, BarChart2, Settings, Zap
} from 'lucide-react';

const navItems = [
  { href: '/', icon: Home, label: 'Today' },
  { href: '/morning', icon: Sun, label: 'Morning' },
  { href: '/nutrition', icon: Apple, label: 'Nutrition' },
  { href: '/lifting', icon: Dumbbell, label: 'Training' },
  { href: '/sleep', icon: Moon, label: 'Sleep' },
  { href: '/discipline', icon: Shield, label: 'Discipline' },
  { href: '/skincare', icon: Sparkles, label: 'Skincare' },
  { href: '/ib-prep', icon: BookOpen, label: 'IB Prep' },
  { href: '/fun', icon: Star, label: 'Fun' },
  { href: '/analytics', icon: BarChart2, label: 'Analytics' },
  { href: '/settings', icon: Settings, label: 'Settings' },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden md:flex fixed left-0 top-0 h-full w-56 flex-col border-r z-30"
      style={{ backgroundColor: '#0d0d14', borderColor: '#1e1e2e' }}>
      {/* Logo */}
      <div className="px-4 py-5 border-b" style={{ borderColor: '#1e1e2e' }}>
        <div className="flex items-center gap-3">
          <div className="relative">
            <span className="text-3xl">🧊</span>
            <div className="absolute inset-0 blur-md rounded-full" style={{ background: 'rgba(99,102,241,0.4)' }} />
          </div>
          <div>
            <div className="text-lg font-bold tracking-tight" style={{ color: '#e2e8f0' }}>Melt</div>
            <div className="text-xs" style={{ color: '#64748b' }}>Lock in.</div>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {navItems.map(({ href, icon: Icon, label }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={clsx(
                'flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-all',
                active
                  ? 'text-white'
                  : 'hover:text-white'
              )}
              style={active
                ? { backgroundColor: '#6366f1', color: 'white' }
                : { color: '#64748b' }
              }
            >
              <Icon size={16} />
              {label}
            </Link>
          );
        })}
        <div className="pt-2 border-t" style={{ borderColor: '#1e1e2e' }}>
          <Link
            href="/salvage"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-all"
            style={{ color: '#f59e0b' }}
          >
            <Zap size={16} />
            Salvage Mode
          </Link>
        </div>
      </nav>
    </aside>
  );
}
