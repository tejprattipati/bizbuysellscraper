'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { CheckCircle2, Circle } from 'lucide-react';

const STEPS = [
  { id: 'standup', label: 'Stand up. Right now.' },
  { id: 'room', label: 'Leave the room.' },
  { id: 'phone', label: 'Phone face down. Not in hand.' },
  { id: 'water', label: 'Get a glass of water.' },
  { id: 'pushups', label: 'Do 10 pushups.' },
  { id: 'downstairs', label: 'Go somewhere else in the house.' },
];

export default function UrgeModePage() {
  const router = useRouter();
  const [timeLeft, setTimeLeft] = useState(10 * 60);
  const [running, setRunning] = useState(false);
  const [completed, setCompleted] = useState<Set<string>>(new Set());
  const [phase, setPhase] = useState<'pre' | 'timer' | 'outcome'>('pre');
  const [outcome, setOutcome] = useState<'resisted' | 'delayed' | null>(null);

  const tick = useCallback(() => {
    setTimeLeft(t => {
      if (t <= 1) {
        setPhase('outcome');
        setRunning(false);
        return 0;
      }
      return t - 1;
    });
  }, []);

  useEffect(() => {
    if (!running) return;
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [running, tick]);

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;
  const pct = ((10 * 60 - timeLeft) / (10 * 60)) * 100;

  const toggle = (id: string) => {
    setCompleted(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const startTimer = () => {
    setRunning(true);
    setPhase('timer');
  };

  if (phase === 'outcome') {
    return (
      <div className="fixed inset-0 flex flex-col items-center justify-center p-8 text-center"
        style={{ backgroundColor: '#0a0a0f' }}>
        <div className="text-5xl mb-6">⏱️</div>
        <h2 className="text-3xl font-bold mb-2" style={{ color: '#e2e8f0' }}>10 Minutes Done.</h2>
        <p className="text-lg mb-8" style={{ color: '#94a3b8' }}>How did it go?</p>
        <div className="flex gap-4 w-full max-w-sm">
          <button
            onClick={() => router.push('/discipline')}
            className="flex-1 py-4 rounded-2xl font-bold text-lg"
            style={{ backgroundColor: '#166534', color: '#4ade80' }}
          >
            ✓ Resisted
          </button>
          <button
            onClick={() => router.push('/discipline')}
            className="flex-1 py-4 rounded-2xl font-bold text-lg"
            style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
          >
            Log it
          </button>
        </div>
        <button
          onClick={() => router.push('/discipline')}
          className="mt-6 text-sm"
          style={{ color: '#475569' }}
        >
          Back to discipline
        </button>
      </div>
    );
  }

  if (phase === 'pre') {
    return (
      <div className="fixed inset-0 flex flex-col p-8 justify-between"
        style={{ backgroundColor: '#0a0a0f' }}>
        <div className="text-center pt-8">
          <div className="text-6xl mb-6">🛑</div>
          <h1 className="text-4xl font-black mb-3" style={{ color: '#ef4444', letterSpacing: '-1px' }}>LEAVE THE ROOM.</h1>
          <p className="text-xl font-bold mb-2" style={{ color: '#e2e8f0' }}>DO NOT THINK IN BED.</p>
          <p className="text-base" style={{ color: '#64748b' }}>You called this. Now follow through.</p>
        </div>

        <div className="space-y-3">
          {STEPS.map(({ id, label }) => {
            const done = completed.has(id);
            return (
              <button
                key={id}
                onClick={() => toggle(id)}
                className="w-full flex items-center gap-3 p-4 rounded-xl text-left"
                style={{ backgroundColor: done ? '#0f2a0f' : '#12121a' }}
              >
                {done
                  ? <CheckCircle2 size={22} style={{ color: '#22c55e', flexShrink: 0 }} />
                  : <Circle size={22} style={{ color: '#475569', flexShrink: 0 }} />}
                <span className="font-medium" style={{ color: done ? '#4ade80' : '#e2e8f0' }}>{label}</span>
              </button>
            );
          })}
        </div>

        <button
          onClick={startTimer}
          className="w-full py-5 rounded-2xl font-black text-xl mt-4"
          style={{ backgroundColor: '#ef4444', color: 'white' }}
        >
          START 10-MIN TIMER
        </button>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 flex flex-col items-center justify-center p-8 text-center"
      style={{ backgroundColor: '#0a0a0f' }}>
      {/* Ring timer */}
      <div className="relative w-56 h-56 mb-8">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 200 200">
          <circle cx="100" cy="100" r="88" fill="none" stroke="#1e1e2e" strokeWidth="12" />
          <circle
            cx="100" cy="100" r="88"
            fill="none"
            stroke="#ef4444"
            strokeWidth="12"
            strokeDasharray={`${2 * Math.PI * 88}`}
            strokeDashoffset={`${2 * Math.PI * 88 * (1 - pct / 100)}`}
            strokeLinecap="round"
            className="transition-all duration-1000"
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-5xl font-black" style={{ color: '#ef4444' }}>
            {minutes}:{seconds.toString().padStart(2, '0')}
          </span>
          <span className="text-sm mt-1" style={{ color: '#64748b' }}>stay with it</span>
        </div>
      </div>

      <h2 className="text-2xl font-bold mb-2" style={{ color: '#e2e8f0' }}>Hold the line.</h2>
      <p className="text-base mb-6" style={{ color: '#64748b' }}>Don't go back. This feeling passes.</p>

      <div className="w-full max-w-sm space-y-2">
        {STEPS.slice(0, 3).map(({ id, label }) => {
          const done = completed.has(id);
          return (
            <button
              key={id}
              onClick={() => toggle(id)}
              className="w-full flex items-center gap-3 p-3 rounded-xl text-left"
              style={{ backgroundColor: done ? '#0f2a0f' : '#12121a' }}
            >
              {done ? <CheckCircle2 size={18} style={{ color: '#22c55e' }} /> : <Circle size={18} style={{ color: '#475569' }} />}
              <span className="text-sm" style={{ color: done ? '#4ade80' : '#94a3b8' }}>{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
