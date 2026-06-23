import Foundation

struct CopyEngine {
    static func dashboardMessage(score: Int, hour: Int, log: DailyLog) -> String {
        if score >= 85 { return "Good. Keep stacking wins." }
        if !log.morningRoutineCompleted && hour > 10 { return "Bad wakeup. Still salvageable. Launch now." }
        if log.proteinGrams < 50 && hour > 14 { return "Calories are moving faster than protein. Fix the ratio." }
        if log.ibMinutes == 0 && hour > 15 { return "IB block still needed. 60 minutes minimum. Not perfect. Just do it." }
        if score < 50 { return "Salvage Mode recommended. Minimum viable day still counts." }
        if score < 70 { return "You're behind, not cooked. Hit the next block." }
        return "Solid progress. Protect the afternoon."
    }

    static func statusLabel(score: Int) -> String {
        switch score {
        case 85...100: return "On Track"
        case 70..<85: return "Solid"
        case 50..<70: return "Salvageable"
        case 25..<50: return "Behind"
        default: return "Cooked but recoverable"
        }
    }

    static let urgeEmergencySteps = [
        "Leave the room immediately.",
        "Put the phone face-down.",
        "Do 20 pushups.",
        "Drink a full glass of water.",
        "Go downstairs or outside.",
        "Start a 10-minute timer.",
        "Do not negotiate while in bed."
    ]

    static let salvageChecklist = [
        "Shower or rinse",
        "Brush teeth",
        "Drink 500ml water",
        "Hit 120g protein minimum",
        "Stay in calorie range",
        "Complete 60 min IB block",
        "One movement session",
        "No porn/masturbation rest of day",
        "No phone in bed tonight",
        "Night skincare",
        "Sleep before midnight"
    ]
}
