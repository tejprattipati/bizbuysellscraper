import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var calories: Int
    var protein: Int
    var water: Double  // in liters
    var lifted: Bool
    var liftType: String
    var movementMinutes: Int
    var ibMinutes: Int
    var morningRoutineDone: Bool
    var showered: Bool
    var sunscreen: Bool
    var nightRoutineDone: Bool
    var pornAvoided: Bool
    var masturbationAvoided: Bool
    var phoneInBedAvoided: Bool
    var mood: Int  // 1-5
    var energy: Int  // 1-5
    var dayScore: Int  // 0-100
    var notes: String

    init(
        date: Date = Date(),
        calories: Int = 0,
        protein: Int = 0,
        water: Double = 0,
        lifted: Bool = false,
        liftType: String = "",
        movementMinutes: Int = 0,
        ibMinutes: Int = 0,
        morningRoutineDone: Bool = false,
        showered: Bool = false,
        sunscreen: Bool = false,
        nightRoutineDone: Bool = false,
        pornAvoided: Bool = true,
        masturbationAvoided: Bool = true,
        phoneInBedAvoided: Bool = false,
        mood: Int = 3,
        energy: Int = 3,
        dayScore: Int = 0,
        notes: String = ""
    ) {
        self.date = date
        self.calories = calories
        self.protein = protein
        self.water = water
        self.lifted = lifted
        self.liftType = liftType
        self.movementMinutes = movementMinutes
        self.ibMinutes = ibMinutes
        self.morningRoutineDone = morningRoutineDone
        self.showered = showered
        self.sunscreen = sunscreen
        self.nightRoutineDone = nightRoutineDone
        self.pornAvoided = pornAvoided
        self.masturbationAvoided = masturbationAvoided
        self.phoneInBedAvoided = phoneInBedAvoided
        self.mood = mood
        self.energy = energy
        self.dayScore = dayScore
        self.notes = notes
    }

    /// Computed day score based on logged data
    func computedScore() -> Int {
        var score = 0

        // Nutrition (30 pts)
        if calories >= 1600 && calories <= 1800 { score += 15 }
        else if calories > 0 && calories < 2000 { score += 8 }
        if protein >= 140 { score += 15 }
        else if protein >= 100 { score += 8 }

        // Hydration (10 pts)
        if water >= 3.0 { score += 10 }
        else if water >= 2.0 { score += 5 }

        // Training (20 pts)
        if lifted { score += 15 }
        if movementMinutes >= 30 { score += 5 }

        // IB Prep (10 pts)
        if ibMinutes >= 60 { score += 10 }
        else if ibMinutes >= 30 { score += 5 }

        // Routines (10 pts)
        if morningRoutineDone { score += 5 }
        if nightRoutineDone { score += 5 }

        // Discipline (10 pts)
        if pornAvoided { score += 4 }
        if masturbationAvoided { score += 3 }
        if phoneInBedAvoided { score += 3 }

        // Hygiene (5 pts)
        if showered { score += 3 }
        if sunscreen { score += 2 }

        // Mood/Energy (5 pts)
        score += max(0, mood - 1)  // 0-4 pts
        if energy >= 4 { score += 1 }

        return min(score, 100)
    }
}
