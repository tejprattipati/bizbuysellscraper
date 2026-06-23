import SwiftUI

// MARK: - PillarCard

struct PillarCard<Content: View>: View {
    let title: String
    let icon: String
    let completed: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(completed ? .green : .primary)
                Spacer()
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(completed ? .green : .secondary)
            }
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - ProgressBar

struct ProgressBar: View {
    let value: Double  // 0-1
    let color: Color
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(value, 1.0))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - StarRatingView

struct StarRatingView: View {
    @Binding var rating: Int
    let max: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...max, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundColor(i <= rating ? .yellow : .secondary)
                    .onTapGesture { rating = i }
            }
        }
    }
}

// MARK: - ChecklistRow

struct ChecklistRow: View {
    let label: String
    @Binding var checked: Bool

    var body: some View {
        Button(action: { checked.toggle() }) {
            HStack(spacing: 14) {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked ? .green : .secondary)
                    .font(.title3)
                Text(label)
                    .foregroundColor(checked ? .secondary : .primary)
                    .strikethrough(checked)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DayScoreBadge

struct DayScoreBadge: View {
    let score: Int

    var scoreColor: Color {
        switch score {
        case 85...100: return .green
        case 70..<85: return .blue
        case 50..<70: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(scoreColor)
                Text("/ 100")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }
}

#Preview("PillarCard") {
    PillarCard(title: "Morning Launch", icon: "sun.max.fill", completed: true) {
        Text("All tasks done!")
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("ProgressBar") {
    ProgressBar(value: 0.65, color: .indigo, label: "Protein: 91 / 140g")
        .frame(height: 24)
        .padding()
        .preferredColorScheme(.dark)
}
