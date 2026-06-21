export function getProteinStatus(protein: number, target: number, hour: number) {
  if (protein >= target) return { status: 'complete', message: 'Protein target hit.' };
  const gap = target - protein;
  if (hour < 12 && protein < 50) return { status: 'urgent', message: `Only ${protein}g protein so far. Urgent. Egg whites or shake now.` };
  if (hour >= 17 && protein < 100) return { status: 'behind', message: `${gap}g protein remaining. Evening push needed.` };
  return { status: 'on-track', message: `${gap}g to go.` };
}

export function getSuggestedFood(calories: number, protein: number, calorieMax: number, proteinTarget: number): string {
  const calRemaining = calorieMax - calories;
  const protRemaining = proteinTarget - protein;

  if (protRemaining > 60 && calRemaining > 400) return 'Protein badly needed. Egg whites + Greek yogurt or chicken breast.';
  if (protRemaining > 40 && calRemaining < 300) return 'Calories tight. Egg whites, Greek yogurt, or protein shake only.';
  if (protRemaining > 20 && calRemaining > 300) return 'Close on protein. Add lean source to next meal.';
  if (protRemaining <= 0) return 'Protein hit. Balance your remaining calories.';
  return 'On track. Keep protein first in next meal.';
}

export function isBuldakMeal(mealName: string): boolean {
  return /buldak|ramen|noodle/i.test(mealName);
}

export function getCalorieStatus(calories: number, min: number, max: number): { status: string; color: string } {
  if (calories === 0) return { status: 'Not started', color: 'text-slate-400' };
  if (calories < min * 0.5) return { status: 'Very low', color: 'text-red-400' };
  if (calories < min) return { status: 'Below target', color: 'text-orange-400' };
  if (calories <= max) return { status: 'On target', color: 'text-green-400' };
  if (calories <= max * 1.1) return { status: 'Slightly over', color: 'text-yellow-400' };
  return { status: 'Over target', color: 'text-red-400' };
}
