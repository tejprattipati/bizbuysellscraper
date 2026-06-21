'use client';

import { useState, useEffect } from 'react';
import { BookOpen, Plus, X } from 'lucide-react';
import { getTodayLog, saveLog } from '@/lib/storage';
import { DailyLog } from '@/lib/types';
import { ProgressBar } from '@/components/ProgressBar';

const IB_DAILY_TARGET = 90;

export default function IBPrepPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [mounted, setMounted] = useState(false);
  const [newTask, setNewTask] = useState('');
  const [minutesInput, setMinutesInput] = useState('');

  useEffect(() => {
    setMounted(true);
    setLog(getTodayLog());
  }, []);

  if (!mounted || !log) return <div className="text-slate-500 p-8">Loading...</div>;

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const addTask = () => {
    if (!newTask.trim()) return;
    updateLog({ ibTasksCompleted: [...log.ibTasksCompleted, newTask.trim()] });
    setNewTask('');
  };

  const removeTask = (i: number) => {
    updateLog({ ibTasksCompleted: log.ibTasksCompleted.filter((_, idx) => idx !== i) });
  };

  const addMinutes = (mins: number) => {
    updateLog({ ibMinutes: log.ibMinutes + mins });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <BookOpen size={24} style={{ color: '#34d399' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>IB Prep</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Target: {IB_DAILY_TARGET} min/day</p>
        </div>
      </div>

      {/* Placeholder banner */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#6366f1' }}>
        <p className="font-bold text-sm" style={{ color: '#a5b4fc' }}>📅 IB Calendar not loaded.</p>
        <p className="text-xs mt-1" style={{ color: '#64748b' }}>Add topics below to activate full tracking. Coming soon: subject calendar, exam countdown.</p>
      </div>

      {/* Daily minutes */}
      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Study Time Today</h3>
        <div className="flex items-center gap-4 mb-2">
          <span className="text-4xl font-black" style={{ color: log.ibMinutes >= IB_DAILY_TARGET ? '#22c55e' : '#e2e8f0' }}>
            {log.ibMinutes}
          </span>
          <span className="text-lg" style={{ color: '#64748b' }}>/ {IB_DAILY_TARGET} min</span>
        </div>
        <ProgressBar value={log.ibMinutes} max={IB_DAILY_TARGET} showValue={false} />
        <div className="flex gap-2 flex-wrap">
          {[15, 30, 45, 60, 90].map(m => (
            <button
              key={m}
              onClick={() => addMinutes(m)}
              className="px-3 py-1.5 rounded-lg text-sm font-medium"
              style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
            >
              +{m}m
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <input
            type="number"
            placeholder="Custom minutes"
            value={minutesInput}
            onChange={e => setMinutesInput(e.target.value)}
            className="flex-1 px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
          />
          <button
            onClick={() => { addMinutes(parseInt(minutesInput) || 0); setMinutesInput(''); }}
            className="px-4 py-2 rounded-lg text-sm font-medium"
            style={{ backgroundColor: '#6366f1', color: 'white' }}
          >
            Add
          </button>
        </div>
      </div>

      {/* Topic */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Today's Topic / Subject</h3>
        <input
          className="w-full px-3 py-2 rounded-lg text-sm border"
          style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
          placeholder="e.g. Math SL - Integration"
          value={log.ibTopic || ''}
          onChange={e => updateLog({ ibTopic: e.target.value })}
        />
      </div>

      {/* Confidence */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Confidence Level</h3>
        <div className="flex gap-2">
          {[1, 2, 3, 4, 5].map(n => (
            <button
              key={n}
              onClick={() => updateLog({ ibConfidence: n })}
              className="flex-1 py-3 rounded-lg text-sm font-bold"
              style={{
                backgroundColor: log.ibConfidence === n ? '#6366f1' : '#1e1e2e',
                color: log.ibConfidence === n ? 'white' : '#64748b',
              }}
            >
              {n}
            </button>
          ))}
        </div>
        <p className="text-xs mt-2 text-center" style={{ color: '#64748b' }}>1 = lost, 5 = solid</p>
      </div>

      {/* Tasks completed */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-3" style={{ color: '#e2e8f0' }}>Tasks Completed ({log.ibTasksCompleted.length})</h3>
        <div className="flex gap-2 mb-3">
          <input
            className="flex-1 px-3 py-2 rounded-lg text-sm border"
            style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
            placeholder="Add completed task"
            value={newTask}
            onChange={e => setNewTask(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && addTask()}
          />
          <button onClick={addTask} className="px-3 py-2 rounded-lg" style={{ backgroundColor: '#6366f1', color: 'white' }}>
            <Plus size={16} />
          </button>
        </div>
        {log.ibTasksCompleted.map((task, i) => (
          <div key={i} className="flex items-center gap-2 py-2 border-t text-sm" style={{ borderColor: '#1e1e2e', color: '#94a3b8' }}>
            <span className="flex-1">✓ {task}</span>
            <button onClick={() => removeTask(i)} style={{ color: '#475569' }}><X size={14} /></button>
          </div>
        ))}
      </div>

      {/* Notes */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-2" style={{ color: '#e2e8f0' }}>Session Notes</h3>
        <textarea
          className="w-full px-3 py-2 rounded-lg text-sm border resize-none"
          style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
          rows={4}
          placeholder="What did you cover? What's unclear?"
          value={log.ibNotes || ''}
          onChange={e => updateLog({ ibNotes: e.target.value })}
        />
      </div>
    </div>
  );
}
