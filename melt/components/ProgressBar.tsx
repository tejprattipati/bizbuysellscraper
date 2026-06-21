'use client';

import clsx from 'clsx';

interface ProgressBarProps {
  value: number;
  max: number;
  label?: string;
  showValue?: boolean;
  size?: 'sm' | 'md' | 'lg';
  colorClass?: string;
}

export function ProgressBar({ value, max, label, showValue = true, size = 'md', colorClass }: ProgressBarProps) {
  const pct = Math.min(100, max > 0 ? (value / max) * 100 : 0);

  const barColor = colorClass || (pct >= 100 ? 'bg-green-500' : pct >= 70 ? 'bg-blue-500' : pct >= 40 ? 'bg-yellow-500' : 'bg-red-500');
  const heightClass = size === 'sm' ? 'h-1.5' : size === 'lg' ? 'h-4' : 'h-2.5';

  return (
    <div className="w-full">
      {(label || showValue) && (
        <div className="flex justify-between items-center mb-1">
          {label && <span className="text-sm" style={{ color: '#94a3b8' }}>{label}</span>}
          {showValue && <span className="text-sm font-medium" style={{ color: '#e2e8f0' }}>{value} / {max}</span>}
        </div>
      )}
      <div className={clsx('w-full rounded-full', heightClass)} style={{ backgroundColor: '#1e1e2e' }}>
        <div
          className={clsx('rounded-full transition-all duration-500', heightClass, barColor)}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}
