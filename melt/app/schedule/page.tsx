'use client';

import { useState } from 'react';

interface TimeBlock {
  time: string;
  label: string;
  category: 'morning' | 'study' | 'training' | 'nutrition' | 'evening' | 'sleep';
  done: boolean;
}

const DEFAULT_SCHEDULE: TimeBlock[] = [
  { time: '07:30', label: 'Wake up + out of bed', category: 'morning', done: false },
  { time: '07:45', label: 'Morning hygiene (teeth, wash face, SPF)', category: 'morning', done: false },
  { time: '08:00', label: 'Breakfast + protein shake', category: 'nutrition', done: false },
  { time: '08:30', label: 'IB Prep Block 1 (60 min)', category: 'study', done: false },
  { time: '09:30', label: 'IB Prep Block 2 (30 min)', category: 'study', done: false },
  { time: '10:00', label: 'Break / movement', category: 'training', done: false },
  { time: '10:30', label: 'Gym / Training session', category: 'training', done: false },
  { time: '12:00', label: 'Post-workout meal (high protein)', category: 'nutrition', done: false },
  { time: '13:00', label: 'IB Prep Block 3 (30 min)', category: 'study', done: false },
  { time: '13:30', label: 'Free time / fun activity', category: 'evening', done: false },
  { time: '15:30', label: 'Sunscreen reapply', category: 'morning', done: false },
  { time: '16:00', label: 'IB Prep Block 4 (30 min) or review', category: 'study', done: false },
  { time: '17:30', label: 'Dinner (protein first)', category: 'nutrition', done: false },
  { time: '19:00', label: 'Leisure / social / singing', category: 'evening', done: false },
  { time: '21:30', label: 'Night routine (skincare, teeth)', category: 'sleep', done: false },
  { time: '22:30', label: 'Wind down — no phone in bed', category: 'sleep', done: false },
  { time: '23:30', label: 'Lights out', category: 'sleep', done: false },
];

const CAT_COLORS: Record<TimeBlock['category'], { bg: string; text: string; border: string }> = {
  morning: { bg: '#1a1200', text: '#fbbf24', border: '#92400e' },
  study: { bg: '#0a1628', text: '#60a5fa', border: '#1e3a5f' },
  training: { bg: '#0f1a0f', text: '#4ade80', border: '#166534' },
  nutrition: { bg: '#1a0f1a', text: '#c084fc', border: '#6b21a8' },
  evening: { bg: '#12121a', text: '#94a3b8', border: '#1e1e2e' },
  sleep: { bg: '#0f0f1a', text: '#818cf8', border: '#1e1b4b' },
};

export default function SchedulePage() {
  const [blocks, setBlocks] = useState(DEFAULT_SCHEDULE);
  const toggle = (i: number) => setBlocks(prev => prev.map((b, idx) => idx === i ? { ...b, done: !b.done } : b));
  const doneCount = blocks.filter(b => b.done).length;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>📅 Daily Schedule</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>Default summer timeline</p>
        </div>
        <div className="text-right">
          <div className="text-2xl font-bold" style={{ color: '#6366f1' }}>{doneCount}/{blocks.length}</div>
          <div className="text-xs" style={{ color: '#64748b' }}>blocks done</div>
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
        {(Object.keys(CAT_COLORS) as TimeBlock['category'][]).map(cat => (
          <div key={cat} className="flex items-center gap-1 text-xs px-2 py-1 rounded-full"
            style={{ backgroundColor: CAT_COLORS[cat].bg, color: CAT_COLORS[cat].text, border: `1px solid ${CAT_COLORS[cat].border}` }}>
            {cat}
          </div>
        ))}
      </div>
      <div className="space-y-2">
        {blocks.map((block, i) => {
          const colors = CAT_COLORS[block.category];
          return (
            <button key={i} onClick={() => toggle(i)}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-all"
              style={{ backgroundColor: block.done ? '#0f2a0f' : colors.bg, border: `1px solid ${block.done ? '#166534' : colors.border}`, opacity: block.done ? 0.7 : 1 }}>
              <div className={`w-4 h-4 rounded flex-shrink-0 flex items-center justify-center text-xs ${block.done ? 'bg-green-600' : 'bg-slate-700'}`}>
                {block.done ? '✓' : ''}
              </div>
              <span className="text-xs font-mono w-12 flex-shrink-0" style={{ color: '#64748b' }}>{block.time}</span>
              <span className="text-sm font-medium" style={{ color: block.done ? '#4ade80' : colors.text }}>{block.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
