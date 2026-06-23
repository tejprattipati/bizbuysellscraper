import SwiftData
import Foundation

@Model
class IBSession {
    var date: Date
    var plannedTopic: String
    var actualMinutes: Int
    var completedTasks: String  // newline separated
    var confidenceScore: Int  // 1-5
    var notes: String

    init() {
        self.date = Date()
        self.plannedTopic = ""
        self.actualMinutes = 0
        self.completedTasks = ""
        self.confidenceScore = 3
        self.notes = ""
    }
}
