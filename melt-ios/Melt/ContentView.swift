import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [UserSettings]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MainTabView()
            .preferredColorScheme(.dark)
            .onAppear {
                if settings.isEmpty {
                    let defaultSettings = UserSettings()
                    modelContext.insert(defaultSettings)
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
}
