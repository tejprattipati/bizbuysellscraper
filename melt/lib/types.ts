export interface UserSettings {
  wakeTargetTime: string;
  outOfBedGraceMinutes: number;
  sleepTargetTime: string;
  calorieMin: number;
  calorieMax: number;
  proteinTarget: number;
  waterTargetLiters: number;
  weeklyLiftTarget: number;
  weeklyLegSessionsTarget: number;
  pornAbstinenceGoalEnabled: boolean;
  masturbationAbstinenceGoalEnabled: boolean;
  morningSunscreenRequired: boolean;
  animeAllowedAfterCoreWorkOnly: boolean;
  bedPhoneRuleEnabled: boolean;
  ibModuleEnabled: boolean;
  ibDailyMinutesTarget: number;
  animeCapMinutes: number;
  claudeApiKey: string;
}

export interface Meal {
  id: string;
  mealName: string;
  time: string;
  calories: number;
  protein: number;
  carbs?: number;
  fat?: number;
  notes?: string;
  mealQuality: 'excellent' | 'good' | 'okay' | 'bad';
  isHighProtein: boolean;
  isBuldakMeal: boolean;
  wasPlanned: boolean;
}

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  weight: string;
  rpe?: number;
  notes?: string;
}

export interface LiftingLog {
  date: string;
  sessionType: 'upper' | 'lower' | 'full' | 'core' | 'rest';
  exercises: Exercise[];
  durationMinutes: number;
  intensity: number;
  crampsOccurred: boolean;
  crampSeverity?: 'none' | 'mild' | 'moderate' | 'severe';
  notes?: string;
}

export interface UrgeLog {
  id: string;
  time: string;
  intensity: number;
  trigger: string;
  actionTaken: string;
  outcome: 'resisted' | 'relapsed' | 'delayed';
}

export interface DailyLog {
  date: string;
  wakeTime?: string;
  outOfBedTime?: string;
  sleptAtTime?: string;
  sleepQuality?: number;
  morningRoutineCompleted: boolean;
  showerCompleted: boolean;
  brushedTeethMorning: boolean;
  sunscreenApplied: boolean;
  sunscreenReapplied: boolean;
  nightRoutineCompleted: boolean;
  cleanserCompleted: boolean;
  acneTreatmentCompleted: boolean;
  moisturizerCompleted: boolean;
  nightCleanser: boolean;
  pillowcaseChanged: boolean;
  acneSeverity?: number;
  calories: number;
  proteinGrams: number;
  waterLiters: number;
  meals: Meal[];
  lifted: boolean;
  liftType?: 'upper' | 'lower' | 'full' | 'rest' | 'other';
  sportPlayed?: 'basketball' | 'volleyball' | 'walk' | 'rollerblade' | 'none' | 'other';
  movementMinutes: number;
  legCramping?: 'none' | 'mild' | 'moderate' | 'severe';
  ibMinutes: number;
  ibTasksCompleted: string[];
  ibTopic?: string;
  ibConfidence?: number;
  ibNotes?: string;
  singingMinutes: number;
  animeMinutes: number;
  funActivityCompleted: boolean;
  funActivityDescription?: string;
  pornAvoided: boolean;
  masturbationAvoided: boolean;
  phoneInBedAvoided: boolean;
  bedRottingAvoided: boolean;
  urgesLogged: UrgeLog[];
  relapseOccurred: boolean;
  relapseType?: 'porn' | 'masturbation' | 'both';
  mood?: number;
  energy?: number;
  notes?: string;
  dayStatus: 'ideal' | 'minimum' | 'salvaged' | 'missed' | 'in-progress';
  salvageModeActivated: boolean;
  salvageCompleted: boolean;
  nutritionScreenshotAnalyzed: boolean;
  nutritionScreenshotNotes?: string;
}

export interface Streak {
  pornFree: number;
  masturbationFree: number;
  phoneOutOfBed: number;
  morningLaunch: number;
  skincare: number;
  wakeOnTime: number;
}
