import SwiftUI
import SwiftData

struct SalvageModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var allLogs: [DailyLog]

    @State private var checkedItems: Set<Int> = []
    @State private var showConfirmation = false

    private var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
    }

    private var items: [(String, Bool)] {
        let log = todayLog
        return [
            ("Shower or rinse", log?.showerCompleted ?? false),
            ("Brush teeth", log?.brushedTeethMorning ?? false),
            ("Drink 500ml water", (log?.waterLiters ?? 0) > 0),
            ("Hit 120g protein minimum", (log?.proteinGrams ?? 0) >= 120),
            ("Stay in calorie range", (log?.calories ?? 0) > 0),
            ("Complete 60 min IB block", (log?.ibMinutes ?? 0) >= 60),
            ("One movement session", (log?.lifted ?? false) || (log?.movementMinutes ?? 0) >= 20),
            ("No porn/masturbation rest of day", (log?.pornAvoided ?? true) && (log?.masturbationAvoided ?? true)),
            ("No phone in bed tonight", log?.phoneInBedAvoided ?? true),
            ("Night skincare", log?.nightRoutineCompleted ?? false),
            ("Sleep before midnight", true)  // user must confirm
        ]
    }

    private var completedFromLog: Int {
        items.filter { $0.1 }.count
    }

    private var totalChecked: Int {
        checkedItems.count + completedFromLog
    }

    private var canMarkSalvaged: Bool {
        totalChecked >= 7
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Salvage Mode")
                            .font(.title.bold())
                        Text("Do the minimum. Don't spiral.")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("You're behind, not cooked.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(totalChecked)/\(items.count) items")
                                .font(.headline)
                            Spacer()
                            Text(canMarkSalvaged ? "Enough to salvage!" : "\(7 - totalChecked) more to salvage")
                                .font(.caption)
                                .foregroundColor(canMarkSalvaged ? .green : .secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2))
                                RoundedRectangle(cornerRadius: 6).fill(canMarkSalvaged ? Color.green : Color.orange)
                                    .frame(width: geo.size.width * min(Double(totalChecked) / Double(items.count), 1.0))
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Checklist
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            let alreadyDone = item.1
                            let checked = alreadyDone || checkedItems.contains(index)

                            Button(action: {
                                guard !alreadyDone else { return }
                                if checkedItems.contains(index) {
                                    checkedItems.remove(index)
                                } else {
                                    checkedItems.insert(index)
                                }
                            }) {
                                HStack(spacing: 14) {
                                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(checked ? .green : .secondary)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.0)
                                            .foregroundColor(checked ? .secondary : .primary)
                                            .strikethrough(checked)
                                        if alreadyDone {
                                            Text("Already done")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .disabled(alreadyDone)

                            if index < items.count - 1 { Divider() }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Mark salvaged button
                    if canMarkSalvaged {
                        Button(action: { showConfirmation = true }) {
                            Label("Mark Day as Salvaged", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }

                    Text("Minimum viable day still counts. Every item matters.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Salvage Mode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Mark as Salvaged?", isPresented: $showConfirmation) {
                Button("Yes, Salvaged") {
                    if let log = todayLog {
                        log.dayStatus = "salvaged"
                        log.salvageModeActivated = true
                        log.salvageCompleted = true
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You completed \(totalChecked) of \(items.count) salvage items. The day is saved.")
            }
        }
    }
}

#Preview {
    SalvageModeView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
