import SwiftUI
import SwiftData

struct AntyCrampCheckView: View {
    let log: DailyLog

    @State private var drankWater = false
    @State private var ateFood = false
    @State private var hadSodium = false
    @State private var warmedUp = false
    @State private var startingLight = false

    private var readyToLift: Bool {
        drankWater && ateFood && warmedUp
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(.orange)
                Text("Anti-Cramp Checklist")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                ChecklistRow(label: "Drank water (500ml+)", checked: $drankWater)
                Divider()
                ChecklistRow(label: "Ate food before session", checked: $ateFood)
                Divider()
                ChecklistRow(label: "Had sodium / electrolytes", checked: $hadSodium)
                Divider()
                ChecklistRow(label: "Warmed up properly", checked: $warmedUp)
                Divider()
                ChecklistRow(label: "Starting light / controlled", checked: $startingLight)
            }

            if readyToLift {
                Label("Good to go. Start light.", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else {
                Label("Complete checklist before heavy sets.", systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }

            // Cramp severity logger
            VStack(alignment: .leading, spacing: 6) {
                Text("Cramping during session?")
                    .font(.subheadline)
                Picker("Cramp Severity", selection: Binding(
                    get: { log.legCramping },
                    set: { log.legCramping = $0 }
                )) {
                    Text("None").tag("none")
                    Text("Mild").tag("mild")
                    Text("Moderate").tag("moderate")
                    Text("Severe").tag("severe")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    AntyCrampCheckView(log: DailyLog())
        .padding()
        .preferredColorScheme(.dark)
}
