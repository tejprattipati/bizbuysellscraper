import SwiftUI
import SwiftData

struct NightShutdownView: View {
    let log: DailyLog

    @State private var stoppedIntenseWork = false
    @State private var stoppedAnime = false
    @State private var phonePutAway = false
    @State private var plannedTomorrow = false

    private var completedCount: Int {
        [stoppedIntenseWork,
         stoppedAnime,
         log.nightCleanser,
         log.brushedTeethMorning,
         plannedTomorrow,
         phonePutAway].filter { $0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Night Shutdown Checklist")
                    .font(.headline)
                Spacer()
                Text("\(completedCount)/6")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }

            VStack(spacing: 0) {
                ChecklistRow(label: "Stop intense work", checked: $stoppedIntenseWork)
                Divider()
                ChecklistRow(label: "Stop anime/manga by 10:30 PM", checked: $stoppedAnime)
                Divider()
                ChecklistRow(label: "Night skincare", checked: Binding(
                    get: { log.nightCleanser },
                    set: { log.nightCleanser = $0 }
                ))
                Divider()
                ChecklistRow(label: "Brush teeth", checked: Binding(
                    get: { log.brushedTeethMorning },
                    set: { log.brushedTeethMorning = $0 }
                ))
                Divider()
                ChecklistRow(label: "Plan top 3 tasks for tomorrow", checked: $plannedTomorrow)
                Divider()
                ChecklistRow(label: "Phone away", checked: $phonePutAway)
            }

            if completedCount == 6 {
                Label("Shutdown complete. Good night.", systemImage: "moon.stars.fill")
                    .foregroundColor(.indigo)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(8)
                    .onAppear {
                        log.nightRoutineCompleted = true
                    }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    NightShutdownView(log: DailyLog())
        .padding()
        .preferredColorScheme(.dark)
}
