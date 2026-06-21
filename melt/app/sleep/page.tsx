'use client';

import { useState, useEffect } from 'react';
import { Moon, CheckCircle2, Circle } from 'lucide-react';
import { getTodayLog, saveLog, getSettings } from '@/lib/storage';
import { DailyLog, UserSettings } from '@/lib/types';

const nightChecklist = [
  { key: 'nightCleanser', label: 'Face cleanser', emoji: '🧼' },
  { key: 'acneTreatmentCompleted', label: 'Acne treatment', emoji: '💊' },
  { key: 'moisturizerCompleted', label: 'Moisturizer', emoji: '🧴' },
  { key: 'brushedTeethMorning', label: 'Brush teeth', emoji: '🦷' },
  { key: 'phoneInBedAvoided', label: 'Phone out of bed', emoji: '📵' },
  { key: 'nightRoutineCompleted', label: 'Full night routine done', emoji: '✅' },
];

export default function SleepPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [mounted, setMounted] = useState(false);
  const [bedTime, setBedTime] = useState('');
  const [wakeTime, setWakeTime] = useState('');

  useEffect(() => {
    setMounted(true);
    const l = getTodayLog();
    setLog(l);
    setSettings(getSettings());
    if (l.sleptAtTime) setBedTime(l.sleptAtTime);
    if (l.wakeTime) setWakeTime(l.wakeTime);
  }, []);

  if (!mounted || !log || !settings) return <div className="text-slate-500 p-8">Loading...</div>;

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const toggleItem = (key: keyof DailyLog) => {
    updateLog({ [key]: !(log[key] as boolean) } as Partial<DailyLog>);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Moon size={24} style={{ color: '#818cf8' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Sleep & Shutdown</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Target: in bed by {settings.sleepTargetTime}</p>
        </div>
      </div>

      {/* Wake/bed time logging */}
      <div className="rounded-xl border p-4 space-y-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Time Log</h3>
        <div>
          <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Wake Time</label>
          <div className="flex gap-2">
            <input
              type="time"
              value={wakeTime}
              onChange={e => setWakeTime(e.target.value)}
              className="flex-1 px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            />
            <button
              onClick={() => updateLog({ wakeTime })}
              className="px-4 py-2 rounded-lg text-sm font-medium"
              style={{ backgroundColor: '#6366f1', color: 'white' }}
            >
              Save
            </button>
          </div>
        </div>
        <div>
          <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Bed Time</label>
          <div className="flex gap-2">
            <input
              type="time"
              value={bedTime}
              onChange={e => setBedTime(e.target.value)}
              className="flex-1 px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            />
            <button
              onClick={() => updateLog({ sleptAtTime: bedTime })}
              className="px-4 py-2 rounded-lg text-sm font-medium"
              style={{ backgroundColor: '#6366f1', color: 'white' }}
            >
              Save
            </button>
          </div>
        </div>
      </div>

      {/* Sleep quality */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Sleep Quality</h3>
        <div className="flex gap-2">
          {[1, 2, 3, 4, 5].map(n => (
            <button
              key={n}
              onClick={() => updateLog({ sleepQuality: n })}
              className="flex-1 py-3 rounded-lg text-sm font-bold transition-all"
              style={{
                backgroundColor: log.sleepQuality === n ? '#6366f1' : '#1e1e2e',
                color: log.sleepQuality === n ? 'white' : '#64748b',
              }}
            >
              {n}
            </button>
          ))}
        </div>
        <p className="text-xs mt-2 text-center" style={{ color: '#64748b' }}>1 = terrible, 5 = great</p>
      </div>

      {/* Night checklist */}
      <div className="rounded-xl border p-4 space-y-2" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Night Shutdown Checklist</h3>
        {nightChecklist.map(({ key, label, emoji }) => {
          const done = log[key as keyof DailyLog] as boolean;
          return (
            <button
              key={key}
              onClick={() => toggleItem(key as keyof DailyLog)}
              className="w-full flex items-center gap-3 p-3 rounded-lg transition-all text-left"
              style={{ backgroundColor: done ? '#0f2a0f' : '#1e1e2e' }}
            >
              {done
                ? <CheckCircle2 size={20} style={{ color: '#22c55e', flexShrink: 0 }} />
                : <Circle size={20} style={{ color: '#64748b', flexShrink: 0 }} />}
              <span className="text-lg">{emoji}</span>
              <span className="text-sm font-medium" style={{ color: done ? '#4ade80' : '#e2e8f0' }}>{label}</span>
            </button>
          );
        })}
      </div>

      {/* Phone in bed toggle */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <div className="flex items-center justify-between">
          <div>
            <p className="font-semibold" style={{ color: '#e2e8f0' }}>📵 Phone Out of Bed</p>
            <p className="text-xs" style={{ color: '#64748b' }}>Did you keep your phone off the bed tonight?</p>
          </div>
          <button
            onClick={() => updateLog({ phoneInBedAvoided: !log.phoneInBedAvoided })}
            className="px-4 py-2 rounded-lg font-medium text-sm"
            style={{
              backgroundColor: log.phoneInBedAvoided ? '#166534' : '#1e1e2e',
              color: log.phoneInBedAvoided ? '#4ade80' : '#64748b',
            }}
          >
            {log.phoneInBedAvoided ? '✓ Yes' : 'No'}
          </button>
        </div>
      </div>
    </div>
  );
}
