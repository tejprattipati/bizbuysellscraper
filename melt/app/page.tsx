'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { format } from 'date-fns';
import { Zap, Sun, Apple, Dumbbell, Moon, Shield, Sparkles, BookOpen, ChevronRight, Plus, Droplets } from 'lucide-react';
import { getTodayLog, saveLog, getSettings, getTodayDate } from '@/lib/storage';
import { calculateDayScore, getDayLabel, getDayStatusColor } from '@/lib/scoring';
import { getDashboardMessage } from '@/lib/copy';
import { DailyLog, UserSettings } from '@/lib/types';
import { ProgressBar } from '@/components/ProgressBar';
import { DayScoreBadge } from '@/components/DayScoreBadge';

export default function TodayPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [now, setNow] = useState(new Date());
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    setLog(getTodayLog());
    setSettings(getSettings());
    const timer = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  if (!mounted || !log || !settings) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <div className="text-slate-500">Loading...</div>
      </div>
    );
  }

  const score = calculateDayScore(log, settings);
  const hour = now.getHours();
  const message = getDashboardMessage(score, hour, log);

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const addWater = () => {
    updateLog({ waterLiters: Math.min(log.waterLiters + 0.25, 10) });
  };

  const getMorningStatus = () => {
    if (log.morningRoutineCompleted && log.showerCompleted && log.sunscreenApplied) return 'complete';
    if (log.morningRoutineCompleted || log.showerCompleted) return 'in-progress';
    if (hour > 12) return 'missed';
    return 'in-progress';
  };

  const getNutritionStatus = () => {
    if (log.proteinGrams >= settings.proteinTarget && log.calories >= settings.calorieMin) return 'complete';
    if (log.calories > 0 || log.proteinGrams > 0) return 'in-progress';
    if (hour > 14) return 'behind';
    return 'in-progress';
  };

  const getIBStatus = () => {
    if (log.ibMinutes >= settings.ibDailyMinutesTarget) return 'complete';
    if (log.ibMinutes >= 30) return 'in-progress';
    if (hour > 16) return 'behind';
    return 'in-progress';
  };

  const getLiftStatus = () => {
    if (log.lifted) return 'complete';
    if (hour > 20) return 'missed';
    return 'in-progress';
  };

  const getDisciplineStatus = () => {
    if (!log.pornAvoided || !log.masturbationAvoided) return 'missed';
    return 'complete';
  };

  const getSkincareStatus = () => {
    if (log.nightRoutineCompleted && log.sunscreenApplied) return 'complete';
    if (log.sunscreenApplied) return 'in-progress';
    return 'in-progress';
  };

  const getSleepStatus = () => {
    if (log.sleptAtTime) return 'complete';
    return 'in-progress';
  };

  const statusDot: Record<string, string> = {
    complete: 'bg-green-500',
    'in-progress': 'bg-blue-500',
    behind: 'bg-yellow-500',
    missed: 'bg-red-500',
  };

  const pillars = [
    { key: 'morning', icon: '☀️', label: 'Morning', href: '/morning', status: getMorningStatus(), detail: log.morningRoutineCompleted ? 'Done' : 'Not started' },
    { key: 'nutrition', icon: '🥩', label: 'Nutrition', href: '/nutrition', status: getNutritionStatus(), detail: `${log.proteinGrams}g protein · ${log.calories} cal` },
    { key: 'training', icon: '🏋️', label: 'Training', href: '/lifting', status: getLiftStatus(), detail: log.lifted ? `${log.liftType || 'Done'}` : 'Not logged' },
    { key: 'ib', icon: '📚', label: 'IB Prep', href: '/ib-prep', status: getIBStatus(), detail: `${log.ibMinutes} / ${settings.ibDailyMinutesTarget} min` },
    { key: 'discipline', icon: '🛡️', label: 'Discipline', href: '/discipline', status: getDisciplineStatus(), detail: (!log.pornAvoided || !log.masturbationAvoided) ? 'Relapse logged' : 'Clean day' },
    { key: 'skincare', icon: '✨', label: 'Skincare', href: '/skincare', status: getSkincareStatus(), detail: log.sunscreenApplied ? 'SPF applied' : 'Pending' },
    { key: 'sleep', icon: '🌙', label: 'Sleep', href: '/sleep', status: getSleepStatus(), detail: log.wakeTime ? `Up at ${log.wakeTime}` : 'Not logged' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="relative">
              <span className="text-3xl">🧊</span>
              <div className="absolute inset-0 blur-md rounded-full opacity-60" style={{ background: 'rgba(99,102,241,0.5)' }} />
            </div>
            <div>
              <h1 className="text-2xl font-bold" style={{ color: '#e2e8f0' }}>Melt</h1>
              <p className="text-xs" style={{ color: '#64748b' }}>Melt the summer. Lock in.</p>
            </div>
          </div>
          <p className="text-sm mt-2" style={{ color: '#94a3b8' }}>
            {format(now, 'EEEE, MMMM d')} · {format(now, 'h:mm:ss a')}
          </p>
        </div>
        <DayScoreBadge score={score} size="md" />
      </div>

      {/* Status banner */}
      <div className="rounded-xl px-4 py-3 border" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <p className="text-sm font-medium" style={{ color: '#c4b5fd' }}>{message}</p>
      </div>

      {/* Quick water button */}
      <div className="flex gap-3">
        <button
          onClick={addWater}
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all hover:opacity-80"
          style={{ backgroundColor: '#1e3a5f', color: '#60a5fa' }}
        >
          <Droplets size={16} />
          +250ml water ({log.waterLiters.toFixed(2)}L / {settings.waterTargetLiters}L)
        </button>
        <Link href="/salvage" className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all hover:opacity-80"
          style={{ backgroundColor: '#2d1f00', color: '#f59e0b' }}>
          <Zap size={16} />
          Salvage
        </Link>
      </div>

      {/* Pillar cards grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {pillars.map(({ key, icon, label, href, status, detail }) => (
          <Link key={key} href={href}>
            <div className="rounded-xl border p-4 transition-all hover:border-indigo-500/40 cursor-pointer"
              style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">{icon}</span>
                  <span className="font-semibold text-sm" style={{ color: '#e2e8f0' }}>{label}</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${statusDot[status]}`} />
                  <ChevronRight size={14} style={{ color: '#64748b' }} />
                </div>
              </div>
              <p className="text-xs" style={{ color: '#64748b' }}>{detail}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Nutrition bars */}
      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold text-sm" style={{ color: '#e2e8f0' }}>Nutrition Summary</h3>
        <ProgressBar label="Protein" value={log.proteinGrams} max={settings.proteinTarget} />
        <ProgressBar label="Calories" value={log.calories} max={settings.calorieMax} />
        <ProgressBar label="Water" value={parseFloat(log.waterLiters.toFixed(2))} max={settings.waterTargetLiters} colorClass="bg-blue-500" />
      </div>

      {/* Salvage mode banner if score is low */}
      {score < 70 && (
        <div className="rounded-xl border p-4" style={{ backgroundColor: '#1a1200', borderColor: '#92400e' }}>
          <div className="flex items-center justify-between">
            <div>
              <p className="font-bold text-sm" style={{ color: '#f59e0b' }}>SALVAGE MODE AVAILABLE</p>
              <p className="text-xs mt-1" style={{ color: '#92400e' }}>Score is {score}/100. Hit minimum checklist to save the day.</p>
            </div>
            <Link href="/salvage"
              className="px-4 py-2 rounded-lg text-sm font-bold"
              style={{ backgroundColor: '#f59e0b', color: '#0a0a0f' }}>
              <Zap size={16} className="inline mr-1" />
              GO
            </Link>
          </div>
        </div>
      )}

      {/* Quick toggles */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold text-sm mb-3" style={{ color: '#e2e8f0' }}>Quick Log</h3>
        <div className="grid grid-cols-2 gap-2">
          {[
            { key: 'morningRoutineCompleted', label: '☀️ Morning done' },
            { key: 'showerCompleted', label: '🚿 Showered' },
            { key: 'sunscreenApplied', label: '🧴 Sunscreen' },
            { key: 'lifted', label: '🏋️ Lifted' },
            { key: 'nightRoutineCompleted', label: '🌙 Night routine' },
            { key: 'bedRottingAvoided', label: '🛏️ No bed rotting' },
          ].map(({ key, label }) => {
            const val = log[key as keyof DailyLog] as boolean;
            return (
              <button
                key={key}
                onClick={() => updateLog({ [key]: !val } as Partial<DailyLog>)}
                className="flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium text-left transition-all"
                style={{
                  backgroundColor: val ? '#1a2e1a' : '#1e1e2e',
                  color: val ? '#4ade80' : '#64748b',
                  border: `1px solid ${val ? '#166534' : '#2d2d3d'}`,
                }}
              >
                <div className={`w-3 h-3 rounded flex items-center justify-center text-xs ${val ? 'bg-green-600' : 'bg-slate-700'}`}>
                  {val ? '✓' : ''}
                </div>
                {label}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
