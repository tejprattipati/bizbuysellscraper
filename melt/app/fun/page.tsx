'use client';

import { useState, useEffect } from 'react';
import { Star, AlertTriangle } from 'lucide-react';
import { getTodayLog, saveLog } from '@/lib/storage';
import { DailyLog } from '@/lib/types';

const FUN_ACTIVITIES = [
  { key: 'basketball', label: 'Basketball', emoji: '🏀' },
  { key: 'volleyball', label: 'Volleyball', emoji: '🏐' },
  { key: 'walk', label: 'Walk/Explore', emoji: '🚶' },
  { key: 'rollerblade', label: 'Rollerblade', emoji: '🛼' },
  { key: 'singing', label: 'Singing', emoji: '🎤' },
  { key: 'friends', label: 'Hang with friends', emoji: '👥' },
  { key: 'other', label: 'Other', emoji: '⭐' },
];

export default function FunPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [mounted, setMounted] = useState(false);
  const [customActivity, setCustomActivity] = useState('');
  const [animeInput, setAnimeInput] = useState('');

  useEffect(() => {
    setMounted(true);
    const l = getTodayLog();
    setLog(l);
    if (l.animeMinutes) setAnimeInput(l.animeMinutes.toString());
  }, []);

  if (!mounted || !log) return <div className="text-slate-500 p-8">Loading...</div>;

  const ANIME_CAP = 90;
  const animeOver = log.animeMinutes > ANIME_CAP;

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const selectActivity = (key: string, label: string) => {
    updateLog({
      funActivityCompleted: true,
      funActivityDescription: label,
      sportPlayed: ['basketball', 'volleyball', 'walk', 'rollerblade'].includes(key)
        ? (key as DailyLog['sportPlayed'])
        : 'other',
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Star size={24} style={{ color: '#fbbf24' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Fun & Social</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Summer is not just grind. Lock in fun too.</p>
        </div>
      </div>

      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Today's Fun Activity</h3>
        {log.funActivityCompleted && log.funActivityDescription ? (
          <div className="flex items-center justify-between p-3 rounded-lg" style={{ backgroundColor: '#0f2a0f' }}>
            <span className="text-sm font-medium" style={{ color: '#4ade80' }}>✓ {log.funActivityDescription}</span>
            <button onClick={() => updateLog({ funActivityCompleted: false, funActivityDescription: undefined })} className="text-xs" style={{ color: '#64748b' }}>clear</button>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-2">
            {FUN_ACTIVITIES.map(({ key, label, emoji }) => (
              <button key={key} onClick={() => selectActivity(key, label)}
                className="flex items-center gap-2 p-3 rounded-lg text-sm font-medium text-left transition-all"
                style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>
                <span className="text-lg">{emoji}</span>{label}
              </button>
            ))}
          </div>
        )}
        <div className="mt-3 flex gap-2">
          <input className="flex-1 px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            placeholder="Custom activity..."
            value={customActivity}
            onChange={e => setCustomActivity(e.target.value)} />
          <button onClick={() => { if (customActivity) { selectActivity('other', customActivity); setCustomActivity(''); } }}
            className="px-3 py-2 rounded-lg text-sm" style={{ backgroundColor: '#6366f1', color: 'white' }}>Add</button>
        </div>
      </div>

      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: animeOver ? '#92400e' : '#1e1e2e' }}>
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Anime Tracker</h3>
          <span className="text-xs px-2 py-1 rounded" style={{ backgroundColor: animeOver ? '#7f1d1d' : '#1e1e2e', color: animeOver ? '#fca5a5' : '#64748b' }}>
            Cap: {ANIME_CAP} min
          </span>
        </div>
        <div className="flex gap-2 mb-3">
          <input type="number" value={animeInput} onChange={e => setAnimeInput(e.target.value)}
            className="flex-1 px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            placeholder="Minutes watched" />
          <button onClick={() => updateLog({ animeMinutes: parseInt(animeInput) || 0 })}
            className="px-4 py-2 rounded-lg text-sm font-medium" style={{ backgroundColor: '#6366f1', color: 'white' }}>Set</button>
        </div>
        <div className="flex gap-2 mb-3">
          {[24, 45, 90].map(m => (
            <button key={m} onClick={() => { const newVal = log.animeMinutes + m; setAnimeInput(newVal.toString()); updateLog({ animeMinutes: newVal }); }}
              className="px-3 py-1.5 rounded-lg text-sm" style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>+{m}m</button>
          ))}
        </div>
        <div className="w-full rounded-full h-2" style={{ backgroundColor: '#1e1e2e' }}>
          <div className="h-2 rounded-full transition-all" style={{ width: `${Math.min(100, (log.animeMinutes / ANIME_CAP) * 100)}%`, backgroundColor: animeOver ? '#ef4444' : '#6366f1' }} />
        </div>
        <p className="text-xs mt-1" style={{ color: '#64748b' }}>{log.animeMinutes} / {ANIME_CAP} minutes</p>
        {animeOver && (
          <div className="flex items-center gap-2 mt-3 p-2 rounded-lg" style={{ backgroundColor: '#1a0a0a' }}>
            <AlertTriangle size={14} style={{ color: '#f59e0b' }} />
            <p className="text-xs" style={{ color: '#f59e0b' }}>Over the cap. Cut it here.</p>
          </div>
        )}
      </div>

      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>🎤 Singing Practice</h3>
        <div className="flex gap-2">
          <input type="number" placeholder="Minutes"
            className="flex-1 px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            value={log.singingMinutes || ''}
            onChange={e => updateLog({ singingMinutes: parseInt(e.target.value) || 0 })} />
          <span className="flex items-center text-sm" style={{ color: '#64748b' }}>min</span>
        </div>
      </div>
    </div>
  );
}
