import SwiftData
import Foundation

@Model
class UserSettings {
    var wakeTargetTime: String = "08:00"
    var outOfBedGraceMinutes: Int = 5
    var sleepTargetTime: String = "23:30"
    var calorieMin: Int = 1600
    var calorieMax: Int = 1800
    var proteinTarget: Int = 140
    var waterTargetLiters: Double = 3.0
    var weeklyLiftTarget: Int = 4
    var weeklyLegSessionsTarget: Int = 2
    var pornAbstinenceGoalEnabled: Bool = true
    var masturbationAbstinenceGoalEnabled: Bool = true
    var morningSunscreenRequired: Bool = true
    var animeAllowedAfterCoreWorkOnly: Bool = true
    var bedPhoneRuleEnabled: Bool = true
    var ibModuleEnabled: Bool = true
    var ibDailyMinutesTarget: Int = 90
    var animeCapMinutes: Int = 90
    var claudeApiKey: String = ""

    // Streaks
    var pornFreeStreak: Int = 0
    var masturbationFreeStreak: Int = 0
    var phoneOutOfBedStreak: Int = 0
    var morningLaunchStreak: Int = 0
    var skincareStreak: Int = 0
    var wakeOnTimeStreak: Int = 0
    var pornFreeStartDate: Date?
    var masturbationFreeStartDate: Date?

    init() {}
}
