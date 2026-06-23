import SwiftUI
import SwiftData

struct SkincareView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query private var settings: [UserSettings]

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Skincare streak
                    HStack {
                        Label("\(userSettings.skincareStreak) day streak", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Spacer()
                        if userSettings.skincareStreak > 7 {
                            Text("🔥 Consistent!")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Morning routine
                    PillarCard(title: "Morning Routine", icon: "sun.max.fill",
                               completed: todayLog.sunscreenApplied) {
                        VStack(spacing: 0) {
                            ChecklistRow(label: "Cleanser / Rinse", checked: Binding(
                                get: { todayLog.showerCompleted },
                                set: { todayLog.showerCompleted = $0 }
                            ))
                            Divider()
                            ChecklistRow(label: "Moisturizer", checked: Binding(
                                get: { todayLog.morningRoutineCompleted },
                                set: { todayLog.morningRoutineCompleted = $0 }
                            ))
                            Divider()
                            ChecklistRow(label: "Sunscreen SPF (required!)", checked: Binding(
                                get: { todayLog.sunscreenApplied },
                                set: { todayLog.sunscreenApplied = $0 }
                            ))
                            Divider()
                            ChecklistRow(label: "Sunscreen Reapplied (afternoon)", checked: Binding(
                                get: { todayLog.sunscreenReapplied },
                                set: { todayLog.sunscreenReapplied = $0 }
                            ))
                        }
                    }

                    // Night routine
                    PillarCard(title: "Night Routine", icon: "moon.stars.fill",
                               completed: todayLog.nightRoutineCompleted) {
                        VStack(spacing: 0) {
                            ChecklistRow(label: "Cleanser", checked: Binding(
                                get: { todayLog.nightCleanser },
                                set: { todayLog.nightCleanser = $0 }
                            ))
                            Divider()
                            ChecklistRow(label: "Acne Treatment", checked: Binding(
                                get: { todayLog.acneTreatmentCompleted },
                                set: { todayLog.acneTreatmentCompleted = $0 }
                            ))
                            Divider()
                            ChecklistRow(label: "Moisturizer", checked: Binding(
                                get: { todayLog.nightMoisturizer },
                                set: { todayLog.nightMoisturizer = $0 }
                            ))
                        }
                        .onChange(of: todayLog.nightCleanser) { _, _ in updateNightRoutine() }
                        .onChange(of: todayLog.acneTreatmentCompleted) { _, _ in updateNightRoutine() }
                        .onChange(of: todayLog.nightMoisturizer) { _, _ in updateNightRoutine() }
                    }

                    // Extra care
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extra Care")
                            .font(.headline)
                        ChecklistRow(label: "Shower after sweat", checked: Binding(
                            get: { todayLog.showerCompleted },
                            set: { todayLog.showerCompleted = $0 }
                        ))
                        Divider()
                        ChecklistRow(label: "Pillowcase changed this week", checked: Binding(
                            get: { todayLog.pillowcaseChanged },
                            set: { todayLog.pillowcaseChanged = $0 }
                        ))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Acne severity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Acne Severity Today")
                            .font(.headline)
                        HStack {
                            StarRatingView(rating: Binding(
                                get: { todayLog.acneSeverity },
                                set: { todayLog.acneSeverity = $0 }
                            ), max: 5)
                            Spacer()
                            Text(acneSeverityLabel(todayLog.acneSeverity))
                                .foregroundColor(.secondary)
                        }
                        if todayLog.acneSeverity >= 4 {
                            Text("High severity — prioritize night routine and pillowcase.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Sunscreen reminder
                    if !todayLog.sunscreenApplied && userSettings.morningSunscreenRequired {
                        HStack {
                            Image(systemName: "exclamationmark.sun.fill")
                                .foregroundColor(.yellow)
                            Text("Sunscreen is required today. Apply before going outside.")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Skincare")
        }
    }

    func updateNightRoutine() {
        todayLog.nightRoutineCompleted = todayLog.nightCleanser && todayLog.acneTreatmentCompleted && todayLog.nightMoisturizer
    }

    func acneSeverityLabel(_ n: Int) -> String {
        switch n {
        case 0: return "Not rated"
        case 1: return "Clear"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "Significant"
        case 5: return "Severe"
        default: return ""
        }
    }
}

#Preview {
    SkincareView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
