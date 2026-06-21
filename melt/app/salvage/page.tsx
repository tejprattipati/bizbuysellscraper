'use client';

import { useState, useEffect } from 'react';
import { Zap, CheckCircle2, Circle } from 'lucide-react';
import { getTodayLog, saveLog, getSettings } from '@/lib/storage';
import { DailyLog, UserSettings } from '@/lib/types';
import { calculateDayScore } from '@/lib/scoring';
import { getSalvageMessage } from '@/lib/copy';

interface SalvageTask {
  key: keyof DailyLog;
  label: string;
  emoji: string;
  points: number;
}

const SALVAGE_TASKS: SalvageTask[] = [
  { key: 'showerCompleted', label: 'Shower', emoji: '🚿', points: 4 },
  { key: 'morningRoutineCompleted', label: 'Morning routine (even partial)', emoji: '☀️', points: 8 },
  { key: 'lifted', label: 'Any workout (even 20 min)', emoji: '🏋️', points: 12 },
  { key: 'pornAvoided', label: 'No porn today', emoji: '🛡️', points: 5 },
  { key: 'masturbationAvoided', label: 'Clean day', emoji: '✓', points: 5 },
  { key: 'phoneInBedAvoided', label: 'Phone out of bed', emoji: '📵', points: 3 },
  { key: 'nightRoutineCompleted', label: 'Night skincare routine', emoji: '🌙', points: 6 },
  { key: 'sunscreenApplied', label: 'Applied sunscreen', emoji: '🧴', points: 3 },
];

export default function SalvagePage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setLog(getTodayLog());
    setSettings(getSettings());
  }, []);

  if (!mounted || !log || !settings) return <div className="text-slate-500 p-8">Loading...</div>;

  const score = calculateDayScore(log, settings);
  const message = getSalvageMessage(score);

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const toggleTask = (key: keyof DailyLog) => {
    updateLog({ [key]: !(log[key] as boolean), salvageModeActivated: true } as Partial<DailyLog>);
  };

  const allDone = SALVAGE_TASKS.every(t => log[t.key] as boolean);
  const completedTasks = SALVAGE_TASKS.filter(t => log[t.key] as boolean);
  const totalPoints = completedTasks.reduce((s, t) => s + t.points, 0);

  const markSalvaged = () => {
    updateLog({ salvageCompleted: true, dayStatus: 'salvaged', salvageModeActivated: true });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1a1200' }}>
          <Zap size={24} style={{ color: '#f59e0b' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#f59e0b' }}>SALVAGE MODE</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Minimum viable day. Still counts.</p>
        </div>
      </div>

      {/* Score and message */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#1a1200', borderColor: '#92400e' }}>
        <div className="flex items-center justify-between mb-2">
          <span className="text-3xl font-black" style={{ color: '#f59e0b' }}>{score}/100</span>
          <span className="text-sm px-2 py-1 rounded" style={{ backgroundColor: '#92400e', color: '#fbbf24' }}>
            {completedTasks.length}/{SALVAGE_TASKS.length} done
          </span>
        </div>
        <p className="text-sm" style={{ color: '#d97706' }}>{message}</p>
      </div>

      {/* Points earned */}
      <div className="rounded-xl border p-3 text-center" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <p className="text-sm" style={{ color: '#64748b' }}>Salvage points earned</p>
        <p className="text-4xl font-black" style={{ color: '#6366f1' }}>{totalPoints}</p>
        <p className="text-xs" style={{ color: '#64748b' }}>of {SALVAGE_TASKS.reduce((s, t) => s + t.points, 0)} possible</p>
      </div>

      {/* Salvage checklist */}
      <div className="space-y-2">
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Minimum Viable Checklist</h3>
        {SALVAGE_TASKS.map(({ key, label, emoji, points }) => {
          const done = log[key] as boolean;
          return (
            <button
              key={key}
              onClick={() => toggleTask(key)}
              className="w-full flex items-center gap-3 p-4 rounded-xl text-left transition-all"
              style={{ backgroundColor: done ? '#0f2a0f' : '#12121a', border: `1px solid ${done ? '#166534' : '#1e1e2e'}` }}
            >
              {done
                ? <CheckCircle2 size={22} style={{ color: '#22c55e', flexShrink: 0 }} />
                : <Circle size={22} style={{ color: '#475569', flexShrink: 0 }} />}
              <span className="text-lg">{emoji}</span>
              <span className="flex-1 text-sm font-medium" style={{ color: done ? '#4ade80' : '#e2e8f0' }}>{label}</span>
              <span className="text-xs" style={{ color: '#64748b' }}>+{points}pts</span>
            </button>
          );
        })}
      </div>

      {/* IB quick add */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-2" style={{ color: '#e2e8f0' }}>Quick IB Time</h3>
        <div className="flex gap-2">
          {[30, 45, 60].map(m => (
            <button
              key={m}
              onClick={() => updateLog({ ibMinutes: log.ibMinutes + m })}
              className="flex-1 py-2 rounded-lg text-sm font-medium"
              style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
            >
              +{m}m IB
            </button>
          ))}
        </div>
      </div>

      {/* Mark salvaged */}
      {(allDone || completedTasks.length >= 4) && !log.salvageCompleted && (
        <button
          onClick={markSalvaged}
          className="w-full py-4 rounded-xl font-black text-lg"
          style={{ backgroundColor: '#f59e0b', color: '#0a0a0f' }}
        >
          ⚡ MARK DAY SALVAGED
        </button>
      )}

      {log.salvageCompleted && (
        <div className="rounded-xl p-4 text-center" style={{ backgroundColor: '#0f2a0f', border: '1px solid #166534' }}>
          <p className="text-2xl font-black" style={{ color: '#4ade80' }}>✓ Day Salvaged</p>
          <p className="text-sm mt-1" style={{ color: '#64748b' }}>Not ideal. Better than nothing. Reset tomorrow.</p>
        </div>
      )}
    </div>
  );
}
