import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]
    @Query private var allLogs: [DailyLog]

    @State private var showResetTodayAlert = false
    @State private var showResetAllAlert = false
    @State private var showExportSheet = false
    @State private var exportJSON = ""
    @State private var showApiKeyField = false

    private var s: UserSettings {
        if let existing = settingsArray.first { return existing }
        let new = UserSettings()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Claude API") {
                    HStack {
                        if showApiKeyField {
                            TextField("sk-ant-...", text: Binding(get: { s.claudeApiKey }, set: { s.claudeApiKey = $0 }))
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                        } else {
                            SecureField("Claude API Key", text: Binding(get: { s.claudeApiKey }, set: { s.claudeApiKey = $0 }))
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                        }
                        Button(action: { showApiKeyField.toggle() }) {
                            Image(systemName: showApiKeyField ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    if s.claudeApiKey.isEmpty {
                        Text("Required for nutrition screenshot analysis.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("API key saved.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Section("Sleep") {
                    HStack {
                        Text("Wake Target")
                        Spacer()
                        TextField("08:00", text: Binding(get: { s.wakeTargetTime }, set: { s.wakeTargetTime = $0 }))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Sleep Target")
                        Spacer()
                        TextField("23:30", text: Binding(get: { s.sleepTargetTime }, set: { s.sleepTargetTime = $0 }))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                    }
                    Stepper("Out-of-bed grace: \(s.outOfBedGraceMinutes) min",
                            value: Binding(get: { s.outOfBedGraceMinutes }, set: { s.outOfBedGraceMinutes = $0 }),
                            in: 0...30)
                }

                Section("Nutrition Targets") {
                    Stepper("Cal min: \(s.calorieMin)",
                            value: Binding(get: { s.calorieMin }, set: { s.calorieMin = $0 }),
                            in: 1000...3000, step: 50)
                    Stepper("Cal max: \(s.calorieMax)",
                            value: Binding(get: { s.calorieMax }, set: { s.calorieMax = $0 }),
                            in: 1000...3500, step: 50)
                    Stepper("Protein target: \(s.proteinTarget)g",
                            value: Binding(get: { s.proteinTarget }, set: { s.proteinTarget = $0 }),
                            in: 50...300, step: 5)
                    HStack {
                        Text("Water target")
                        Spacer()
                        Stepper(String(format: "%.1fL", s.waterTargetLiters),
                                value: Binding(get: { s.waterTargetLiters }, set: { s.waterTargetLiters = $0 }),
                                in: 1.0...6.0, step: 0.25)
                    }
                }

                Section("Training") {
                    Stepper("Weekly lift target: \(s.weeklyLiftTarget)",
                            value: Binding(get: { s.weeklyLiftTarget }, set: { s.weeklyLiftTarget = $0 }),
                            in: 1...7)
                    Stepper("Weekly leg sessions: \(s.weeklyLegSessionsTarget)",
                            value: Binding(get: { s.weeklyLegSessionsTarget }, set: { s.weeklyLegSessionsTarget = $0 }),
                            in: 0...5)
                }

                Section("IB Prep") {
                    Toggle("IB Module Enabled", isOn: Binding(get: { s.ibModuleEnabled }, set: { s.ibModuleEnabled = $0 }))
                    Stepper("Daily IB target: \(s.ibDailyMinutesTarget) min",
                            value: Binding(get: { s.ibDailyMinutesTarget }, set: { s.ibDailyMinutesTarget = $0 }),
                            in: 15...300, step: 15)
                }

                Section("Discipline Goals") {
                    Toggle("Porn abstinence goal",
                           isOn: Binding(get: { s.pornAbstinenceGoalEnabled }, set: { s.pornAbstinenceGoalEnabled = $0 }))
                    Toggle("No-masturbation goal",
                           isOn: Binding(get: { s.masturbationAbstinenceGoalEnabled }, set: { s.masturbationAbstinenceGoalEnabled = $0 }))
                    Toggle("No phone in bed",
                           isOn: Binding(get: { s.bedPhoneRuleEnabled }, set: { s.bedPhoneRuleEnabled = $0 }))
                }

                Section("Skincare") {
                    Toggle("Morning sunscreen required",
                           isOn: Binding(get: { s.morningSunscreenRequired }, set: { s.morningSunscreenRequired = $0 }))
                }

                Section("Fun") {
                    Toggle("Anime after core work only",
                           isOn: Binding(get: { s.animeAllowedAfterCoreWorkOnly }, set: { s.animeAllowedAfterCoreWorkOnly = $0 }))
                    Stepper("Anime cap: \(s.animeCapMinutes) min",
                            value: Binding(get: { s.animeCapMinutes }, set: { s.animeCapMinutes = $0 }),
                            in: 15...300, step: 15)
                }

                Section("Data") {
                    Button("Export Data (JSON)") {
                        exportJSON = generateExportJSON()
                        showExportSheet = true
                    }

                    Button("Reset Today's Log", role: .destructive) {
                        showResetTodayAlert = true
                    }

                    Button("Reset All Data", role: .destructive) {
                        showResetAllAlert = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Today?", isPresented: $showResetTodayAlert) {
                Button("Reset", role: .destructive) { resetToday() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete today's log and create a fresh one.")
            }
            .alert("Reset ALL Data?", isPresented: $showResetAllAlert) {
                Button("Delete Everything", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all logs. This cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(text: exportJSON)
            }
        }
    }

    func resetToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if let log = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            modelContext.delete(log)
        }
        let newLog = DailyLog(date: today)
        modelContext.insert(newLog)
    }

    func resetAll() {
        for log in allLogs {
            modelContext.delete(log)
        }
    }

    func generateExportJSON() -> String {
        let logs = allLogs.map { log -> [String: Any] in
            [
                "date": log.date.ISO8601Format(),
                "calories": log.calories,
                "protein": log.proteinGrams,
                "water": log.waterLiters,
                "lifted": log.lifted,
                "ibMinutes": log.ibMinutes,
                "pornAvoided": log.pornAvoided,
                "masturbationAvoided": log.masturbationAvoided,
                "morningRoutineCompleted": log.morningRoutineCompleted,
                "nightRoutineCompleted": log.nightRoutineCompleted,
                "sleepQuality": log.sleepQuality,
                "mood": log.mood,
                "energy": log.energy,
                "notes": log.notes
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: logs, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{\"error\": \"export failed\"}"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
