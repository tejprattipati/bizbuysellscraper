import SwiftData
import Foundation

@Model
class UrgeEntry {
    var time: Date
    var intensity: Int  // 1-10
    var trigger: String
    var actionTaken: String
    var outcome: String  // resisted/relapsed/delayed

    init(intensity: Int, trigger: String) {
        self.time = Date()
        self.intensity = intensity
        self.trigger = trigger
        self.actionTaken = ""
        self.outcome = "resisted"
    }
}
