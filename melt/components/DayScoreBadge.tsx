'use client';

import { getDayLabel, getDayStatusColor, getScoreBgColor } from '@/lib/scoring';

interface DayScoreBadgeProps {
  score: number;
  size?: 'sm' | 'md' | 'lg';
}

export function DayScoreBadge({ score, size = 'md' }: DayScoreBadgeProps) {
  const label = getDayLabel(score);
  const textColor = getDayStatusColor(score);
  const bgBorder = getScoreBgColor(score);

  const sizeClasses = {
    sm: 'w-16 h-16 text-xl',
    md: 'w-24 h-24 text-3xl',
    lg: 'w-32 h-32 text-4xl',
  };

  return (
    <div className={`relative flex flex-col items-center justify-center rounded-full border-2 ${sizeClasses[size]} ${bgBorder}`}>
      <span className={`font-bold ${textColor}`}>{score}</span>
      <span className="text-xs" style={{ color: '#64748b' }}>{label}</span>
    </div>
  );
}
