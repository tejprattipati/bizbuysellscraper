import SwiftUI
import SwiftData

struct FunView: View {
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

    private var animeCapWarning: Bool {
        todayLog.animeMinutes >= userSettings.animeCapMinutes
    }

    let activities: [(String, String, String)] = [
        ("basketball", "🏀", "Basketball"),
        ("volleyball", "🏐", "Volleyball"),
        ("singing", "🎤", "Singing"),
        ("studio", "🎵", "Studio"),
        ("walk", "🚶", "Walk"),
        ("rollerblade", "🛼", "Rollerblade"),
        ("friends", "👥", "Friends"),
        ("anime", "📺", "Anime/Manga"),
        ("other", "✨", "Other")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Activity picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Fun Activity")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(activities, id: \.0) { (key, emoji, label) in
                                Button(action: {
                                    todayLog.funActivityDescription = label
                                    todayLog.sportPlayed = key
                                    todayLog.funActivityCompleted = true
                                }) {
                                    VStack(spacing: 6) {
                                        Text(emoji).font(.system(size: 28))
                                        Text(label).font(.caption2).multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(todayLog.funActivityDescription == label
                                                ? Color.indigo
                                                : Color(.secondarySystemBackground))
                                    .foregroundColor(todayLog.funActivityDescription == label ? .white : .primary)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Custom fun goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fun goal for today")
                            .font(.headline)
                        TextField("e.g. Practice a new song, watch ep 5...", text: Binding(
                            get: { todayLog.funActivityDescription },
                            set: { todayLog.funActivityDescription = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Singing tracker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🎤 Singing")
                                .font(.headline)
                            Spacer()
                            Text("\(todayLog.singingMinutes) min")
                                .foregroundColor(.secondary)
                        }
                        Stepper("Minutes: \(todayLog.singingMinutes)", value: Binding(
                            get: { todayLog.singingMinutes },
                            set: { todayLog.singingMinutes = $0 }
                        ), in: 0...240, step: 10)
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Anime tracker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("📺 Anime / Manga")
                                .font(.headline)
                            Spacer()
                            Text("\(todayLog.animeMinutes) / \(userSettings.animeCapMinutes) min")
                                .foregroundColor(animeCapWarning ? .red : .secondary)
                        }
                        Stepper("Minutes: \(todayLog.animeMinutes)", value: Binding(
                            get: { todayLog.animeMinutes },
                            set: { todayLog.animeMinutes = $0 }
                        ), in: 0...480, step: 15)
                        .font(.subheadline)

                        ProgressBar(
                            value: Double(todayLog.animeMinutes) / Double(userSettings.animeCapMinutes),
                            color: animeCapWarning ? .red : .yellow,
                            label: ""
                        )
                        .frame(height: 20)

                        if animeCapWarning {
                            Label("Anime cap reached (\(userSettings.animeCapMinutes) min). Put it down.", systemImage: "hand.raised.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if userSettings.animeAllowedAfterCoreWorkOnly {
                            Text("Anime allowed after IB block + workout only.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Fun complete toggle
                    Toggle(isOn: Binding(
                        get: { todayLog.funActivityCompleted },
                        set: { todayLog.funActivityCompleted = $0 }
                    )) {
                        Label("Fun goal completed!", systemImage: "party.popper.fill")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .tint(.yellow)
                }
                .padding()
            }
            .navigationTitle("Fun & Social")
        }
    }
}

#Preview {
    FunView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
