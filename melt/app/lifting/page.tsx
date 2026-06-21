'use client';

import { useState, useEffect } from 'react';
import { Dumbbell, Plus, X } from 'lucide-react';
import { getTodayLog, saveLog, saveLiftingLog, getAllLiftingLogs } from '@/lib/storage';
import { DailyLog, LiftingLog, Exercise } from '@/lib/types';
import { format } from 'date-fns';

const SESSION_TYPES = ['upper', 'lower', 'full', 'core', 'rest'] as const;

export default function LiftingPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [lifting, setLifting] = useState<LiftingLog | null>(null);
  const [mounted, setMounted] = useState(false);
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [newEx, setNewEx] = useState({ name: '', sets: '3', reps: '10', weight: '', rpe: '', notes: '' });

  useEffect(() => {
    setMounted(true);
    const l = getTodayLog();
    setLog(l);
    const today = format(new Date(), 'yyyy-MM-dd');
    const liftLogs = getAllLiftingLogs();
    const existing = liftLogs.find(ll => ll.date === today);
    if (existing) {
      setLifting(existing);
      setExercises(existing.exercises);
    } else {
      setLifting({
        date: today,
        sessionType: 'upper',
        exercises: [],
        durationMinutes: 60,
        intensity: 7,
        crampsOccurred: false,
      });
    }
  }, []);

  if (!mounted || !log || !lifting) return <div className="text-slate-500 p-8">Loading...</div>;

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const updateLifting = (updates: Partial<LiftingLog>) => {
    const updated = { ...lifting, ...updates };
    setLifting(updated);
    saveLiftingLog(updated);
  };

  const addExercise = () => {
    if (!newEx.name) return;
    const ex: Exercise = {
      name: newEx.name,
      sets: parseInt(newEx.sets) || 3,
      reps: newEx.reps,
      weight: newEx.weight,
      rpe: newEx.rpe ? parseInt(newEx.rpe) : undefined,
      notes: newEx.notes || undefined,
    };
    const updated = [...exercises, ex];
    setExercises(updated);
    updateLifting({ exercises: updated });
    setNewEx({ name: '', sets: '3', reps: '10', weight: '', rpe: '', notes: '' });
  };

  const removeExercise = (idx: number) => {
    const updated = exercises.filter((_, i) => i !== idx);
    setExercises(updated);
    updateLifting({ exercises: updated });
  };

  const markSessionComplete = () => {
    updateLog({ lifted: true, liftType: lifting.sessionType as DailyLog['liftType'] });
    updateLifting({ exercises });
  };

  const isLegDay = lifting.sessionType === 'lower' || lifting.sessionType === 'full';

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Dumbbell size={24} style={{ color: '#6366f1' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Training</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>{log.lifted ? '✓ Session logged' : 'Log today\'s workout'}</p>
        </div>
      </div>

      {/* Session type */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Session Type</h3>
        <div className="flex flex-wrap gap-2">
          {SESSION_TYPES.map(type => (
            <button
              key={type}
              onClick={() => updateLifting({ sessionType: type })}
              className="px-3 py-1.5 rounded-lg text-sm font-medium capitalize"
              style={{
                backgroundColor: lifting.sessionType === type ? '#6366f1' : '#1e1e2e',
                color: lifting.sessionType === type ? 'white' : '#64748b',
              }}
            >
              {type}
            </button>
          ))}
        </div>
      </div>

      {/* Anti-cramp checklist for leg day */}
      {isLegDay && (
        <div className="rounded-xl border p-4" style={{ backgroundColor: '#1a1200', borderColor: '#92400e' }}>
          <h3 className="font-semibold mb-3" style={{ color: '#f59e0b' }}>⚡ Anti-Cramp Checklist (Leg Day)</h3>
          <div className="space-y-2 text-sm" style={{ color: '#d97706' }}>
            <div>✓ Hydrate 1L+ before session</div>
            <div>✓ Banana or electrolytes pre-workout</div>
            <div>✓ Warm up calves and hamstrings</div>
            <div>✓ Avoid max effort on cramping muscles</div>
          </div>
          <div className="mt-3">
            <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Cramp severity today</label>
            <div className="flex gap-2">
              {(['none', 'mild', 'moderate', 'severe'] as const).map(sev => (
                <button
                  key={sev}
                  onClick={() => updateLifting({ crampSeverity: sev, crampsOccurred: sev !== 'none' })}
                  className="flex-1 py-1.5 rounded text-xs font-medium capitalize"
                  style={{
                    backgroundColor: lifting.crampSeverity === sev ? '#f59e0b' : '#1e1e2e',
                    color: lifting.crampSeverity === sev ? '#0a0a0f' : '#64748b',
                  }}
                >
                  {sev}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Duration & intensity */}
      <div className="rounded-xl border p-4 grid grid-cols-2 gap-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <div>
          <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Duration (min)</label>
          <input
            type="number"
            value={lifting.durationMinutes}
            onChange={e => updateLifting({ durationMinutes: parseInt(e.target.value) || 0 })}
            className="w-full px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
          />
        </div>
        <div>
          <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Intensity (1-10)</label>
          <input
            type="number"
            min="1" max="10"
            value={lifting.intensity}
            onChange={e => updateLifting({ intensity: parseInt(e.target.value) || 7 })}
            className="w-full px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
          />
        </div>
      </div>

      {/* Exercises */}
      <div className="space-y-2">
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Exercises ({exercises.length})</h3>
        {exercises.map((ex, i) => (
          <div key={i} className="rounded-xl border p-3 flex items-start gap-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
            <div className="flex-1">
              <p className="text-sm font-medium" style={{ color: '#e2e8f0' }}>{ex.name}</p>
              <p className="text-xs" style={{ color: '#64748b' }}>
                {ex.sets} sets × {ex.reps} reps {ex.weight && `@ ${ex.weight}`} {ex.rpe && `· RPE ${ex.rpe}`}
              </p>
            </div>
            <button onClick={() => removeExercise(i)} style={{ color: '#64748b' }}><X size={14} /></button>
          </div>
        ))}

        {/* Add exercise */}
        <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
          <h4 className="text-sm font-semibold" style={{ color: '#e2e8f0' }}>Add Exercise</h4>
          <input
            className="w-full px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            placeholder="Exercise name"
            value={newEx.name}
            onChange={e => setNewEx(p => ({ ...p, name: e.target.value }))}
          />
          <div className="grid grid-cols-3 gap-2">
            <input
              type="number"
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Sets"
              value={newEx.sets}
              onChange={e => setNewEx(p => ({ ...p, sets: e.target.value }))}
            />
            <input
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Reps"
              value={newEx.reps}
              onChange={e => setNewEx(p => ({ ...p, reps: e.target.value }))}
            />
            <input
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Weight"
              value={newEx.weight}
              onChange={e => setNewEx(p => ({ ...p, weight: e.target.value }))}
            />
          </div>
          <button
            onClick={addExercise}
            className="flex items-center gap-1 px-4 py-2 rounded-lg text-sm font-medium"
            style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
          >
            <Plus size={14} /> Add
          </button>
        </div>
      </div>

      {/* Complete session */}
      <button
        onClick={markSessionComplete}
        className="w-full py-4 rounded-xl font-bold text-lg transition-all"
        style={{
          backgroundColor: log.lifted ? '#166534' : '#6366f1',
          color: 'white',
        }}
      >
        {log.lifted ? '✓ Session Logged' : 'Mark Session Complete'}
      </button>
    </div>
  );
}
