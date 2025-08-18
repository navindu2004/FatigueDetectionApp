import Foundation
import SwiftData

@Model
final class FatigueEvent {
    var timestamp: Date
    // We can now store the enum directly, SwiftData will handle it.
    var state: FatigueState
    
    init(timestamp: Date, state: FatigueState) {
        self.timestamp = timestamp
        self.state = state
    }
}
