import SwiftUI
import SwiftData

struct LiftingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query(sort: \DailyLog.date, order: .reverse) private var recentLogs: [DailyLog]
    @Query private var settings: [UserSettings]

    @State private var showLogWorkout = false

    private var todayLog: DailyLog {
        let today = Calendar.current.startOfDay(for: Date())
        if let log = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return log
        }
        let newLog = DailyLog(date: today)
        modelContext.insert(newLog)
        return newLog
    }

    private var plannedSessionType: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // weekday: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
        switch weekday {
        case 2, 4, 6: return "upper"   // Mon, Wed, Fri
        case 3, 7: return "lower"      // Tue, Sat
        case 5: return "rest"          // Thu
        case 1: return "full"          // Sun (volleyball/sport)
        default: return "upper"
        }
    }

    private var plannedDescription: String {
        switch plannedSessionType {
        case "upper": return "Upper Body"
        case "lower": return "Light Legs + Core"
        case "rest": return "Rest / Walk"
        case "full": return "Volleyball / Sport"
        default: return "Training"
        }
    }

    private var weekSessions: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return recentLogs.filter { $0.date >= startOfWeek && $0.lifted }.count
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var showAntyCramp: Bool {
        ["lower", "full"].contains(plannedSessionType) || ["lower", "full"].contains(todayLog.liftType)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Planned session
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Plan")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(plannedDescription)
                                .font(.title2.bold())
                        }
                        Spacer()
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Weekly summary
                    HStack(spacing: 0) {
                        ForEach(0..<userSettings.weeklyLiftTarget, id: \.self) { i in
                            Circle()
                                .fill(i < weekSessions ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(i < weekSessions ? .white : .secondary)
                                )
                            if i < userSettings.weeklyLiftTarget - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        Text("\(weekSessions)/\(userSettings.weeklyLiftTarget) sessions this week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 40),
                        alignment: .top
                    )

                    // Today's lift status
                    VStack(spacing: 8) {
                        Toggle(isOn: Binding(
                            get: { todayLog.lifted },
                            set: { todayLog.lifted = $0 }
                        )) {
                            Label("Lifted Today", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                        }
                        if todayLog.lifted {
                            Picker("Lift Type", selection: Binding(
                                get: { todayLog.liftType },
                                set: { todayLog.liftType = $0 }
                            )) {
                                Text("Upper").tag("upper")
                                Text("Lower").tag("lower")
                                Text("Full Body").tag("full")
                                Text("Core").tag("core")
                                Text("Rest").tag("rest")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Anti-cramp checklist
                    if showAntyCramp {
                        AntyCrampCheckView(log: todayLog)
                    }

                    // Log workout button
                    Button(action: { showLogWorkout = true }) {
                        Label("Log Workout Details", systemImage: "pencil.and.list.clipboard")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    // Today's sessions
                    if !todayLog.liftingSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Sessions")
                                .font(.headline)
                            ForEach(todayLog.liftingSessions) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.sessionType.capitalized)
                                            .font(.subheadline.bold())
                                        Text("\(session.durationMinutes) min • Intensity: \(session.intensity)/5")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if session.crampsOccurred {
                                        Label("Cramps", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Sport section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sport / Movement")
                            .font(.headline)
                        Picker("Sport", selection: Binding(
                            get: { todayLog.sportPlayed },
                            set: { todayLog.sportPlayed = $0 }
                        )) {
                            Text("None").tag("none")
                            Text("Basketball").tag("basketball")
                            Text("Volleyball").tag("volleyball")
                            Text("Walk").tag("walk")
                            Text("Rollerblade").tag("rollerblade")
                            Text("Other").tag("other")
                        }
                        .pickerStyle(.menu)

                        Stepper("Movement: \(todayLog.movementMinutes) min", value: Binding(
                            get: { todayLog.movementMinutes },
                            set: { todayLog.movementMinutes = $0 }
                        ), in: 0...300, step: 10)
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Training")
            .sheet(isPresented: $showLogWorkout) {
                LogWorkoutView(log: todayLog)
            }
        }
    }
}

#Preview {
    LiftingView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
