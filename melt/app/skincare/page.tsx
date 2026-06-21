'use client';

import { useState, useEffect } from 'react';
import { Sparkles, CheckCircle2, Circle } from 'lucide-react';
import { getTodayLog, saveLog, recalculateStreaks } from '@/lib/storage';
import { DailyLog } from '@/lib/types';

const morningRoutine = [
  { key: 'cleanserCompleted', label: 'Gentle cleanser', emoji: '🧼' },
  { key: 'sunscreenApplied', label: 'SPF (morning)', emoji: '🧴' },
  { key: 'sunscreenReapplied', label: 'SPF reapply (afternoon)', emoji: '☀️' },
  { key: 'brushedTeethMorning', label: 'Brush teeth (AM)', emoji: '🦷' },
];

const nightRoutineItems = [
  { key: 'nightCleanser', label: 'Double cleanse', emoji: '🌙' },
  { key: 'acneTreatmentCompleted', label: 'Acne treatment', emoji: '💊' },
  { key: 'moisturizerCompleted', label: 'Moisturizer', emoji: '💧' },
  { key: 'pillowcaseChanged', label: 'Pillowcase clean', emoji: '🛏️' },
  { key: 'nightRoutineCompleted', label: 'Full night routine done', emoji: '✅' },
];

export default function SkincarePage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setLog(getTodayLog());
  }, []);

  if (!mounted || !log) return <div className="text-slate-500 p-8">Loading...</div>;

  const streaks = recalculateStreaks();

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const toggleItem = (key: keyof DailyLog) => {
    updateLog({ [key]: !(log[key] as boolean) } as Partial<DailyLog>);
  };

  const morningDone = morningRoutine.filter(i => log[i.key as keyof DailyLog] as boolean).length;
  const nightDone = nightRoutineItems.filter(i => log[i.key as keyof DailyLog] as boolean).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Sparkles size={24} style={{ color: '#f472b6' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Skincare</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Streak: {streaks.skincare} days</p>
        </div>
      </div>

      {/* Progress summary */}
      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-xl border p-3 text-center" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
          <div className="text-2xl font-bold" style={{ color: morningDone === morningRoutine.length ? '#22c55e' : '#f59e0b' }}>
            {morningDone}/{morningRoutine.length}
          </div>
          <div className="text-xs mt-1" style={{ color: '#64748b' }}>Morning done</div>
        </div>
        <div className="rounded-xl border p-3 text-center" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
          <div className="text-2xl font-bold" style={{ color: nightDone === nightRoutineItems.length ? '#22c55e' : '#818cf8' }}>
            {nightDone}/{nightRoutineItems.length}
          </div>
          <div className="text-xs mt-1" style={{ color: '#64748b' }}>Night done</div>
        </div>
      </div>

      {/* Morning routine */}
      <div className="rounded-xl border p-4 space-y-2" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#fbbf24' }}>☀️ Morning Routine</h3>
        {morningRoutine.map(({ key, label, emoji }) => {
          const done = log[key as keyof DailyLog] as boolean;
          return (
            <button
              key={key}
              onClick={() => toggleItem(key as keyof DailyLog)}
              className="w-full flex items-center gap-3 p-3 rounded-lg transition-all text-left"
              style={{ backgroundColor: done ? '#0f2a0f' : '#1e1e2e' }}
            >
              {done ? <CheckCircle2 size={20} style={{ color: '#22c55e', flexShrink: 0 }} /> : <Circle size={20} style={{ color: '#64748b', flexShrink: 0 }} />}
              <span className="text-lg">{emoji}</span>
              <span className="text-sm font-medium" style={{ color: done ? '#4ade80' : '#e2e8f0' }}>{label}</span>
            </button>
          );
        })}
      </div>

      {/* Acne severity */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Acne Severity Today</h3>
        <div className="flex gap-2">
          {[1, 2, 3, 4, 5].map(n => (
            <button
              key={n}
              onClick={() => updateLog({ acneSeverity: n })}
              className="flex-1 py-3 rounded-lg text-sm font-bold transition-all"
              style={{
                backgroundColor: log.acneSeverity === n ? (n <= 2 ? '#166534' : n <= 3 ? '#92400e' : '#7f1d1d') : '#1e1e2e',
                color: log.acneSeverity === n ? 'white' : '#64748b',
              }}
            >
              {n}
            </button>
          ))}
        </div>
        <p className="text-xs mt-2 text-center" style={{ color: '#64748b' }}>1 = clear, 5 = severe</p>
      </div>

      {/* Night routine */}
      <div className="rounded-xl border p-4 space-y-2" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#818cf8' }}>🌙 Night Routine</h3>
        {nightRoutineItems.map(({ key, label, emoji }) => {
          const done = log[key as keyof DailyLog] as boolean;
          return (
            <button
              key={key}
              onClick={() => toggleItem(key as keyof DailyLog)}
              className="w-full flex items-center gap-3 p-3 rounded-lg transition-all text-left"
              style={{ backgroundColor: done ? '#0f2a0f' : '#1e1e2e' }}
            >
              {done ? <CheckCircle2 size={20} style={{ color: '#22c55e', flexShrink: 0 }} /> : <Circle size={20} style={{ color: '#64748b', flexShrink: 0 }} />}
              <span className="text-lg">{emoji}</span>
              <span className="text-sm font-medium" style={{ color: done ? '#4ade80' : '#e2e8f0' }}>{label}</span>
            </button>
          );
        })}
      </div>

      {/* Pillowcase reminder */}
      {!log.pillowcaseChanged && (
        <div className="rounded-xl border px-4 py-3" style={{ backgroundColor: '#12121a', borderColor: '#6366f1' }}>
          <p className="text-sm" style={{ color: '#a5b4fc' }}>🛏️ Pillowcase reminder: change it if it's been more than 3 days.</p>
        </div>
      )}
    </div>
  );
}
