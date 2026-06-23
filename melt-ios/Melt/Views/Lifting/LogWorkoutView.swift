import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let log: DailyLog

    @State private var sessionType = "upper"
    @State private var duration = 60
    @State private var intensity = 3
    @State private var crampsOccurred = false
    @State private var crampSeverity = "none"
    @State private var notes = ""
    @State private var exerciseNotes = ""

    let sessionTypes = ["upper", "lower", "full", "core", "rest"]
    let crampOptions = ["none", "mild", "moderate", "severe"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    Picker("Type", selection: $sessionType) {
                        ForEach(sessionTypes, id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    Stepper("Duration: \(duration) min", value: $duration, in: 10...180, step: 5)
                    VStack(alignment: .leading) {
                        Text("Intensity: \(intensity)/5")
                        Slider(value: Binding(
                            get: { Double(intensity) },
                            set: { intensity = Int($0) }
                        ), in: 1...5, step: 1)
                        .tint(.red)
                    }
                }

                Section("Cramping") {
                    Toggle("Cramps Occurred", isOn: $crampsOccurred)
                    if crampsOccurred {
                        Picker("Severity", selection: $crampSeverity) {
                            ForEach(crampOptions, id: \.self) { s in
                                Text(s.capitalized).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Exercises") {
                    TextField("Exercises / notes (optional)", text: $exerciseNotes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Section("Session Notes") {
                    TextField("How did it go?", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let session = LiftingSession(sessionType: sessionType)
                        session.durationMinutes = duration
                        session.intensity = intensity
                        session.crampsOccurred = crampsOccurred
                        session.crampSeverity = crampsOccurred ? crampSeverity : "none"
                        session.notes = notes
                        session.exercisesJSON = exerciseNotes.isEmpty ? "[]" : "[\"\(exerciseNotes)\"]"
                        log.liftingSessions.append(session)
                        log.lifted = true
                        log.liftType = sessionType
                        log.legCramping = crampsOccurred ? crampSeverity : "none"
                        log.movementMinutes = max(log.movementMinutes, duration)
                        modelContext.insert(session)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LogWorkoutView(log: DailyLog())
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
