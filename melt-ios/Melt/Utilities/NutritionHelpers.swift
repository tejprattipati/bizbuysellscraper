import Foundation

struct NutritionHelpers {
    static func proteinStatus(protein: Int, target: Int, hour: Int) -> (status: String, message: String) {
        if protein >= target { return ("complete", "Protein target hit. ✓") }
        let gap = target - protein
        if hour < 12 && protein < 50 { return ("urgent", "Only \(protein)g protein by midday. Urgent. Egg whites or shake now.") }
        if hour >= 17 && protein < 100 { return ("behind", "\(gap)g protein remaining. Evening push needed.") }
        return ("on-track", "\(gap)g to go.")
    }

    static func suggestedFood(calories: Int, protein: Int, calorieMax: Int, proteinTarget: Int) -> String {
        let calRemaining = calorieMax - calories
        let protRemaining = proteinTarget - protein

        if protRemaining > 60 && calRemaining > 400 { return "Protein badly needed. Egg whites + Greek yogurt or chicken breast." }
        if protRemaining > 40 && calRemaining < 300 { return "Calories tight. Egg whites, Greek yogurt, or protein shake only." }
        if protRemaining > 20 && calRemaining > 300 { return "Close on protein. Add lean source to next meal." }
        if protRemaining <= 0 { return "Protein hit. Balance your remaining calories." }
        return "On track. Keep protein first in next meal."
    }

    static func isBuldak(_ name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("buldak") || lower.contains("ramen") || lower.contains("noodle")
    }

    static func proteinEfficiency(calories: Int, protein: Int) -> Double {
        guard calories > 0 else { return 0 }
        return Double(protein) / Double(calories) * 100
    }
}
