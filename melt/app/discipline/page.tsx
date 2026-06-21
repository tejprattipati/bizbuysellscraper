'use client';

import { useState, useEffect } from 'react';
import { Shield, AlertTriangle } from 'lucide-react';
import Link from 'next/link';
import { getTodayLog, saveLog, recalculateStreaks } from '@/lib/storage';
import { DailyLog, UrgeLog } from '@/lib/types';

function generateId() {
  return Math.random().toString(36).substr(2, 9);
}

export default function DisciplinePage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [mounted, setMounted] = useState(false);
  const [showUrgeForm, setShowUrgeForm] = useState(false);
  const [showRelapseForm, setShowRelapseForm] = useState(false);
  const [urgeForm, setUrgeForm] = useState({ intensity: 5, trigger: '', actionTaken: '', outcome: 'resisted' as UrgeLog['outcome'] });
  const [relapseForm, setRelapseForm] = useState({ type: 'porn' as 'porn' | 'masturbation' | 'both', notes: '' });

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

  const logUrge = () => {
    if (!urgeForm.trigger) return;
    const urge: UrgeLog = {
      id: generateId(),
      time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
      intensity: urgeForm.intensity,
      trigger: urgeForm.trigger,
      actionTaken: urgeForm.actionTaken,
      outcome: urgeForm.outcome,
    };
    updateLog({ urgesLogged: [...log.urgesLogged, urge] });
    setUrgeForm({ intensity: 5, trigger: '', actionTaken: '', outcome: 'resisted' });
    setShowUrgeForm(false);
  };

  const logRelapse = () => {
    updateLog({
      relapseOccurred: true,
      relapseType: relapseForm.type,
      pornAvoided: relapseForm.type !== 'masturbation' ? false : log.pornAvoided,
      masturbationAvoided: relapseForm.type !== 'porn' ? false : log.masturbationAvoided,
    });
    setShowRelapseForm(false);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Shield size={24} style={{ color: '#818cf8' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Discipline</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Private. Honest. Clean.</p>
        </div>
      </div>

      {/* Streaks */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { label: 'Porn-free', value: streaks.pornFree, color: '#818cf8' },
          { label: 'Clean', value: streaks.masturbationFree, color: '#34d399' },
          { label: 'Phone out', value: streaks.phoneOutOfBed, color: '#60a5fa' },
        ].map(({ label, value, color }) => (
          <div key={label} className="rounded-xl border p-3 text-center" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
            <div className="text-2xl font-bold" style={{ color }}>{value}</div>
            <div className="text-xs mt-1" style={{ color: '#64748b' }}>{label}</div>
            <div className="text-xs" style={{ color: '#475569' }}>days</div>
          </div>
        ))}
      </div>

      {/* Today's status */}
      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Today's Status</h3>
        {[
          { key: 'pornAvoided', label: 'Avoided porn', emoji: '🛡️' },
          { key: 'masturbationAvoided', label: 'Clean day', emoji: '✓' },
          { key: 'phoneInBedAvoided', label: 'Phone out of bed', emoji: '📵' },
          { key: 'bedRottingAvoided', label: 'No bed rotting', emoji: '🛏️' },
        ].map(({ key, label, emoji }) => {
          const val = log[key as keyof DailyLog] as boolean;
          return (
            <button
              key={key}
              onClick={() => updateLog({ [key]: !val } as Partial<DailyLog>)}
              className="w-full flex items-center gap-3 p-3 rounded-lg text-left transition-all"
              style={{ backgroundColor: val ? '#0f2a0f' : '#1e1e2e' }}
            >
              <div className={`w-5 h-5 rounded flex items-center justify-center text-sm ${val ? 'bg-green-600' : 'bg-slate-700'}`}>
                {val ? '✓' : ''}
              </div>
              <span className="text-sm" style={{ color: val ? '#4ade80' : '#94a3b8' }}>{emoji} {label}</span>
            </button>
          );
        })}
      </div>

      {/* Urge mode panic button */}
      <Link href="/urge-mode">
        <div className="rounded-xl p-5 text-center cursor-pointer transition-all hover:opacity-90"
          style={{ backgroundColor: '#1a0a0a', border: '2px solid #7f1d1d' }}>
          <div className="text-3xl mb-2">⚡</div>
          <p className="font-bold text-lg" style={{ color: '#ef4444' }}>URGE MODE</p>
          <p className="text-sm mt-1" style={{ color: '#92400e' }}>Tap when it's urgent. Leave the room.</p>
        </div>
      </Link>

      {/* Log urge */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Urge Log ({log.urgesLogged.length})</h3>
          <button
            onClick={() => setShowUrgeForm(!showUrgeForm)}
            className="px-3 py-1.5 rounded-lg text-xs font-medium"
            style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
          >
            + Log Urge
          </button>
        </div>

        {showUrgeForm && (
          <div className="space-y-3 mb-4 p-3 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
            <div>
              <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Intensity (1-10): {urgeForm.intensity}</label>
              <input type="range" min="1" max="10" value={urgeForm.intensity}
                onChange={e => setUrgeForm(p => ({ ...p, intensity: parseInt(e.target.value) }))}
                className="w-full" />
            </div>
            <input
              className="w-full px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#12121a', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Trigger"
              value={urgeForm.trigger}
              onChange={e => setUrgeForm(p => ({ ...p, trigger: e.target.value }))}
            />
            <input
              className="w-full px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#12121a', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Action taken"
              value={urgeForm.actionTaken}
              onChange={e => setUrgeForm(p => ({ ...p, actionTaken: e.target.value }))}
            />
            <div className="flex gap-2">
              {(['resisted', 'delayed', 'relapsed'] as const).map(o => (
                <button
                  key={o}
                  onClick={() => setUrgeForm(p => ({ ...p, outcome: o }))}
                  className="flex-1 py-1.5 rounded text-xs font-medium capitalize"
                  style={{
                    backgroundColor: urgeForm.outcome === o ? '#6366f1' : '#12121a',
                    color: urgeForm.outcome === o ? 'white' : '#64748b',
                  }}
                >
                  {o}
                </button>
              ))}
            </div>
            <button onClick={logUrge} className="w-full py-2 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#6366f1', color: 'white' }}>
              Log
            </button>
          </div>
        )}

        {log.urgesLogged.map(u => (
          <div key={u.id} className="flex items-start gap-2 py-2 border-t text-xs" style={{ borderColor: '#1e1e2e' }}>
            <span style={{ color: '#64748b' }}>{u.time}</span>
            <span style={{ color: '#e2e8f0' }}>Intensity {u.intensity} · {u.trigger} → {u.outcome}</span>
          </div>
        ))}
      </div>

      {/* Relapse handling */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-2" style={{ color: '#e2e8f0' }}>Honest Check-In</h3>
        <p className="text-xs mb-3" style={{ color: '#64748b' }}>Logging a setback is not weakness. It's data.</p>
        {log.relapseOccurred ? (
          <div className="p-3 rounded-lg" style={{ backgroundColor: '#1a0a0a' }}>
            <p className="text-sm" style={{ color: '#f87171' }}>Setback logged: {log.relapseType}.</p>
            <p className="text-xs mt-1" style={{ color: '#64748b' }}>Reset the streak tomorrow. Today isn't done.</p>
          </div>
        ) : (
          <button
            onClick={() => setShowRelapseForm(!showRelapseForm)}
            className="text-xs px-3 py-2 rounded-lg"
            style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
          >
            Log a setback
          </button>
        )}
        {showRelapseForm && !log.relapseOccurred && (
          <div className="mt-3 space-y-3">
            <div className="flex gap-2">
              {(['porn', 'masturbation', 'both'] as const).map(t => (
                <button
                  key={t}
                  onClick={() => setRelapseForm(p => ({ ...p, type: t }))}
                  className="flex-1 py-1.5 rounded text-xs font-medium capitalize"
                  style={{
                    backgroundColor: relapseForm.type === t ? '#7f1d1d' : '#1e1e2e',
                    color: relapseForm.type === t ? '#fca5a5' : '#64748b',
                  }}
                >
                  {t}
                </button>
              ))}
            </div>
            <button onClick={logRelapse} className="w-full py-2 rounded-lg text-sm font-medium" style={{ backgroundColor: '#7f1d1d', color: '#fca5a5' }}>
              Log honestly
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
