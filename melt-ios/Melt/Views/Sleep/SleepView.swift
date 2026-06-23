import SwiftUI
import SwiftData

struct SleepView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query private var settings: [UserSettings]

    @State private var showWakeTimePicker = false
    @State private var wakeTimeSelection = Date()

    private var todayLog: DailyLog {
        let today = Calendar.current.startOfDay(for: Date())
        if let log = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return log
        }
        let newLog = DailyLog(date: today)
        modelContext.insert(newLog)
        return newLog
    }

    private var yesterdayLog: DailyLog? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        return allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Tonight's target
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tonight's Target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(userSettings.sleepTargetTime)
                                .font(.title.bold())
                        }
                        Spacer()
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.indigo)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Yesterday's sleep
                    if let yesterday = yesterdayLog {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Night")
                                .font(.headline)
                            HStack {
                                if let slept = yesterday.sleptAtTime {
                                    VStack(alignment: .leading) {
                                        Text("Slept").font(.caption).foregroundColor(.secondary)
                                        Text(slept.formatted(date: .omitted, time: .shortened)).font(.subheadline.bold())
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Quality").font(.caption).foregroundColor(.secondary)
                                    HStack(spacing: 2) {
                                        ForEach(1...5, id: \.self) { i in
                                            Image(systemName: i <= yesterday.sleepQuality ? "star.fill" : "star")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }

                    // Log wake time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Wake Time")
                            .font(.headline)
                        if let wake = todayLog.wakeTime {
                            HStack {
                                Image(systemName: "alarm.fill").foregroundColor(.orange)
                                Text(wake.formatted(date: .omitted, time: .shortened))
                                    .font(.title3.bold())
                                Spacer()
                                Button("Edit") { showWakeTimePicker = true }
                                    .foregroundColor(.indigo)
                            }
                        } else {
                            Button(action: {
                                wakeTimeSelection = Date()
                                showWakeTimePicker = true
                            }) {
                                Label("Log Wake Time", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.indigo)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        if showWakeTimePicker {
                            DatePicker("Wake Time", selection: $wakeTimeSelection, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            Button("Save Wake Time") {
                                todayLog.wakeTime = wakeTimeSelection
                                showWakeTimePicker = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Sleep quality
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Quality (last night)")
                            .font(.headline)
                        HStack {
                            StarRatingView(rating: Binding(
                                get: { todayLog.sleepQuality },
                                set: { todayLog.sleepQuality = $0 }
                            ), max: 5)
                            Spacer()
                            Text(sleepQualityLabel(todayLog.sleepQuality))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Phone in bed toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: Binding(
                            get: { todayLog.phoneInBedAvoided },
                            set: { todayLog.phoneInBedAvoided = $0 }
                        )) {
                            Label("No Phone in Bed", systemImage: "iphone.slash")
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Night shutdown checklist
                    NightShutdownView(log: todayLog)
                }
                .padding()
            }
            .navigationTitle("Sleep")
        }
    }

    func sleepQualityLabel(_ q: Int) -> String {
        switch q {
        case 5: return "Excellent"
        case 4: return "Good"
        case 3: return "Okay"
        case 2: return "Poor"
        case 1: return "Terrible"
        default: return "Not rated"
        }
    }
}

#Preview {
    SleepView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
