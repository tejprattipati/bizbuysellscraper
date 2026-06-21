'use client';

import { useState, useEffect } from 'react';
import { Settings, Download, Trash2 } from 'lucide-react';
import { getSettings, saveSettings, exportAllData, clearAllData } from '@/lib/storage';
import { UserSettings } from '@/lib/types';

export default function SettingsPage() {
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [mounted, setMounted] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    setMounted(true);
    setSettings(getSettings());
  }, []);

  if (!mounted || !settings) return <div className="text-slate-500 p-8">Loading...</div>;

  const update = (updates: Partial<UserSettings>) => {
    const updated = { ...settings, ...updates };
    setSettings(updated);
    saveSettings(updated);
    setSaved(true);
    setTimeout(() => setSaved(false), 1500);
  };

  const handleExport = () => {
    const data = exportAllData();
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `melt-data-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleClear = () => {
    if (confirm('Clear ALL Melt data? This cannot be undone.')) {
      clearAllData();
      setSettings(getSettings());
    }
  };

  const inputClass = "w-full px-3 py-2 rounded-lg text-sm border";
  const inputStyle = { backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
            <Settings size={24} style={{ color: '#94a3b8' }} />
          </div>
          <div>
            <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Settings</h1>
            <p className="text-sm" style={{ color: '#64748b' }}>Your targets, your rules.</p>
          </div>
        </div>
        {saved && <span className="text-xs px-2 py-1 rounded" style={{ backgroundColor: '#166534', color: '#4ade80' }}>Saved ✓</span>}
      </div>

      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#6366f1' }}>
        <h3 className="font-semibold" style={{ color: '#a5b4fc' }}>🤖 Claude API Key</h3>
        <p className="text-xs" style={{ color: '#64748b' }}>Required for MyFitnessPal screenshot analysis. Get yours at console.anthropic.com</p>
        <input type="password" className={inputClass} style={inputStyle}
          placeholder="sk-ant-..."
          value={settings.claudeApiKey}
          onChange={e => update({ claudeApiKey: e.target.value })} />
      </div>

      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Sleep</h3>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Wake Target</label>
            <input type="time" className={inputClass} style={inputStyle} value={settings.wakeTargetTime} onChange={e => update({ wakeTargetTime: e.target.value })} />
          </div>
          <div>
            <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>Sleep Target</label>
            <input type="time" className={inputClass} style={inputStyle} value={settings.sleepTargetTime} onChange={e => update({ sleepTargetTime: e.target.value })} />
          </div>
        </div>
      </div>

      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Nutrition</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: 'Calorie Min', key: 'calorieMin' as keyof UserSettings, type: 'number' },
            { label: 'Calorie Max', key: 'calorieMax' as keyof UserSettings, type: 'number' },
            { label: 'Protein Target (g)', key: 'proteinTarget' as keyof UserSettings, type: 'number' },
            { label: 'Water Target (L)', key: 'waterTargetLiters' as keyof UserSettings, type: 'number' },
          ].map(({ label, key, type }) => (
            <div key={key}>
              <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>{label}</label>
              <input type={type} className={inputClass} style={inputStyle}
                value={settings[key] as number}
                onChange={e => update({ [key]: parseFloat(e.target.value) || 0 } as Partial<UserSettings>)} />
            </div>
          ))}
        </div>
      </div>

      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>IB & Training</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: 'IB Daily Minutes', key: 'ibDailyMinutesTarget' as keyof UserSettings },
            { label: 'Anime Cap (min)', key: 'animeCapMinutes' as keyof UserSettings },
            { label: 'Weekly Lift Target', key: 'weeklyLiftTarget' as keyof UserSettings },
            { label: 'Weekly Leg Sessions', key: 'weeklyLegSessionsTarget' as keyof UserSettings },
          ].map(({ label, key }) => (
            <div key={key}>
              <label className="text-xs mb-1 block" style={{ color: '#64748b' }}>{label}</label>
              <input type="number" className={inputClass} style={inputStyle}
                value={settings[key] as number}
                onChange={e => update({ [key]: parseInt(e.target.value) || 0 } as Partial<UserSettings>)} />
            </div>
          ))}
        </div>
      </div>

      <div className="rounded-xl border p-4 space-y-2" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold mb-1" style={{ color: '#e2e8f0' }}>Feature Toggles</h3>
        {[
          { key: 'pornAbstinenceGoalEnabled' as keyof UserSettings, label: 'Porn abstinence tracking' },
          { key: 'masturbationAbstinenceGoalEnabled' as keyof UserSettings, label: 'Masturbation abstinence tracking' },
          { key: 'morningSunscreenRequired' as keyof UserSettings, label: 'Morning sunscreen required' },
          { key: 'bedPhoneRuleEnabled' as keyof UserSettings, label: 'Bed phone rule' },
          { key: 'animeAllowedAfterCoreWorkOnly' as keyof UserSettings, label: 'Anime only after core work' },
          { key: 'ibModuleEnabled' as keyof UserSettings, label: 'IB Module enabled' },
        ].map(({ key, label }) => {
          const val = settings[key] as boolean;
          return (
            <div key={key} className="flex items-center justify-between py-2">
              <span className="text-sm" style={{ color: '#94a3b8' }}>{label}</span>
              <button onClick={() => update({ [key]: !val } as Partial<UserSettings>)}
                className="px-3 py-1.5 rounded-lg text-sm"
                style={{ backgroundColor: val ? '#166534' : '#1e1e2e', color: val ? '#4ade80' : '#64748b' }}>
                {val ? 'On' : 'Off'}
              </button>
            </div>
          );
        })}
      </div>

      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Data</h3>
        <button onClick={handleExport}
          className="w-full flex items-center justify-center gap-2 py-3 rounded-lg text-sm font-medium"
          style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>
          <Download size={16} /> Export All Data (JSON)
        </button>
        <button onClick={handleClear}
          className="w-full flex items-center justify-center gap-2 py-3 rounded-lg text-sm font-medium"
          style={{ backgroundColor: '#1a0a0a', color: '#f87171' }}>
          <Trash2 size={16} /> Clear All Data
        </button>
      </div>
    </div>
  );
}
