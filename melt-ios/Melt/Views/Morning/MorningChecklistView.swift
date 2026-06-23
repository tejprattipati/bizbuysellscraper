import SwiftUI
import SwiftData

struct MorningChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @Query private var settings: [UserSettings]
    @State private var showLateLaunch = false

    private var todayLog: DailyLog {
        let today = Calendar.current.startOfDay(for: Date())
        if let log = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return log
        }
        let newLog = DailyLog(date: today)
        modelContext.insert(newLog)
        return newLog
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var completedCount: Int {
        var count = 0
        if todayLog.wakeTime != nil { count += 1 }
        if todayLog.outOfBedTime != nil { count += 1 }
        if todayLog.phoneInBedAvoided { count += 1 }
        if todayLog.brushedTeethMorning { count += 1 }
        if todayLog.showerCompleted { count += 1 }
        if todayLog.sunscreenApplied { count += 1 }
        // water logged
        if todayLog.waterLiters > 0 { count += 1 }
        // high protein breakfast
        if todayLog.meals.first(where: { $0.protein >= 20 }) != nil { count += 1 }
        return count
    }

    private let totalItems = 8

    private var allDone: Bool { completedCount == totalItems }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Streak badge
                    HStack {
                        Label("\(userSettings.morningLaunchStreak) day streak", systemImage: "flame.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(completedCount)/\(totalItems) complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Checklist
                    VStack(spacing: 0) {
                        MorningItemRow(label: "Wake up by \(userSettings.wakeTargetTime)",
                                       icon: "alarm.fill",
                                       isChecked: todayLog.wakeTime != nil) {
                            if todayLog.wakeTime == nil {
                                todayLog.wakeTime = Date()
                            } else {
                                todayLog.wakeTime = nil
                            }
                        }
                        Divider()
                        MorningItemRow(label: "Get out of bed (within \(userSettings.outOfBedGraceMinutes) min)",
                                       icon: "bed.double.fill",
                                       isChecked: todayLog.outOfBedTime != nil) {
                            if todayLog.outOfBedTime == nil {
                                todayLog.outOfBedTime = Date()
                            } else {
                                todayLog.outOfBedTime = nil
                            }
                        }
                        Divider()
                        MorningItemRow(label: "No phone scrolling in bed",
                                       icon: "iphone.slash",
                                       isChecked: todayLog.phoneInBedAvoided) {
                            todayLog.phoneInBedAvoided.toggle()
                        }
                        Divider()
                        MorningItemRow(label: "Brush teeth",
                                       icon: "mouth.fill",
                                       isChecked: todayLog.brushedTeethMorning) {
                            todayLog.brushedTeethMorning.toggle()
                        }
                        Divider()
                        MorningItemRow(label: "Shower or rinse",
                                       icon: "shower.fill",
                                       isChecked: todayLog.showerCompleted) {
                            todayLog.showerCompleted.toggle()
                        }
                        Divider()
                        MorningItemRow(label: "Morning skincare",
                                       icon: "sparkles",
                                       isChecked: todayLog.sunscreenApplied) {
                            todayLog.sunscreenApplied.toggle()
                        }
                        Divider()
                        MorningItemRow(label: "Sunscreen",
                                       icon: "sun.max.fill",
                                       isChecked: todayLog.sunscreenApplied) {
                            todayLog.sunscreenApplied.toggle()
                        }
                        Divider()
                        MorningItemRow(label: "Drink water",
                                       icon: "drop.fill",
                                       isChecked: todayLog.waterLiters > 0) {
                            if todayLog.waterLiters == 0 { todayLog.waterLiters = 0.5 }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Morning Complete button
                    if allDone {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Morning Launch Complete!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(16)
                        .onTapGesture {
                            todayLog.morningRoutineCompleted = true
                        }
                    } else {
                        Button(action: {
                            todayLog.morningRoutineCompleted = true
                        }) {
                            Text("Mark Morning Launch Complete")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.indigo)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }

                    // Late launch mode
                    if hour >= 9 && !todayLog.morningRoutineCompleted {
                        Button(action: { showLateLaunch = true }) {
                            Label("Late Launch Mode", systemImage: "bolt.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Morning")
            .sheet(isPresented: $showLateLaunch) {
                LateLaunchView(log: todayLog)
            }
        }
    }
}

struct MorningItemRow: View {
    let label: String
    let icon: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .secondary)
                    .frame(width: 28)
                Text(label)
                    .foregroundColor(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)
                Spacer()
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .green : .secondary)
                    .font(.title3)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MorningChecklistView()
        .modelContainer(for: [DailyLog.self, UserSettings.self, MealEntry.self, LiftingSession.self, UrgeEntry.self, IBSession.self], inMemory: true)
        .preferredColorScheme(.dark)
}
