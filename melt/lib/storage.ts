import { DailyLog, UserSettings, LiftingLog, Streak } from './types';
import { format } from 'date-fns';

const KEYS = {
  DAILY_LOGS: 'melt_daily_logs',
  USER_SETTINGS: 'melt_user_settings',
  LIFTING_LOGS: 'melt_lifting_logs',
  STREAKS: 'melt_streaks',
};

export const defaultSettings: UserSettings = {
  wakeTargetTime: '08:00',
  outOfBedGraceMinutes: 5,
  sleepTargetTime: '23:30',
  calorieMin: 1600,
  calorieMax: 1800,
  proteinTarget: 140,
  waterTargetLiters: 3,
  weeklyLiftTarget: 4,
  weeklyLegSessionsTarget: 2,
  pornAbstinenceGoalEnabled: true,
  masturbationAbstinenceGoalEnabled: true,
  morningSunscreenRequired: true,
  animeAllowedAfterCoreWorkOnly: true,
  bedPhoneRuleEnabled: true,
  ibModuleEnabled: true,
  ibDailyMinutesTarget: 90,
  animeCapMinutes: 90,
  claudeApiKey: '',
};

export function createDefaultLog(date: string): DailyLog {
  return {
    date,
    morningRoutineCompleted: false,
    showerCompleted: false,
    brushedTeethMorning: false,
    sunscreenApplied: false,
    sunscreenReapplied: false,
    nightRoutineCompleted: false,
    cleanserCompleted: false,
    acneTreatmentCompleted: false,
    moisturizerCompleted: false,
    nightCleanser: false,
    pillowcaseChanged: false,
    calories: 0,
    proteinGrams: 0,
    waterLiters: 0,
    meals: [],
    lifted: false,
    movementMinutes: 0,
    ibMinutes: 0,
    ibTasksCompleted: [],
    singingMinutes: 0,
    animeMinutes: 0,
    funActivityCompleted: false,
    pornAvoided: true,
    masturbationAvoided: true,
    phoneInBedAvoided: true,
    bedRottingAvoided: true,
    urgesLogged: [],
    relapseOccurred: false,
    dayStatus: 'in-progress',
    salvageModeActivated: false,
    salvageCompleted: false,
    nutritionScreenshotAnalyzed: false,
  };
}

export function getTodayDate(): string {
  return format(new Date(), 'yyyy-MM-dd');
}

// Settings
export function getSettings(): UserSettings {
  if (typeof window === 'undefined') return defaultSettings;
  try {
    const raw = localStorage.getItem(KEYS.USER_SETTINGS);
    if (!raw) return defaultSettings;
    return { ...defaultSettings, ...JSON.parse(raw) };
  } catch {
    return defaultSettings;
  }
}

export function saveSettings(settings: UserSettings): void {
  localStorage.setItem(KEYS.USER_SETTINGS, JSON.stringify(settings));
}

// Daily Logs
export function getAllLogs(): Record<string, DailyLog> {
  if (typeof window === 'undefined') return {};
  try {
    const raw = localStorage.getItem(KEYS.DAILY_LOGS);
    if (!raw) return {};
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

export function getLog(date: string): DailyLog {
  const logs = getAllLogs();
  return logs[date] || createDefaultLog(date);
}

export function saveLog(log: DailyLog): void {
  const logs = getAllLogs();
  logs[log.date] = log;
  localStorage.setItem(KEYS.DAILY_LOGS, JSON.stringify(logs));
}

export function getTodayLog(): DailyLog {
  return getLog(getTodayDate());
}

// Lifting Logs
export function getAllLiftingLogs(): LiftingLog[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = localStorage.getItem(KEYS.LIFTING_LOGS);
    if (!raw) return [];
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

export function saveLiftingLog(log: LiftingLog): void {
  const logs = getAllLiftingLogs();
  const idx = logs.findIndex(l => l.date === log.date);
  if (idx >= 0) logs[idx] = log;
  else logs.push(log);
  localStorage.setItem(KEYS.LIFTING_LOGS, JSON.stringify(logs));
}

// Streaks
export function getStreaks(): Streak {
  if (typeof window === 'undefined') return { pornFree: 0, masturbationFree: 0, phoneOutOfBed: 0, morningLaunch: 0, skincare: 0, wakeOnTime: 0 };
  try {
    const raw = localStorage.getItem(KEYS.STREAKS);
    if (!raw) return { pornFree: 0, masturbationFree: 0, phoneOutOfBed: 0, morningLaunch: 0, skincare: 0, wakeOnTime: 0 };
    return JSON.parse(raw);
  } catch {
    return { pornFree: 0, masturbationFree: 0, phoneOutOfBed: 0, morningLaunch: 0, skincare: 0, wakeOnTime: 0 };
  }
}

export function saveStreaks(streaks: Streak): void {
  localStorage.setItem(KEYS.STREAKS, JSON.stringify(streaks));
}

export function recalculateStreaks(): Streak {
  const logs = getAllLogs();
  const dates = Object.keys(logs).sort().reverse();

  const streaks: Streak = { pornFree: 0, masturbationFree: 0, phoneOutOfBed: 0, morningLaunch: 0, skincare: 0, wakeOnTime: 0 };

  for (const date of dates) {
    const log = logs[date];
    if (log.pornAvoided) streaks.pornFree++; else break;
  }

  let mFree = true;
  for (const date of dates) {
    const log = logs[date];
    if (mFree && log.masturbationAvoided) streaks.masturbationFree++; else { mFree = false; }
    if (mFree === false) break;
  }

  for (const date of dates) {
    const log = logs[date];
    if (log.phoneInBedAvoided) streaks.phoneOutOfBed++; else break;
  }

  for (const date of dates) {
    const log = logs[date];
    if (log.morningRoutineCompleted) streaks.morningLaunch++; else break;
  }

  for (const date of dates) {
    const log = logs[date];
    if (log.nightRoutineCompleted) streaks.skincare++; else break;
  }

  return streaks;
}

export function clearAllData(): void {
  Object.values(KEYS).forEach(key => localStorage.removeItem(key));
}

export function exportAllData(): string {
  const data = {
    settings: getSettings(),
    logs: getAllLogs(),
    liftingLogs: getAllLiftingLogs(),
    streaks: getStreaks(),
    exportedAt: new Date().toISOString(),
  };
  return JSON.stringify(data, null, 2);
}
