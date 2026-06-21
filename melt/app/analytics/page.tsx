'use client';

import { useState, useEffect } from 'react';
import { BarChart2 } from 'lucide-react';
import { getAllLogs, recalculateStreaks, getSettings } from '@/lib/storage';
import { calculateDayScore, getDayLabel } from '@/lib/scoring';
import { format, subDays } from 'date-fns';

export default function AnalyticsPage() {
  const [mounted, setMounted] = useState(false);
  const [weekData, setWeekData] = useState<{ date: string; score: number }[]>([]);
  const [streaks, setStreaks] = useState({ pornFree: 0, masturbationFree: 0, phoneOutOfBed: 0, morningLaunch: 0, skincare: 0, wakeOnTime: 0 });
  const [avgProtein, setAvgProtein] = useState(0);
  const [avgCalories, setAvgCalories] = useState(0);
  const [liftDays, setLiftDays] = useState(0);

  useEffect(() => {
    setMounted(true);
    const logs = getAllLogs();
    const settings = getSettings();
    const today = new Date();
    const week = Array.from({ length: 7 }, (_, i) => {
      const date = format(subDays(today, 6 - i), 'yyyy-MM-dd');
      const log = logs[date];
      if (!log) return { date, score: 0 };
      return { date, score: calculateDayScore(log, settings) };
    });
    setWeekData(week);
    const allLogs = Object.values(logs);
    if (allLogs.length > 0) {
      setAvgProtein(Math.round(allLogs.reduce((s, l) => s + l.proteinGrams, 0) / allLogs.length));
      setAvgCalories(Math.round(allLogs.reduce((s, l) => s + l.calories, 0) / allLogs.length));
      setLiftDays(allLogs.filter(l => l.lifted).length);
    }
    setStreaks(recalculateStreaks());
  }, []);

  if (!mounted) return <div className="text-slate-500 p-8">Loading...</div>;

  const maxScore = Math.max(...weekData.map(d => d.score), 1);
  const getBarColor = (score: number) => {
    if (score >= 85) return '#22c55e';
    if (score >= 70) return '#6366f1';
    if (score >= 50) return '#f59e0b';
    if (score >= 25) return '#f97316';
    return '#ef4444';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <BarChart2 size={24} style={{ color: '#6366f1' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Analytics</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Last 7 days</p>
        </div>
      </div>

      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-4" style={{ color: '#e2e8f0' }}>Day Scores (7 days)</h3>
        <div className="flex items-end gap-2 h-32">
          {weekData.map(({ date, score }) => (
            <div key={date} className="flex-1 flex flex-col items-center gap-1">
              <span className="text-xs" style={{ color: '#94a3b8' }}>{score || '—'}</span>
              <div className="w-full rounded-t-sm transition-all"
                style={{ height: `${score > 0 ? Math.max(4, (score / maxScore) * 100) : 4}px`, backgroundColor: score > 0 ? getBarColor(score) : '#1e1e2e' }} />
              <span className="text-xs" style={{ color: '#475569' }}>
                {format(new Date(date + 'T12:00:00'), 'EEE')}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Current Streaks</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: '🛡️ Porn-free', value: streaks.pornFree },
            { label: '✓ Clean days', value: streaks.masturbationFree },
            { label: '📵 Phone out', value: streaks.phoneOutOfBed },
            { label: '☀️ Morning', value: streaks.morningLaunch },
            { label: '✨ Skincare', value: streaks.skincare },
            { label: '⏰ Wake on time', value: streaks.wakeOnTime },
          ].map(({ label, value }) => (
            <div key={label} className="p-3 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
              <div className="text-sm" style={{ color: '#64748b' }}>{label}</div>
              <div className="text-2xl font-bold mt-1" style={{ color: value > 0 ? '#f59e0b' : '#475569' }}>
                {value} <span className="text-sm font-normal" style={{ color: '#64748b' }}>days</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>All-Time Averages</h3>
        <div className="space-y-3">
          {[
            { label: 'Avg Protein', value: `${avgProtein}g`, target: '140g', ok: avgProtein >= 140 },
            { label: 'Avg Calories', value: `${avgCalories}`, target: '1600-1800', ok: avgCalories >= 1600 && avgCalories <= 1800 },
            { label: 'Total Lift Days', value: `${liftDays}`, target: 'ongoing', ok: liftDays > 0 },
          ].map(({ label, value, target, ok }) => (
            <div key={label} className="flex items-center justify-between p-3 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
              <div>
                <div className="text-sm font-medium" style={{ color: '#e2e8f0' }}>{label}</div>
                <div className="text-xs" style={{ color: '#64748b' }}>Target: {target}</div>
              </div>
              <div className="text-lg font-bold" style={{ color: ok ? '#22c55e' : '#f59e0b' }}>{value}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
