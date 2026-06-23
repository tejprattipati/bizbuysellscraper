import SwiftUI
import SwiftData

struct UrgeModeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]

    @State private var timeRemaining = 600
    @State private var timerActive = false
    @State private var stepsDone: Set<Int> = []
    @State private var showOutcome = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let steps = [
        "Stand up right now.",
        "Put the phone face-down on a table.",
        "Drink a full glass of water.",
        "Do 20 pushups.",
        "Open the door. Go to a public area.",
        "Start this timer.",
        "Do not negotiate. Do not go back to bed."
    ]

    private var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }

                VStack(spacing: 8) {
                    Text("LEAVE THE ROOM.")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                    Text("DO NOT THINK IN BED.")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                }

                // Timer circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / 600)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)

                    VStack {
                        Text(timeString(timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("minutes")
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 160, height: 160)

                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Button(action: {
                            if stepsDone.contains(index) {
                                stepsDone.remove(index)
                            } else {
                                stepsDone.insert(index)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: stepsDone.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(stepsDone.contains(index) ? .green : .gray)
                                Text(step)
                                    .foregroundColor(stepsDone.contains(index) ? .gray : .white)
                                    .strikethrough(stepsDone.contains(index))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                if !timerActive {
                    Button("Start 10-Minute Timer") {
                        timerActive = true
                        stepsDone.insert(5)  // auto-check "start timer"
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
        .onReceive(timer) { _ in
            guard timerActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerActive = false
                showOutcome = true
            }
        }
        .sheet(isPresented: $showOutcome) {
            OutcomeSheet(log: todayLog) {
                showOutcome = false
                dismiss()
            }
        }
    }

    func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct OutcomeSheet: View {
    @Environment(\.modelContext) private var modelContext
    let log: DailyLog?
    let onDone: () -> Void

    @State private var trigger = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("10 minutes done.")
                    .font(.title.bold())
                Text("How did it go?")
                    .foregroundColor(.secondary)

                TextField("What triggered this? (optional)", text: $trigger)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button(action: {
                    logUrge(outcome: "resisted")
                    onDone()
                }) {
                    Label("I resisted. Moving on.", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    logUrge(outcome: "relapsed")
                    onDone()
                }) {
                    Label("I need to log a relapse.", systemImage: "exclamationmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }

                Text("No shame. Continue the day.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Outcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func logUrge(outcome: String) {
        guard let log = log else { return }
        let urge = UrgeEntry(intensity: 7, trigger: trigger)
        urge.outcome = outcome
        urge.actionTaken = "Used Urge Mode protocol"
        log.urges.append(urge)
        modelContext.insert(urge)
        if outcome == "relapsed" {
            log.relapseOccurred = true
        }
    }
}

#Preview {
    UrgeModeView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
}
