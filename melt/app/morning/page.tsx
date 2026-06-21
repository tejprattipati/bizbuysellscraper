'use client';

import { useState, useEffect } from 'react';
import { Sun, CheckCircle2, Circle, ChevronRight } from 'lucide-react';
import { getTodayLog, saveLog, getSettings, recalculateStreaks } from '@/lib/storage';
import { DailyLog, UserSettings } from '@/lib/types';
import { ProgressBar } from '@/components/ProgressBar';
import { getMorningMessage } from '@/lib/copy';

interface CheckItem {
  key: keyof DailyLog;
  label: string;
  emoji: string;
  points: number;
}

const morningChecklist: CheckItem[] = [
  { key: 'brushedTeethMorning', label: 'Brush teeth', emoji: '🦷', points: 1 },
  { key: 'showerCompleted', label: 'Shower', emoji: '🚿', points: 2 },
  { key: 'sunscreenApplied', label: 'Apply sunscreen', emoji: '🧴', points: 2 },
  { key: 'morningRoutineCompleted', label: 'Full morning routine done', emoji: '✅', points: 3 },
];

export default function MorningPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [mounted, setMounted] = useState(false);
  const [wakeTime, setWakeTime] = useState('');

  useEffect(() => {
    setMounted(true);
    const l = getTodayLog();
    setLog(l);
    setSettings(getSettings());
    if (l.wakeTime) setWakeTime(l.wakeTime);
  }, []);

  if (!mounted || !log || !settings) return <div className="text-slate-500 p-8">Loading...</div>;

  const hour = new Date().getHours();
  const completed = morningChecklist.filter(item => log[item.key] as boolean).length;
  const total = morningChecklist.length;
  const pct = Math.round((completed / total) * 100);

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const handleWakeTime = () => {
    const now = new Date();
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    setWakeTime(time);
    updateLog({ wakeTime: time, outOfBedTime: time });
  };

  const toggleItem = (key: keyof DailyLog) => {
    const current = log[key] as boolean;
    updateLog({ [key]: !current } as Partial<DailyLog>);
  };

  const streaks = recalculateStreaks();

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Sun size={24} style={{ color: '#f59e0b' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Morning Launch</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>{getMorningMessage(hour, log.morningRoutineCompleted)}</p>
        </div>
      </div>

      {/* Streak badge */}
      <div className="flex gap-3">
        <div className="px-3 py-2 rounded-lg text-sm" style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>
          🔥 Morning streak: <span className="font-bold" style={{ color: '#f59e0b' }}>{streaks.morningLaunch} days</span>
        </div>
        <div className="px-3 py-2 rounded-lg text-sm" style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>
          ⏰ Wake streak: <span className="font-bold" style={{ color: '#f59e0b' }}>{streaks.wakeOnTime} days</span>
        </div>
      </div>

      {/* Progress */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <div className="flex items-center justify-between mb-3">
          <span className="font-semibold" style={{ color: '#e2e8f0' }}>Progress</span>
          <span className="text-2xl font-bold" style={{ color: pct >= 100 ? '#22c55e' : '#6366f1' }}>{pct}%</span>
        </div>
        <ProgressBar value={completed} max={total} showValue={false} />
        <p className="text-xs mt-2" style={{ color: '#64748b' }}>{completed} of {total} tasks complete</p>
      </div>

      {/* Wake time */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Wake Time</h3>
        {log.wakeTime ? (
          <div className="flex items-center gap-3">
            <span className="text-2xl font-bold" style={{ color: '#22c55e' }}>{log.wakeTime}</span>
            <span className="text-sm" style={{ color: '#64748b' }}>logged</span>
            <button onClick={() => updateLog({ wakeTime: undefined })} className="text-xs" style={{ color: '#64748b' }}>clear</button>
          </div>
        ) : (
          <div className="space-y-2">
            <button
              onClick={handleWakeTime}
              className="w-full py-3 rounded-lg font-semibold text-sm transition-all"
              style={{ backgroundColor: '#6366f1', color: 'white' }}
            >
              Log Wake Time (Now)
            </button>
            <div className="flex gap-2">
              <input
                type="time"
                value={wakeTime}
                onChange={e => setWakeTime(e.target.value)}
                className="flex-1 px-3 py-2 rounded-lg text-sm border"
                style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              />
              <button
                onClick={() => wakeTime && updateLog({ wakeTime, outOfBedTime: wakeTime })}
                className="px-4 py-2 rounded-lg text-sm font-medium"
                style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
              >
                Set
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Checklist */}
      <div className="rounded-xl border p-4 space-y-2" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Morning Checklist</h3>
        {morningChecklist.map(({ key, label, emoji, points }) => {
          const done = log[key] as boolean;
          return (
            <button
              key={key}
              onClick={() => toggleItem(key)}
              className="w-full flex items-center gap-3 p-3 rounded-lg transition-all text-left"
              style={{ backgroundColor: done ? '#0f2a0f' : '#1e1e2e' }}
            >
              {done
                ? <CheckCircle2 size={22} style={{ color: '#22c55e', flexShrink: 0 }} />
                : <Circle size={22} style={{ color: '#64748b', flexShrink: 0 }} />
              }
              <span className="text-lg">{emoji}</span>
              <div className="flex-1">
                <span className="text-sm font-medium" style={{ color: done ? '#4ade80' : '#e2e8f0' }}>{label}</span>
              </div>
              <span className="text-xs" style={{ color: '#64748b' }}>+{points}pts</span>
            </button>
          );
        })}
      </div>

      {/* Late launch button */}
      {!log.morningRoutineCompleted && hour >= 10 && (
        <div className="rounded-xl border p-4" style={{ backgroundColor: '#1a1200', borderColor: '#92400e' }}>
          <p className="text-sm font-medium mb-2" style={{ color: '#f59e0b' }}>Late launch detected. Still worth doing.</p>
          <button
            onClick={() => updateLog({ morningRoutineCompleted: true, showerCompleted: true })}
            className="w-full py-3 rounded-lg font-bold text-sm"
            style={{ backgroundColor: '#f59e0b', color: '#0a0a0f' }}
          >
            Mark Late Launch Complete
          </button>
        </div>
      )}
    </div>
  );
}
