import SwiftUI

struct ScheduleBlock: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    let category: String
    let required: Bool
    var completed: Bool = false
}

struct ScheduleView: View {
    @State private var blocks: [ScheduleBlock] = defaultSchedule

    static let defaultSchedule: [ScheduleBlock] = [
        ScheduleBlock(time: "8:00 AM", title: "Wake Up", category: "Sleep", required: true),
        ScheduleBlock(time: "8:00–8:30", title: "Morning Launch: bathroom, brush, skincare, sunscreen", category: "Morning Routine", required: true),
        ScheduleBlock(time: "8:30–9:00", title: "High-Protein Breakfast", category: "Nutrition", required: true),
        ScheduleBlock(time: "9:00–10:30", title: "IB Technicals Deep Work", category: "IB/Study", required: true),
        ScheduleBlock(time: "10:30–11:00", title: "Break / Walk / Internship Check", category: "Admin", required: false),
        ScheduleBlock(time: "11:00–12:15", title: "Lift", category: "Lift", required: true),
        ScheduleBlock(time: "12:15–1:00", title: "Lunch + Shower", category: "Nutrition", required: true),
        ScheduleBlock(time: "1:00–2:00", title: "Secondary IB/Study Block", category: "IB/Study", required: false),
        ScheduleBlock(time: "2:00–3:00", title: "Internship / Admin / Flex Work", category: "Admin", required: false),
        ScheduleBlock(time: "3:00–5:00", title: "Free Block: singing, anime, errands, studio, friends", category: "Fun", required: false),
        ScheduleBlock(time: "5:00–8:00", title: "Basketball / Friends / Volleyball / Dinner Window", category: "Sport", required: false),
        ScheduleBlock(time: "8:00–8:45", title: "Dinner", category: "Nutrition", required: true),
        ScheduleBlock(time: "8:45–9:15", title: "Light Review / Checklist", category: "Admin", required: false),
        ScheduleBlock(time: "9:15–10:30", title: "Guilt-free anime / manga / free time", category: "Fun", required: false),
        ScheduleBlock(time: "10:30–11:15", title: "Shutdown: skincare, plan tomorrow, phone away", category: "Shutdown", required: true),
        ScheduleBlock(time: "11:30", title: "Sleep Target", category: "Sleep", required: true),
    ]

    func categoryColor(_ category: String) -> Color {
        switch category {
        case "Sleep": return .purple
        case "Morning Routine": return .orange
        case "Nutrition": return .green
        case "IB/Study": return .blue
        case "Lift": return .red
        case "Sport": return .cyan
        case "Fun": return .yellow
        case "Admin": return .gray
        case "Shutdown": return .indigo
        default: return .secondary
        }
    }

    private var completedCount: Int { blocks.filter { $0.completed }.count }
    private var requiredCount: Int { blocks.filter { $0.required }.count }
    private var requiredDone: Int { blocks.filter { $0.required && $0.completed }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Summary bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Required: \(requiredDone)/\(requiredCount)")
                                .font(.subheadline.bold())
                            Text("Total: \(completedCount)/\(blocks.count) blocks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        ProgressBar(
                            value: requiredCount > 0 ? Double(requiredDone) / Double(requiredCount) : 0,
                            color: .indigo,
                            label: ""
                        )
                        .frame(width: 100, height: 20)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Timeline
                    LazyVStack(spacing: 0) {
                        ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                            ScheduleBlockRow(
                                block: block,
                                color: categoryColor(block.category),
                                isLast: index == blocks.count - 1,
                                onToggle: {
                                    blocks[index].completed.toggle()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Schedule")
        }
    }
}

struct ScheduleBlockRow: View {
    let block: ScheduleBlock
    let color: Color
    let isLast: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(block.completed ? .green : color)
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)
                if !isLast {
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            // Content
            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(block.time)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            if block.required {
                                Text("required")
                                    .font(.caption2)
                                    .foregroundColor(color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(color.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            Image(systemName: block.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(block.completed ? .green : .secondary)
                        }
                    }
                    Text(block.title)
                        .font(.subheadline)
                        .foregroundColor(block.completed ? .secondary : .primary)
                        .strikethrough(block.completed)
                        .multilineTextAlignment(.leading)
                    Text(block.category)
                        .font(.caption2)
                        .foregroundColor(color)
                        .padding(.bottom, 4)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, isLast ? 20 : 0)
    }
}

#Preview {
    ScheduleView()
        .preferredColorScheme(.dark)
}
