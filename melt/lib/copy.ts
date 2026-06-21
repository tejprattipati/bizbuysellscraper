import { DailyLog } from './types';

export function getDashboardMessage(score: number, hour: number, log: DailyLog): string {
  if (score >= 85) return "Good. Keep stacking wins.";
  if (!log.morningRoutineCompleted && hour > 10) return "Bad wakeup. Still salvageable. Launch now.";
  if (log.proteinGrams < 50 && hour > 14) return "Calories are moving faster than protein. Fix the ratio.";
  if (!log.ibMinutes && hour > 15) return "IB block still needed. 60 minutes minimum. Not perfect. Just do it.";
  if (score < 50) return "Salvage Mode recommended. Minimum viable day still counts.";
  if (score < 70) return "You're behind, not cooked. Hit the next block.";
  return "Solid progress. Protect the afternoon.";
}

export function getMorningMessage(hour: number, completed: boolean): string {
  if (completed) return "Morning launched. Go get it.";
  if (hour < 8) return "Early. Get the routine done before momentum fades.";
  if (hour < 10) return "Window is open. Launch the morning.";
  if (hour < 12) return "Late start. Still counts. Do it now.";
  return "Afternoon launch. Better than nothing. Go.";
}

export function getUrgeMessage(intensity: number): string {
  if (intensity >= 8) return "High intensity urge. Leave the room immediately. Do not negotiate.";
  if (intensity >= 5) return "Moderate urge. Stand up. Get water. Do 10 pushups.";
  return "Low urge. Acknowledge and redirect. You've got this.";
}

export function getSalvageMessage(score: number): string {
  if (score >= 60) return "You're closer than you think. Two more wins and this is a solid day.";
  if (score >= 40) return "Not ideal, but not over. Hit the minimum checklist.";
  return "Salvage time. Small wins stack. Start with water and a meal.";
}
