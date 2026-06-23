import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @Query private var settings: [UserSettings]

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var last7Logs: [DailyLog] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return Array(logs.filter { $0.date >= sevenDaysAgo }.prefix(7)).reversed()
    }

    private var avgProtein: Int {
        guard !last7Logs.isEmpty else { return 0 }
        return last7Logs.reduce(0) { $0 + $1.proteinGrams } / last7Logs.count
    }

    private var avgCalories: Int {
        guard !last7Logs.isEmpty else { return 0 }
        return last7Logs.reduce(0) { $0 + $1.calories } / last7Logs.count
    }

    private var avgWater: Double {
        guard !last7Logs.isEmpty else { return 0 }
        return last7Logs.reduce(0.0) { $0 + $1.waterLiters } / Double(last7Logs.count)
    }

    private var avgIBMinutes: Int {
        guard !last7Logs.isEmpty else { return 0 }
        return last7Logs.reduce(0) { $0 + $1.ibMinutes } / last7Logs.count
    }

    private var avgSleepQuality: Double {
        let rated = last7Logs.filter { $0.sleepQuality > 0 }
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0) { $0 + $1.sleepQuality }) / Double(rated.count)
    }

    private var liftSessionsThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return logs.filter { $0.date >= startOfWeek && $0.lifted }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Score bar chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("7-Day Score")
                            .font(.headline)

                        if last7Logs.isEmpty {
                            Text("No data yet. Start logging to see your scores.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(last7Logs) { log in
                                    let score = ScoringEngine.calculateScore(log: log, settings: userSettings)
                                    VStack(spacing: 4) {
                                        Text("\(score)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(scoreColor(score))
                                            .frame(height: max(CGFloat(score) * 1.2, 4))
                                        Text(dayLabel(log.date))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 140)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Streak badges
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Streaks")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StreakBadge(title: "Porn-Free", days: userSettings.pornFreeStreak, color: .indigo)
                            StreakBadge(title: "Morning Launch", days: userSettings.morningLaunchStreak, color: .orange)
                            StreakBadge(title: "Skincare", days: userSettings.skincareStreak, color: .purple)
                            StreakBadge(title: "Wake On Time", days: userSettings.wakeOnTimeStreak, color: .yellow)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Averages
                    VStack(alignment: .leading, spacing: 12) {
                        Text("7-Day Averages")
                            .font(.headline)
                        VStack(spacing: 10) {
                            AverageRow(label: "Protein", value: "\(avgProtein)g", target: "\(userSettings.proteinTarget)g",
                                       progress: Double(avgProtein) / Double(userSettings.proteinTarget), color: .indigo)
                            AverageRow(label: "Calories", value: "\(avgCalories)", target: "\(userSettings.calorieMax)",
                                       progress: Double(avgCalories) / Double(userSettings.calorieMax), color: .green)
                            AverageRow(label: "Water", value: String(format: "%.1fL", avgWater), target: String(format: "%.1fL", userSettings.waterTargetLiters),
                                       progress: avgWater / userSettings.waterTargetLiters, color: .cyan)
                            AverageRow(label: "IB Minutes", value: "\(avgIBMinutes)", target: "\(userSettings.ibDailyMinutesTarget)",
                                       progress: Double(avgIBMinutes) / Double(userSettings.ibDailyMinutesTarget), color: .blue)
                            AverageRow(label: "Sleep Quality", value: String(format: "%.1f/5", avgSleepQuality), target: "5",
                                       progress: avgSleepQuality / 5.0, color: .purple)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Compliance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week")
                            .font(.headline)
                        HStack(spacing: 20) {
                            ComplianceStat(label: "Lifts", value: "\(liftSessionsThisWeek)/\(userSettings.weeklyLiftTarget)", color: .red)
                            ComplianceStat(label: "IB Days", value: "\(last7Logs.filter { $0.ibMinutes >= 60 }.count)/7", color: .blue)
                            ComplianceStat(label: "Discipline", value: "\(last7Logs.filter { $0.pornAvoided && $0.masturbationAvoided }.count)/\(last7Logs.count)", color: .green)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }

    func scoreColor(_ score: Int) -> Color {
        switch score {
        case 85...100: return .green
        case 70..<85: return .blue
        case 50..<70: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }

    func dayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "E"
        return df.string(from: date)
    }
}

struct StreakBadge: View {
    let title: String
    let days: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(days)")
                .font(.title.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if days > 7 {
                Text("🔥 On Fire")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AverageRow: View {
    let label: String
    let value: String
    let target: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                Text("/ \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 6)
        }
    }
}

struct ComplianceStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
