import SwiftData
import Foundation

@Model
class DailyLog {
    var date: Date
    var wakeTime: Date?
    var outOfBedTime: Date?
    var sleptAtTime: Date?
    var sleepQuality: Int = 0  // 1-5

    // Morning routine
    var morningRoutineCompleted: Bool = false
    var showerCompleted: Bool = false
    var brushedTeethMorning: Bool = false
    var sunscreenApplied: Bool = false
    var sunscreenReapplied: Bool = false

    // Night routine
    var nightRoutineCompleted: Bool = false
    var nightCleanser: Bool = false
    var acneTreatmentCompleted: Bool = false
    var nightMoisturizer: Bool = false
    var pillowcaseChanged: Bool = false
    var acneSeverity: Int = 0  // 1-5

    // Nutrition
    var calories: Int = 0
    var proteinGrams: Int = 0
    var waterLiters: Double = 0

    // Training
    var lifted: Bool = false
    var liftType: String = "none"  // upper/lower/full/core/rest
    var sportPlayed: String = "none"  // basketball/volleyball/walk/rollerblade/none/other
    var movementMinutes: Int = 0
    var legCramping: String = "none"  // none/mild/moderate/severe

    // IB
    var ibMinutes: Int = 0
    var ibTopic: String = ""
    var ibNotes: String = ""
    var ibConfidence: Int = 0  // 1-5

    // Fun
    var singingMinutes: Int = 0
    var animeMinutes: Int = 0
    var funActivityCompleted: Bool = false
    var funActivityDescription: String = ""

    // Discipline
    var pornAvoided: Bool = true
    var masturbationAvoided: Bool = true
    var phoneInBedAvoided: Bool = true
    var bedRottingAvoided: Bool = true
    var relapseOccurred: Bool = false
    var relapseType: String = ""  // porn/masturbation/both

    // Meta
    var mood: Int = 0  // 1-5
    var energy: Int = 0  // 1-5
    var notes: String = ""
    var dayStatus: String = "in-progress"  // ideal/minimum/salvaged/missed/in-progress
    var salvageModeActivated: Bool = false
    var salvageCompleted: Bool = false
    var nutritionScreenshotAnalyzed: Bool = false

    @Relationship(deleteRule: .cascade) var meals: [MealEntry] = []
    @Relationship(deleteRule: .cascade) var urges: [UrgeEntry] = []
    @Relationship(deleteRule: .cascade) var liftingSessions: [LiftingSession] = []
    @Relationship(deleteRule: .cascade) var ibSessions: [IBSession] = []

    init(date: Date = Date()) {
        self.date = Calendar.current.startOfDay(for: date)
    }
}
