import Foundation

struct ScoringEngine {
    static func calculateScore(log: DailyLog, settings: UserSettings) -> Int {
        var score = 0

        // Morning launch: 15 pts
        if log.morningRoutineCompleted { score += 8 }
        if log.showerCompleted { score += 4 }
        if log.sunscreenApplied { score += 3 }

        // Nutrition: 20 pts
        if log.proteinGrams >= settings.proteinTarget { score += 12 }
        else if log.proteinGrams >= Int(Double(settings.proteinTarget) * 0.85) { score += 7 }
        if log.calories >= settings.calorieMin && log.calories <= settings.calorieMax { score += 5 }
        else if log.calories > 0 { score += 2 }
        if log.waterLiters >= settings.waterTargetLiters { score += 3 }

        // IB/study: 20 pts
        if log.ibMinutes >= settings.ibDailyMinutesTarget { score += 20 }
        else if log.ibMinutes >= 60 { score += 12 }
        else if log.ibMinutes >= 30 { score += 6 }

        // Lift/movement: 15 pts
        if log.lifted { score += 12 }
        if log.sportPlayed != "none" && !log.sportPlayed.isEmpty { score += 5 }
        else if log.movementMinutes >= 30 { score += 5 }

        // Discipline: 15 pts
        if log.pornAvoided { score += 5 }
        if log.masturbationAvoided { score += 5 }
        if log.phoneInBedAvoided { score += 3 }
        if log.bedRottingAvoided { score += 2 }

        // Skincare/hygiene: 10 pts
        if log.nightRoutineCompleted { score += 6 }
        if log.sunscreenApplied { score += 2 }
        if log.showerCompleted { score += 2 }

        return min(score, 100)
    }

    static func dayLabel(score: Int) -> String {
        switch score {
        case 85...100: return "Locked 🔒"
        case 70..<85: return "Solid"
        case 50..<70: return "Salvaged"
        case 25..<50: return "Slipping"
        default: return "Reset Tomorrow"
        }
    }

    static func dayLabelColor(score: Int) -> String {
        switch score {
        case 85...100: return "green"
        case 70..<85: return "blue"
        case 50..<70: return "yellow"
        case 25..<50: return "orange"
        default: return "red"
        }
    }
}
