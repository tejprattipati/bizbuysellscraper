import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query private var settings: [UserSettings]

    @State private var showAddMeal = false
    @State private var showScreenshot = false

    private var todayLog: DailyLog {
        let today = Calendar.current.startOfDay(for: Date())
        if let log = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return log
        }
        let newLog = DailyLog(date: today)
        modelContext.insert(newLog)
        return newLog
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var proteinStatus: (status: String, message: String) {
        NutritionHelpers.proteinStatus(protein: todayLog.proteinGrams, target: userSettings.proteinTarget, hour: hour)
    }

    private var hasBuldak: Bool {
        todayLog.meals.contains { NutritionHelpers.isBuldak($0.mealName) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary cards
                    VStack(spacing: 12) {
                        NutrientSummaryCard(
                            title: "Calories",
                            value: "\(todayLog.calories)",
                            target: "\(userSettings.calorieMin)–\(userSettings.calorieMax)",
                            progress: Double(todayLog.calories) / Double(userSettings.calorieMax),
                            color: todayLog.calories > userSettings.calorieMax ? .red : .green,
                            icon: "flame.fill"
                        )

                        NutrientSummaryCard(
                            title: "Protein",
                            value: "\(todayLog.proteinGrams)g",
                            target: "\(userSettings.proteinTarget)g",
                            progress: Double(todayLog.proteinGrams) / Double(userSettings.proteinTarget),
                            color: .indigo,
                            icon: "bolt.fill"
                        )

                        NutrientSummaryCard(
                            title: "Water",
                            value: String(format: "%.1fL", todayLog.waterLiters),
                            target: String(format: "%.1fL", userSettings.waterTargetLiters),
                            progress: todayLog.waterLiters / userSettings.waterTargetLiters,
                            color: .cyan,
                            icon: "drop.fill"
                        )
                    }

                    // Suggestion
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next Move")
                            .font(.caption.uppercased())
                            .foregroundColor(.secondary)
                        Text(NutritionHelpers.suggestedFood(
                            calories: todayLog.calories,
                            protein: todayLog.proteinGrams,
                            calorieMax: userSettings.calorieMax,
                            proteinTarget: userSettings.proteinTarget
                        ))
                        .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Protein warning banner
                    if proteinStatus.status != "complete" {
                        HStack(spacing: 10) {
                            Image(systemName: proteinStatus.status == "urgent" ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .foregroundColor(proteinStatus.status == "urgent" ? .red : .orange)
                            Text(proteinStatus.message)
                                .font(.subheadline)
                                .foregroundColor(proteinStatus.status == "urgent" ? .red : .orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background((proteinStatus.status == "urgent" ? Color.red : Color.orange).opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Buldak alert
                    if hasBuldak {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Ramen/Buldak detected. Was this planned? Consider adding egg whites or chicken.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: { showAddMeal = true }) {
                            Label("Add Meal", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.indigo)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: { showScreenshot = true }) {
                            Label("Screenshot", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }

                    // Water stepper
                    HStack {
                        Text("Water")
                            .font(.subheadline)
                        Spacer()
                        Stepper(String(format: "%.1fL", todayLog.waterLiters), value: Binding(
                            get: { todayLog.waterLiters },
                            set: { todayLog.waterLiters = $0 }
                        ), in: 0...6, step: 0.25)
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Meal list
                    if !todayLog.meals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Meals")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(todayLog.meals) { meal in
                                MealRow(meal: meal)
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in
                                    let meal = todayLog.meals[i]
                                    todayLog.calories -= meal.calories
                                    todayLog.proteinGrams -= meal.protein
                                    modelContext.delete(meal)
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    } else {
                        Text("No meals logged yet.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Nutrition")
            .sheet(isPresented: $showAddMeal) {
                AddMealView(log: todayLog)
            }
            .sheet(isPresented: $showScreenshot) {
                ScreenshotAnalyzerView(log: todayLog)
            }
        }
    }
}

struct NutrientSummaryCard: View {
    let title: String
    let value: String
    let target: String
    let progress: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.title3.bold())
                Text("/ \(target)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MealRow: View {
    let meal: MealEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.mealName)
                    .font(.subheadline.bold())
                Text("Protein: \(meal.protein)g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(meal.calories) cal")
                    .font(.subheadline.bold())
                Text(meal.time.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    NutritionView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
