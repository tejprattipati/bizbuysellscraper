import SwiftUI
import SwiftData

struct AICoachView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("AI Coach", selection: $selectedTab) {
                Text("Analysis").tag(0)
                Text("Chat").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))

            // Content
            TabView(selection: $selectedTab) {
                AIAnalysisView()
                    .tag(0)
                ChatbotView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    AICoachView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
