import SwiftData
import Foundation

@Model
class MealEntry {
    var mealName: String
    var time: Date
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var notes: String
    var mealQuality: String  // excellent/good/okay/bad
    var isHighProtein: Bool
    var isBuldakMeal: Bool
    var wasPlanned: Bool

    init(mealName: String, calories: Int, protein: Int, carbs: Int = 0, fat: Int = 0) {
        self.mealName = mealName
        self.time = Date()
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.notes = ""
        self.mealQuality = "good"
        self.isHighProtein = protein >= 20
        self.isBuldakMeal = mealName.lowercased().contains("buldak") || mealName.lowercased().contains("ramen")
        self.wasPlanned = false
    }
}
