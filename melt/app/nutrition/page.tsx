'use client';

import { useState, useEffect, useRef } from 'react';
import { Apple, Plus, X, Upload, Loader2 } from 'lucide-react';
import { getTodayLog, saveLog, getSettings } from '@/lib/storage';
import { DailyLog, UserSettings, Meal } from '@/lib/types';
import { ProgressBar } from '@/components/ProgressBar';
import { getProteinStatus, getSuggestedFood, getCalorieStatus, isBuldakMeal } from '@/lib/nutrition';
import Anthropic from '@anthropic-ai/sdk';

function generateId() {
  return Math.random().toString(36).substr(2, 9);
}

export default function NutritionPage() {
  const [log, setLog] = useState<DailyLog | null>(null);
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [mounted, setMounted] = useState(false);
  const [showAddMeal, setShowAddMeal] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState('');
  const [showBuldakWarning, setShowBuldakWarning] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [newMeal, setNewMeal] = useState({
    mealName: '', time: '', calories: '', protein: '', carbs: '', fat: '',
    mealQuality: 'good' as Meal['mealQuality'], notes: '', wasPlanned: false,
  });

  useEffect(() => {
    setMounted(true);
    setLog(getTodayLog());
    setSettings(getSettings());
  }, []);

  if (!mounted || !log || !settings) return <div className="text-slate-500 p-8">Loading...</div>;

  const hour = new Date().getHours();
  const proteinStatus = getProteinStatus(log.proteinGrams, settings.proteinTarget, hour);
  const suggestedFood = getSuggestedFood(log.calories, log.proteinGrams, settings.calorieMax, settings.proteinTarget);
  const calStatus = getCalorieStatus(log.calories, settings.calorieMin, settings.calorieMax);

  const updateLog = (updates: Partial<DailyLog>) => {
    const updated = { ...log, ...updates };
    setLog(updated);
    saveLog(updated);
  };

  const addMeal = () => {
    if (!newMeal.mealName || !newMeal.calories) return;
    const cal = parseInt(newMeal.calories) || 0;
    const prot = parseInt(newMeal.protein) || 0;
    const buldak = isBuldakMeal(newMeal.mealName);

    const meal: Meal = {
      id: generateId(),
      mealName: newMeal.mealName,
      time: newMeal.time || `${hour}:00`,
      calories: cal,
      protein: prot,
      carbs: parseInt(newMeal.carbs) || 0,
      fat: parseInt(newMeal.fat) || 0,
      mealQuality: newMeal.mealQuality,
      isHighProtein: prot >= 30,
      isBuldakMeal: buldak,
      wasPlanned: newMeal.wasPlanned,
      notes: newMeal.notes,
    };

    const newMeals = [...log.meals, meal];
    const totalCal = newMeals.reduce((s, m) => s + m.calories, 0);
    const totalProt = newMeals.reduce((s, m) => s + m.protein, 0);

    updateLog({ meals: newMeals, calories: totalCal, proteinGrams: totalProt });
    setNewMeal({ mealName: '', time: '', calories: '', protein: '', carbs: '', fat: '', mealQuality: 'good', notes: '', wasPlanned: false });
    setShowAddMeal(false);
    if (buldak) setShowBuldakWarning(true);
  };

  const removeMeal = (id: string) => {
    const newMeals = log.meals.filter(m => m.id !== id);
    const totalCal = newMeals.reduce((s, m) => s + m.calories, 0);
    const totalProt = newMeals.reduce((s, m) => s + m.protein, 0);
    updateLog({ meals: newMeals, calories: totalCal, proteinGrams: totalProt });
  };

  const handleScreenshot = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !settings.claudeApiKey) {
      if (!settings.claudeApiKey) setAnalysisResult('No Claude API key set. Go to Settings to add one.');
      return;
    }

    setAnalyzing(true);
    setAnalysisResult('');

    try {
      const reader = new FileReader();
      reader.onload = async (ev) => {
        const base64 = (ev.target?.result as string).split(',')[1];
        const mediaType = file.type as 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp';

        const client = new Anthropic({ apiKey: settings.claudeApiKey, dangerouslyAllowBrowser: true });
        const response = await client.messages.create({
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 1024,
          messages: [{
            role: 'user',
            content: [
              {
                type: 'image',
                source: { type: 'base64', media_type: mediaType, data: base64 },
              },
              {
                type: 'text',
                text: 'Analyze this MyFitnessPal nutrition diary screenshot. Extract: total calories, total protein (g), total carbs (g), total fat (g), water (if shown), and list individual meals/foods with their calories and protein. Return ONLY valid JSON in this format: {"totalCalories": 0, "totalProtein": 0, "totalCarbs": 0, "totalFat": 0, "meals": [{"name": "", "calories": 0, "protein": 0}]}',
              },
            ],
          }],
        });

        const text = response.content[0].type === 'text' ? response.content[0].text : '';
        setAnalysisResult(text);

        try {
          const jsonMatch = text.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const data = JSON.parse(jsonMatch[0]);
            if (data.totalCalories || data.totalProtein) {
              updateLog({
                calories: data.totalCalories || log.calories,
                proteinGrams: data.totalProtein || log.proteinGrams,
                nutritionScreenshotAnalyzed: true,
                nutritionScreenshotNotes: text,
              });
            }
          }
        } catch {
          // JSON parse failed, show raw result
        }

        setAnalyzing(false);
      };
      reader.readAsDataURL(file);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      setAnalysisResult(`Error: ${message}`);
      setAnalyzing(false);
    }
  };

  const qualityColors: Record<Meal['mealQuality'], string> = {
    excellent: '#22c55e', good: '#6366f1', okay: '#f59e0b', bad: '#ef4444',
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg" style={{ backgroundColor: '#1e1e2e' }}>
          <Apple size={24} style={{ color: '#22c55e' }} />
        </div>
        <div>
          <h1 className="text-xl font-bold" style={{ color: '#e2e8f0' }}>Nutrition</h1>
          <p className="text-sm" style={{ color: '#64748b' }}>{proteinStatus.message}</p>
        </div>
      </div>

      {/* Summary bars */}
      <div className="rounded-xl border p-4 space-y-4" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <div className="grid grid-cols-3 gap-4 text-center mb-2">
          <div>
            <div className="text-2xl font-bold" style={{ color: calStatus.color }}>{log.calories}</div>
            <div className="text-xs" style={{ color: '#64748b' }}>calories</div>
          </div>
          <div>
            <div className="text-2xl font-bold" style={{ color: log.proteinGrams >= settings.proteinTarget ? '#22c55e' : '#e2e8f0' }}>{log.proteinGrams}g</div>
            <div className="text-xs" style={{ color: '#64748b' }}>protein</div>
          </div>
          <div>
            <div className="text-2xl font-bold" style={{ color: log.waterLiters >= settings.waterTargetLiters ? '#22c55e' : '#e2e8f0' }}>{log.waterLiters.toFixed(1)}L</div>
            <div className="text-xs" style={{ color: '#64748b' }}>water</div>
          </div>
        </div>
        <ProgressBar label="Protein" value={log.proteinGrams} max={settings.proteinTarget} />
        <ProgressBar label={`Calories (${settings.calorieMin}-${settings.calorieMax})`} value={log.calories} max={settings.calorieMax} />
        <ProgressBar label="Water" value={parseFloat(log.waterLiters.toFixed(2))} max={settings.waterTargetLiters} colorClass="bg-blue-500" />
      </div>

      {/* Suggestion */}
      <div className="rounded-xl border px-4 py-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <p className="text-sm font-medium" style={{ color: '#a5b4fc' }}>💡 {suggestedFood}</p>
      </div>

      {/* Water quick add */}
      <div className="flex gap-2 flex-wrap">
        {[0.25, 0.5, 1].map(amt => (
          <button
            key={amt}
            onClick={() => updateLog({ waterLiters: +(log.waterLiters + amt).toFixed(2) })}
            className="px-3 py-2 rounded-lg text-sm font-medium"
            style={{ backgroundColor: '#1e3a5f', color: '#60a5fa' }}
          >
            +{amt}L water
          </button>
        ))}
      </div>

      {/* Meal list */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Meals ({log.meals.length})</h3>
          <button
            onClick={() => setShowAddMeal(!showAddMeal)}
            className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-sm font-medium"
            style={{ backgroundColor: '#6366f1', color: 'white' }}
          >
            <Plus size={14} />
            Add Meal
          </button>
        </div>

        {log.meals.map(meal => (
          <div key={meal.id} className="rounded-xl border p-3 flex items-start gap-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium" style={{ color: '#e2e8f0' }}>{meal.mealName}</span>
                <span className="text-xs px-1.5 py-0.5 rounded" style={{ backgroundColor: `${qualityColors[meal.mealQuality]}22`, color: qualityColors[meal.mealQuality] }}>
                  {meal.mealQuality}
                </span>
                {meal.isBuldakMeal && <span className="text-xs">🌶️ Buldak</span>}
              </div>
              <div className="text-xs mt-1" style={{ color: '#64748b' }}>
                {meal.calories} cal · {meal.protein}g protein
                {meal.time && ` · ${meal.time}`}
              </div>
            </div>
            <button onClick={() => removeMeal(meal.id)} style={{ color: '#64748b' }}>
              <X size={14} />
            </button>
          </div>
        ))}
      </div>

      {/* Add meal form */}
      {showAddMeal && (
        <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#6366f1' }}>
          <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>Add Meal</h3>
          <div className="grid grid-cols-2 gap-3">
            <input
              className="col-span-2 px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Meal name"
              value={newMeal.mealName}
              onChange={e => setNewMeal(p => ({ ...p, mealName: e.target.value }))}
            />
            <input
              type="number"
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Calories"
              value={newMeal.calories}
              onChange={e => setNewMeal(p => ({ ...p, calories: e.target.value }))}
            />
            <input
              type="number"
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Protein (g)"
              value={newMeal.protein}
              onChange={e => setNewMeal(p => ({ ...p, protein: e.target.value }))}
            />
            <input
              type="number"
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Carbs (g)"
              value={newMeal.carbs}
              onChange={e => setNewMeal(p => ({ ...p, carbs: e.target.value }))}
            />
            <input
              type="number"
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              placeholder="Fat (g)"
              value={newMeal.fat}
              onChange={e => setNewMeal(p => ({ ...p, fat: e.target.value }))}
            />
            <input
              type="time"
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              value={newMeal.time}
              onChange={e => setNewMeal(p => ({ ...p, time: e.target.value }))}
            />
            <select
              className="px-3 py-2 rounded-lg text-sm border"
              style={{ backgroundColor: '#1e1e2e', borderColor: '#2d2d3d', color: '#e2e8f0' }}
              value={newMeal.mealQuality}
              onChange={e => setNewMeal(p => ({ ...p, mealQuality: e.target.value as Meal['mealQuality'] }))}
            >
              <option value="excellent">Excellent</option>
              <option value="good">Good</option>
              <option value="okay">Okay</option>
              <option value="bad">Bad</option>
            </select>
          </div>
          <div className="flex gap-2">
            <button onClick={addMeal} className="flex-1 py-2 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#6366f1', color: 'white' }}>
              Add
            </button>
            <button onClick={() => setShowAddMeal(false)} className="px-4 py-2 rounded-lg text-sm" style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Screenshot analyzer */}
      <div className="rounded-xl border p-4 space-y-3" style={{ backgroundColor: '#12121a', borderColor: '#1e1e2e' }}>
        <h3 className="font-semibold" style={{ color: '#e2e8f0' }}>📸 Analyze MyFitnessPal Screenshot</h3>
        <p className="text-xs" style={{ color: '#64748b' }}>
          Upload a screenshot of your MFP diary and Claude will extract your nutrition data automatically.
          {!settings.claudeApiKey && ' Add your Claude API key in Settings first.'}
        </p>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={handleScreenshot}
        />
        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={analyzing || !settings.claudeApiKey}
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50 transition-all"
          style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}
        >
          {analyzing ? <Loader2 size={16} className="animate-spin" /> : <Upload size={16} />}
          {analyzing ? 'Analyzing...' : 'Upload Screenshot'}
        </button>

        {analysisResult && (
          <div className="rounded-lg p-3 text-xs" style={{ backgroundColor: '#1e1e2e', color: '#94a3b8' }}>
            <pre className="whitespace-pre-wrap break-all">{analysisResult}</pre>
          </div>
        )}

        {log.nutritionScreenshotAnalyzed && (
          <div className="flex items-center gap-2 text-xs" style={{ color: '#22c55e' }}>
            ✓ Nutrition imported from screenshot
          </div>
        )}
      </div>

      {/* Buldak warning modal */}
      {showBuldakWarning && (
        <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ backgroundColor: 'rgba(0,0,0,0.8)' }}>
          <div className="rounded-2xl p-6 max-w-sm w-full mx-4" style={{ backgroundColor: '#12121a', border: '1px solid #f59e0b' }}>
            <div className="text-4xl text-center mb-3">🌶️</div>
            <h3 className="text-xl font-bold text-center mb-2" style={{ color: '#f59e0b' }}>Buldak Detected</h3>
            <p className="text-sm text-center mb-4" style={{ color: '#94a3b8' }}>
              Buldak/ramen flagged. Sodium and calories high. Make sure protein still hits target.
            </p>
            <button
              onClick={() => setShowBuldakWarning(false)}
              className="w-full py-3 rounded-lg font-bold"
              style={{ backgroundColor: '#f59e0b', color: '#0a0a0f' }}
            >
              Got it
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
