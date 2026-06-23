import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Today (Dashboard)
            DashboardPlaceholderView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)

            // Tab 2: Nutrition
            NutritionPlaceholderView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(1)

            // Tab 3: AI Coach
            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }
                .tag(2)

            // Tab 4: Training
            TrainingPlaceholderView()
                .tabItem {
                    Label("Training", systemImage: "dumbbell.fill")
                }
                .tag(3)

            // Tab 5: More
            MorePlaceholderView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .tint(.indigo)
    }
}

// MARK: - Placeholder Views (to be replaced by full implementations)

struct DashboardPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)
                Text("Today")
                    .font(.title.bold())
                Text("Daily dashboard coming soon.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Today")
        }
    }
}

struct NutritionPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text("Nutrition")
                    .font(.title.bold())
                Text("Nutrition logging coming soon.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Nutrition")
        }
    }
}

struct TrainingPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text("Training")
                    .font(.title.bold())
                Text("Workout tracking coming soon.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Training")
        }
    }
}

struct MorePlaceholderView: View {
    @AppStorage("claudeAPIKey") private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Claude API") {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                    Text("Required for AI Coach features. Get yours at console.anthropic.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("App") {
                    Label("Version 1.0", systemImage: "info.circle")
                    Label("Melt Summer OS", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
