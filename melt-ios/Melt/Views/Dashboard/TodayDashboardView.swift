import SwiftUI
import SwiftData

struct TodayDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query private var settings: [UserSettings]

    @State private var currentTime = Date()
    @State private var showSalvage = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

    private var score: Int {
        ScoringEngine.calculateScore(log: todayLog, settings: userSettings)
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f.string(from: currentTime)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Score and message
                    HStack(alignment: .center, spacing: 20) {
                        DayScoreBadge(score: score)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(ScoringEngine.dayLabel(score: score))
                                .font(.title2.bold())
                            Text(CopyEngine.dashboardMessage(score: score, hour: hour, log: todayLog))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Morning Launch card
                    PillarCard(title: "Morning Launch", icon: "sun.max.fill",
                               completed: todayLog.morningRoutineCompleted) {
                        VStack(spacing: 4) {
                            ChecklistRow(label: "Morning Routine", checked: Binding(
                                get: { todayLog.morningRoutineCompleted },
                                set: { todayLog.morningRoutineCompleted = $0 }
                            ))
                            ChecklistRow(label: "Shower", checked: Binding(
                                get: { todayLog.showerCompleted },
                                set: { todayLog.showerCompleted = $0 }
                            ))
                            ChecklistRow(label: "Brushed Teeth", checked: Binding(
                                get: { todayLog.brushedTeethMorning },
                                set: { todayLog.brushedTeethMorning = $0 }
                            ))
                            ChecklistRow(label: "Sunscreen Applied", checked: Binding(
                                get: { todayLog.sunscreenApplied },
                                set: { todayLog.sunscreenApplied = $0 }
                            ))
                        }
                    }

                    // Nutrition card
                    PillarCard(title: "Nutrition", icon: "fork.knife",
                               completed: todayLog.proteinGrams >= userSettings.proteinTarget &&
                               todayLog.calories >= userSettings.calorieMin) {
                        VStack(spacing: 10) {
                            ProgressBar(
                                value: Double(todayLog.calories) / Double(userSettings.calorieMax),
                                color: todayLog.calories > userSettings.calorieMax ? .red : .green,
                                label: "Calories: \(todayLog.calories) / \(userSettings.calorieMin)-\(userSettings.calorieMax)"
                            )
                            ProgressBar(
                                value: Double(todayLog.proteinGrams) / Double(userSettings.proteinTarget),
                                color: .indigo,
                                label: "Protein: \(todayLog.proteinGrams)g / \(userSettings.proteinTarget)g"
                            )
                            ProgressBar(
                                value: todayLog.waterLiters / userSettings.waterTargetLiters,
                                color: .cyan,
                                label: "Water: \(String(format: "%.1f", todayLog.waterLiters))L / \(String(format: "%.1f", userSettings.waterTargetLiters))L"
                            )
                        }
                    }

                    // Training card
                    PillarCard(title: "Training", icon: "dumbbell.fill",
                               completed: todayLog.lifted) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Lifted Today", isOn: Binding(
                                get: { todayLog.lifted },
                                set: { todayLog.lifted = $0 }
                            ))
                            if todayLog.lifted {
                                HStack {
                                    Text("Type:")
                                        .foregroundColor(.secondary)
                                    Text(todayLog.liftType.capitalized)
                                        .fontWeight(.semibold)
                                }
                            }
                            HStack {
                                Text("Sport:")
                                    .foregroundColor(.secondary)
                                Text(todayLog.sportPlayed == "none" ? "—" : todayLog.sportPlayed.capitalized)
                            }
                        }
                    }

                    // IB Prep card
                    PillarCard(title: "IB Prep", icon: "briefcase.fill",
                               completed: todayLog.ibMinutes >= userSettings.ibDailyMinutesTarget) {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressBar(
                                value: Double(todayLog.ibMinutes) / Double(userSettings.ibDailyMinutesTarget),
                                color: .blue,
                                label: "IB Minutes: \(todayLog.ibMinutes) / \(userSettings.ibDailyMinutesTarget)"
                            )
                            if !todayLog.ibTopic.isEmpty {
                                Text("Topic: \(todayLog.ibTopic)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Stepper("Minutes: \(todayLog.ibMinutes)", value: Binding(
                                get: { todayLog.ibMinutes },
                                set: { todayLog.ibMinutes = $0 }
                            ), in: 0...480, step: 15)
                            .font(.subheadline)
                        }
                    }

                    // Discipline card
                    PillarCard(title: "Discipline", icon: "shield.fill",
                               completed: todayLog.pornAvoided && todayLog.masturbationAvoided &&
                               todayLog.phoneInBedAvoided && todayLog.bedRottingAvoided) {
                        VStack(spacing: 4) {
                            ChecklistRow(label: "Porn-free", checked: Binding(
                                get: { todayLog.pornAvoided },
                                set: { todayLog.pornAvoided = $0 }
                            ))
                            ChecklistRow(label: "Masturbation-free", checked: Binding(
                                get: { todayLog.masturbationAvoided },
                                set: { todayLog.masturbationAvoided = $0 }
                            ))
                            ChecklistRow(label: "No phone in bed", checked: Binding(
                                get: { todayLog.phoneInBedAvoided },
                                set: { todayLog.phoneInBedAvoided = $0 }
                            ))
                            ChecklistRow(label: "No bed rotting", checked: Binding(
                                get: { todayLog.bedRottingAvoided },
                                set: { todayLog.bedRottingAvoided = $0 }
                            ))
                        }
                    }

                    // Skincare card
                    PillarCard(title: "Skincare", icon: "sparkles",
                               completed: todayLog.sunscreenApplied && todayLog.nightRoutineCompleted) {
                        VStack(spacing: 4) {
                            ChecklistRow(label: "Sunscreen (AM)", checked: Binding(
                                get: { todayLog.sunscreenApplied },
                                set: { todayLog.sunscreenApplied = $0 }
                            ))
                            ChecklistRow(label: "Night Routine", checked: Binding(
                                get: { todayLog.nightRoutineCompleted },
                                set: { todayLog.nightRoutineCompleted = $0 }
                            ))
                        }
                    }

                    // Sleep card
                    PillarCard(title: "Sleep", icon: "moon.stars.fill",
                               completed: todayLog.sleepQuality > 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let slept = todayLog.sleptAtTime {
                                Text("Slept at: \(slept.formatted(date: .omitted, time: .shortened))")
                                    .font(.subheadline)
                            } else {
                                Text("Sleep time not logged")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Quality:")
                                StarRatingView(rating: Binding(
                                    get: { todayLog.sleepQuality },
                                    set: { todayLog.sleepQuality = $0 }
                                ), max: 5)
                            }
                        }
                    }

                    // Salvage Mode button
                    if score < 70 {
                        Button(action: { showSalvage = true }) {
                            Label("Activate Salvage Mode", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(12)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Melt 🧊")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(timeString)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .sheet(isPresented: $showSalvage) {
            SalvageModeView()
        }
    }
}

#Preview {
    TodayDashboardView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
