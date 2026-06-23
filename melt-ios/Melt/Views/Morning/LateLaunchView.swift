import SwiftUI
import SwiftData

struct LateLaunchView: View {
    @Environment(\.dismiss) var dismiss
    let log: DailyLog

    @State private var gotUp = false
    @State private var brushed = false
    @State private var showered = false
    @State private var drank = false
    @State private var ateMeal = false
    @State private var startedWork = false

    private var completedCount: Int {
        [gotUp, brushed, showered, drank, ateMeal, startedWork].filter { $0 }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text("Late Launch Mode")
                        .font(.title.bold())
                    Text("Stripped-down. Still counts.")
                        .foregroundColor(.secondary)
                    Text("\(completedCount)/6 done")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
                .padding()

                Divider()

                // Reduced checklist
                List {
                    LateLaunchRow(label: "Get up right now", icon: "figure.stand", checked: $gotUp)
                    LateLaunchRow(label: "Brush teeth", icon: "mouth.fill", checked: $brushed)
                    LateLaunchRow(label: "Shower or rinse", icon: "shower.fill", checked: $showered)
                    LateLaunchRow(label: "Drink 500ml water", icon: "drop.fill", checked: $drank)
                    LateLaunchRow(label: "Eat protein meal", icon: "fork.knife", checked: $ateMeal)
                    LateLaunchRow(label: "Start work block now", icon: "laptopcomputer", checked: $startedWork)
                }
                .listStyle(.plain)

                // Done button
                Button(action: {
                    log.morningRoutineCompleted = completedCount >= 4
                    log.showerCompleted = showered
                    log.brushedTeethMorning = brushed
                    if drank && log.waterLiters == 0 { log.waterLiters = 0.5 }
                    dismiss()
                }) {
                    Text("Save & Continue Day")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(completedCount >= 4 ? Color.indigo : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                }
            }
            .navigationTitle("Late Launch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct LateLaunchRow: View {
    let label: String
    let icon: String
    @Binding var checked: Bool

    var body: some View {
        Button(action: { checked.toggle() }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(checked ? .green : .secondary)
                    .frame(width: 24)
                Text(label)
                    .foregroundColor(checked ? .secondary : .primary)
                    .strikethrough(checked)
                Spacer()
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked ? .green : .secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LateLaunchView(log: DailyLog())
        .preferredColorScheme(.dark)
}
