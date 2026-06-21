'use client';

import { ReactNode } from 'react';
import clsx from 'clsx';
import Link from 'next/link';

interface PillarCardProps {
  icon: ReactNode;
  title: string;
  status: 'complete' | 'behind' | 'missed' | 'in-progress';
  score?: number;
  maxScore?: number;
  children?: ReactNode;
  href?: string;
  quickAction?: ReactNode;
}

const statusConfig = {
  complete: { label: '✓ Done', color: 'text-green-400', borderColor: 'border-green-500/30' },
  behind: { label: '⚠ Behind', color: 'text-yellow-400', borderColor: 'border-yellow-500/30' },
  missed: { label: '✗ Missed', color: 'text-red-400', borderColor: 'border-red-500/30' },
  'in-progress': { label: '→ Active', color: 'text-blue-400', borderColor: 'border-blue-500/30' },
};

export function PillarCard({ icon, title, status, children, href, quickAction }: PillarCardProps) {
  const { label, color, borderColor } = statusConfig[status];

  const CardContent = (
    <div className={clsx('rounded-xl border p-4 transition-all hover:border-opacity-60', borderColor)}
      style={{ backgroundColor: '#12121a', borderColor: undefined }}>
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="text-lg">{icon}</span>
          <span className="font-semibold text-sm" style={{ color: '#e2e8f0' }}>{title}</span>
        </div>
        <span className={clsx('text-xs font-medium', color)}>{label}</span>
      </div>
      {children && <div className="space-y-2">{children}</div>}
      {quickAction && <div className="mt-3 pt-3 border-t" style={{ borderColor: '#1e1e2e' }}>{quickAction}</div>}
    </div>
  );

  if (href) {
    return <Link href={href} className="block">{CardContent}</Link>;
  }
  return CardContent;
}
