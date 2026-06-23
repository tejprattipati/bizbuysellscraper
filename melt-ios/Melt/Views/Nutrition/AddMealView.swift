import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let log: DailyLog

    @State private var mealName = ""
    @State private var calories = 0
    @State private var protein = 0
    @State private var carbs = 0
    @State private var fat = 0
    @State private var quality = "good"
    @State private var wasPlanned = false

    let qualityOptions = ["excellent", "good", "okay", "bad"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Info") {
                    TextField("Meal name", text: $mealName)
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", value: $protein, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", value: $carbs, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", value: $fat, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Quality") {
                    Picker("Meal Quality", selection: $quality) {
                        ForEach(qualityOptions, id: \.self) { q in
                            Text(q.capitalized).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Was Planned", isOn: $wasPlanned)
                }

                if NutritionHelpers.isBuldak(mealName) {
                    Section {
                        Label("Buldak/Ramen detected. Add protein source?", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !mealName.isEmpty else { return }
                        let meal = MealEntry(mealName: mealName, calories: calories, protein: protein, carbs: carbs, fat: fat)
                        meal.mealQuality = quality
                        meal.wasPlanned = wasPlanned
                        meal.isBuldakMeal = NutritionHelpers.isBuldak(mealName)
                        log.meals.append(meal)
                        log.calories += calories
                        log.proteinGrams += protein
                        modelContext.insert(meal)
                        dismiss()
                    }
                    .disabled(mealName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddMealView(log: DailyLog())
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
