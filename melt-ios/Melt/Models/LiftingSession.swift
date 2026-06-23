import SwiftData
import Foundation

@Model
class LiftingSession {
    var date: Date
    var sessionType: String  // upper/lower/full/core/rest
    var durationMinutes: Int
    var intensity: Int  // 1-5
    var crampsOccurred: Bool
    var crampSeverity: String  // none/mild/moderate/severe
    var notes: String
    var exercisesJSON: String  // JSON-encoded exercise array

    init(sessionType: String) {
        self.date = Date()
        self.sessionType = sessionType
        self.durationMinutes = 0
        self.intensity = 3
        self.crampsOccurred = false
        self.crampSeverity = "none"
        self.notes = ""
        self.exercisesJSON = "[]"
    }
}
