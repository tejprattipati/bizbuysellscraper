import { DailyLog, UserSettings } from './types';

export function calculateDayScore(log: DailyLog, settings: UserSettings): number {
  let score = 0;

  // Morning launch: 15 pts
  if (log.morningRoutineCompleted) score += 8;
  if (log.showerCompleted) score += 4;
  if (log.sunscreenApplied) score += 3;

  // Nutrition: 20 pts
  if (log.proteinGrams >= settings.proteinTarget) score += 12;
  else if (log.proteinGrams >= settings.proteinTarget * 0.85) score += 7;
  if (log.calories >= settings.calorieMin && log.calories <= settings.calorieMax) score += 5;
  else if (log.calories > 0) score += 2;
  if (log.waterLiters >= settings.waterTargetLiters) score += 3;

  // IB/study: 20 pts
  if (log.ibMinutes >= settings.ibDailyMinutesTarget) score += 20;
  else if (log.ibMinutes >= 60) score += 12;
  else if (log.ibMinutes >= 30) score += 6;

  // Lift/movement: 15 pts
  if (log.lifted) score += 12;
  if (log.sportPlayed && log.sportPlayed !== 'none') score += 5;
  else if (log.movementMinutes >= 30) score += 5;

  // Discipline: 15 pts
  if (log.pornAvoided) score += 5;
  if (log.masturbationAvoided) score += 5;
  if (log.phoneInBedAvoided) score += 3;
  if (log.bedRottingAvoided) score += 2;

  // Skincare/hygiene: 10 pts
  if (log.nightRoutineCompleted) score += 6;
  if (log.sunscreenApplied) score += 2;
  if (log.showerCompleted) score += 2;

  // Sleep/shutdown: 5 pts
  if (log.nightRoutineCompleted) score += 5;

  return Math.min(score, 100);
}

export function getDayLabel(score: number): string {
  if (score >= 85) return 'Locked';
  if (score >= 70) return 'Solid';
  if (score >= 50) return 'Salvaged';
  if (score >= 25) return 'Slipping';
  return 'Reset Tomorrow';
}

export function getDayStatusColor(score: number): string {
  if (score >= 85) return 'text-green-400';
  if (score >= 70) return 'text-blue-400';
  if (score >= 50) return 'text-yellow-400';
  if (score >= 25) return 'text-orange-400';
  return 'text-red-400';
}

export function getScoreBgColor(score: number): string {
  if (score >= 85) return 'bg-green-500/20 border-green-500/40';
  if (score >= 70) return 'bg-blue-500/20 border-blue-500/40';
  if (score >= 50) return 'bg-yellow-500/20 border-yellow-500/40';
  if (score >= 25) return 'bg-orange-500/20 border-orange-500/40';
  return 'bg-red-500/20 border-red-500/40';
}
