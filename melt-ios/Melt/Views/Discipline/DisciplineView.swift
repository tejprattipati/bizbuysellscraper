import SwiftUI
import SwiftData

struct DisciplineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query private var settings: [UserSettings]

    @State private var showUrgeMode = false
    @State private var showRelapseLog = false
    @State private var relapseLogExpanded = false

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
                    // Streak counters
                    HStack(spacing: 12) {
                        StreakCard(
                            title: "Porn-Free",
                            days: userSettings.pornFreeStreak,
                            icon: "shield.fill",
                            color: userSettings.pornFreeStreak > 7 ? .green : .indigo
                        )
                        StreakCard(
                            title: "Clean",
                            days: userSettings.masturbationFreeStreak,
                            icon: "hand.raised.fill",
                            color: userSettings.masturbationFreeStreak > 7 ? .green : .blue
                        )
                        StreakCard(
                            title: "No Phone Bed",
                            days: userSettings.phoneOutOfBedStreak,
                            icon: "iphone.slash",
                            color: userSettings.phoneOutOfBedStreak > 7 ? .green : .purple
                        )
                    }

                    // Today's toggles
                    VStack(spacing: 0) {
                        DisciplineToggleRow(
                            label: "Porn-free today",
                            icon: "shield.fill",
                            isOn: Binding(get: { todayLog.pornAvoided }, set: { todayLog.pornAvoided = $0 }),
                            positive: true
                        )
                        Divider()
                        DisciplineToggleRow(
                            label: "No masturbation",
                            icon: "hand.raised.fill",
                            isOn: Binding(get: { todayLog.masturbationAvoided }, set: { todayLog.masturbationAvoided = $0 }),
                            positive: true
                        )
                        Divider()
                        DisciplineToggleRow(
                            label: "No phone in bed",
                            icon: "iphone.slash",
                            isOn: Binding(get: { todayLog.phoneInBedAvoided }, set: { todayLog.phoneInBedAvoided = $0 }),
                            positive: true
                        )
                        Divider()
                        DisciplineToggleRow(
                            label: "No bed rotting",
                            icon: "bed.double.fill",
                            isOn: Binding(get: { todayLog.bedRottingAvoided }, set: { todayLog.bedRottingAvoided = $0 }),
                            positive: true
                        )
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Urge mode panic button
                    Button(action: { showUrgeMode = true }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("URGE MODE")
                                    .font(.headline)
                                Text("Tap if you're fighting right now")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                    }

                    // Relapse handling
                    if todayLog.relapseOccurred {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Relapse logged today.", systemImage: "arrow.clockwise")
                                .foregroundColor(.orange)
                                .font(.subheadline.bold())
                            Text("Log it, learn from it, continue the day.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Relapse log (collapsed)
                    DisclosureGroup("Relapse Log", isExpanded: $relapseLogExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Log a Relapse Today", isOn: Binding(
                                get: { todayLog.relapseOccurred },
                                set: { todayLog.relapseOccurred = $0 }
                            ))
                            if todayLog.relapseOccurred {
                                Picker("Type", selection: Binding(
                                    get: { todayLog.relapseType.isEmpty ? "porn" : todayLog.relapseType },
                                    set: { todayLog.relapseType = $0 }
                                )) {
                                    Text("Porn").tag("porn")
                                    Text("Masturbation").tag("masturbation")
                                    Text("Both").tag("both")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Urge history
                    if !todayLog.urges.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Urge Log")
                                .font(.headline)
                            ForEach(todayLog.urges) { urge in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(urge.time.formatted(date: .omitted, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Intensity: \(urge.intensity)/10")
                                            .font(.subheadline)
                                        if !urge.trigger.isEmpty {
                                            Text("Trigger: \(urge.trigger)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(urge.outcome.capitalized)
                                        .font(.caption.bold())
                                        .foregroundColor(urge.outcome == "resisted" ? .green : .red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background((urge.outcome == "resisted" ? Color.green : Color.red).opacity(0.15))
                                        .cornerRadius(8)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Discipline")
            .fullScreenCover(isPresented: $showUrgeMode) {
                UrgeModeView()
            }
        }
    }
}

struct StreakCard: View {
    let title: String
    let days: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text("\(days)")
                .font(.title.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if days > 7 {
                Text("🔥")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DisciplineToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    let positive: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isOn ? .green : .secondary)
                    .frame(width: 24)
                Text(label)
                    .foregroundColor(isOn ? .primary : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .tint(.green)
    }
}

#Preview {
    DisciplineView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
