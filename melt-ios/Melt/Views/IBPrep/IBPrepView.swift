import SwiftUI
import SwiftData

struct IBPrepView: View {
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
                VStack(spacing: 20) {
                    // Placeholder banner
                    VStack(spacing: 8) {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.indigo)
                        Text("IB Calendar Not Loaded")
                            .font(.title2.bold())
                        Text("Paste or import your technical calendar to activate the full IB module.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Import Calendar") {
                            // Future: import IB calendar
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Daily tracking (always available)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's IB Tracking")
                            .font(.headline)

                        ProgressBar(
                            value: Double(todayLog.ibMinutes) / Double(userSettings.ibDailyMinutesTarget),
                            color: .blue,
                            label: "Minutes: \(todayLog.ibMinutes) / \(userSettings.ibDailyMinutesTarget)"
                        )
                        .frame(height: 20)

                        Stepper("IB Minutes: \(todayLog.ibMinutes)", value: Binding(
                            get: { todayLog.ibMinutes },
                            set: { todayLog.ibMinutes = $0 }
                        ), in: 0...480, step: 15)

                        TextField("Topic / what you covered", text: Binding(
                            get: { todayLog.ibTopic },
                            set: { todayLog.ibTopic = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        TextField("Notes", text: Binding(
                            get: { todayLog.ibNotes },
                            set: { todayLog.ibNotes = $0 }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)

                        HStack {
                            Text("Confidence:")
                            StarRatingView(rating: Binding(
                                get: { todayLog.ibConfidence },
                                set: { todayLog.ibConfidence = $0 }
                            ), max: 5)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Block toggles
                    VStack(spacing: 0) {
                        Toggle(isOn: .constant(todayLog.ibMinutes >= 90)) {
                            Label("Technical Block Complete (90 min)", systemImage: "checkmark.circle")
                        }
                        .disabled(true)
                        Divider()
                        Toggle(isOn: .constant(todayLog.ibMinutes >= 60)) {
                            Label("Secondary Block Complete (60 min)", systemImage: "checkmark.circle")
                        }
                        .disabled(true)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    if todayLog.ibMinutes >= userSettings.ibDailyMinutesTarget {
                        Label("IB target hit today. ", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("IB Prep")
        }
    }
}

#Preview {
    IBPrepView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
