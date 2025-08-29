import Foundation
import SwiftData

@Model
final class FatigueEvent {
    var timestamp: Date
    var state: FatigueState
    
    // --- ADD THESE NEW PROPERTIES ---
    // These will store the raw data from the 2-second window that
    // triggered this event. SwiftData can store arrays of simple types.
    var ecgSnapshot: [Double]
    var eegSnapshot: [Double]
    
    init(timestamp: Date, state: FatigueState, ecgSnapshot: [Double], eegSnapshot: [Double]) {
        self.timestamp = timestamp
        self.state = state
        self.ecgSnapshot = ecgSnapshot
        self.eegSnapshot = eegSnapshot
    }
}
