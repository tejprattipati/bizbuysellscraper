import SwiftUI
import SwiftData

struct AIAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]

    @AppStorage("claudeAPIKey") private var apiKey: String = ""

    @State private var analysisText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var hasAnalysis: Bool = false

    private var todayLog: DailyLog? {
        let calendar = Calendar.current
        return allLogs.first { calendar.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Day summary card
                    if let log = todayLog {
                        DaySummaryCard(log: log)
                    } else {
                        EmptyDayCard()
                    }

                    // Get Analysis button
                    Button(action: fetchAnalysis) {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isLoading ? "Analyzing..." : "Get Today's Analysis")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.indigo, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading || apiKey.isEmpty)
                    .padding(.horizontal)

                    if apiKey.isEmpty {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.orange)
                            Text("Add your Claude API key in Settings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Error message
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // Analysis result
                    if hasAnalysis && !analysisText.isEmpty {
                        AnalysisResultView(text: analysisText)
                            .padding(.horizontal)

                        ShareLink(
                            item: analysisText,
                            subject: Text("Melt Coach Analysis"),
                            message: Text("My AI coach's take on today:")
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Analysis")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func fetchAnalysis() {
        guard let log = todayLog else {
            errorMessage = "No data logged for today. Start logging to get an analysis."
            return
        }
        guard !apiKey.isEmpty else { return }

        isLoading = true
        errorMessage = ""

        Task {
            do {
                let result = try await ClaudeAPIClient.analyzeDayData(
                    calories: log.calories,
                    protein: log.protein,
                    water: log.water,
                    lifted: log.lifted,
                    liftType: log.liftType,
                    movementMinutes: log.movementMinutes,
                    ibMinutes: log.ibMinutes,
                    morningDone: log.morningRoutineDone,
                    showered: log.showered,
                    sunscreen: log.sunscreen,
                    nightDone: log.nightRoutineDone,
                    pornAvoided: log.pornAvoided,
                    masturbationAvoided: log.masturbationAvoided,
                    phoneInBedAvoided: log.phoneInBedAvoided,
                    score: log.dayScore > 0 ? log.dayScore : log.computedScore(),
                    mood: log.mood,
                    energy: log.energy,
                    apiKey: apiKey
                )
                await MainActor.run {
                    analysisText = result
                    hasAnalysis = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Day Summary Card

struct DaySummaryCard: View {
    let log: DailyLog

    private var score: Int { log.dayScore > 0 ? log.dayScore : log.computedScore() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today at a Glance")
                    .font(.headline)
                Spacer()
                Text("\(score)/100")
                    .font(.title2.bold())
                    .foregroundStyle(scoreColor)
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatChip(icon: "flame.fill", label: "Calories", value: "\(log.calories)", color: .orange)
                StatChip(icon: "p.circle.fill", label: "Protein", value: "\(log.protein)g", color: .blue)
                StatChip(icon: "drop.fill", label: "Water", value: String(format: "%.1fL", log.water), color: .cyan)
                StatChip(icon: "dumbbell.fill", label: "Lifted", value: log.lifted ? "Yes" : "No", color: log.lifted ? .green : .red)
                StatChip(icon: "figure.walk", label: "Movement", value: "\(log.movementMinutes)m", color: .teal)
                StatChip(icon: "book.fill", label: "IB Study", value: "\(log.ibMinutes)m", color: .purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        return .red
    }
}

struct StatChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EmptyDayCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No data logged for today")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Log your day first, then come back for an AI analysis.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Analysis Result

struct AnalysisResultView: View {
    let text: String

    private var sections: [(emoji: String, title: String, content: String)] {
        parseAnalysis(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Coach's Analysis")
                    .font(.headline)
                Spacer()
            }

            if sections.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                ForEach(sections, id: \.title) { section in
                    SectionCard(emoji: section.emoji, title: section.title, content: section.content)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func parseAnalysis(_ text: String) -> [(emoji: String, title: String, content: String)] {
        // Try to split numbered sections
        var results: [(emoji: String, title: String, content: String)] = []
        let emojis = ["🥗", "💪", "📊", "🔧"]
        let defaultTitles = ["Nutrition Assessment", "Training Assessment", "Overall Score", "Recommendations"]

        // Look for numbered sections like "1." or "**1."
        let lines = text.components(separatedBy: "\n")
        var current: (index: Int, lines: [String])? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            for i in 1...4 {
                if trimmed.hasPrefix("\(i).") || trimmed.hasPrefix("**\(i).") {
                    if let cur = current {
                        let content = cur.lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !content.isEmpty {
                            let idx = cur.index - 1
                            results.append((emojis[idx], defaultTitles[idx], content))
                        }
                    }
                    current = (i, [trimmed])
                    break
                }
            }
            if var cur = current, !trimmed.hasPrefix("\(cur.index).") {
                cur.lines.append(trimmed)
                current = cur
            }
        }
        if let cur = current {
            let content = cur.lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                let idx = cur.index - 1
                results.append((emojis[min(idx, 3)], defaultTitles[min(idx, 3)], content))
            }
        }

        return results
    }
}

struct SectionCard: View {
    let emoji: String
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(emoji)
                Text(title)
                    .font(.subheadline.bold())
            }
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    AIAnalysisView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
