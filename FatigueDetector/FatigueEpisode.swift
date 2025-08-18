import Foundation
import SwiftData

@Model
final class FatigueEpisode {
    // Identity
    @Attribute(.unique) var id: UUID = UUID()
    
    // Timing
    var startedAt: Date
    var endedAt: Date?          // nil while ongoing
    
    // Stats
    var avgProb: Double         // filled on end
    var maxProb: Double         // track peak probability
    var frames: Int             // how many frames contributed to stats
    
    // Context / metadata (handy in History)
    var onThreshold: Double
    var offThreshold: Double
    var consecOnNeeded: Int
    var consecOffNeeded: Int
    var simulated: Bool         // whether this run was in simulator mode
    
    init(startedAt: Date,
         onThreshold: Double,
         offThreshold: Double,
         consecOnNeeded: Int,
         consecOffNeeded: Int,
         simulated: Bool)
    {
        self.startedAt = startedAt
        self.endedAt = nil
        self.avgProb = 0
        self.maxProb = 0
        self.frames = 0
        self.onThreshold = onThreshold
        self.offThreshold = offThreshold
        self.consecOnNeeded = consecOnNeeded
        self.consecOffNeeded = consecOffNeeded
        self.simulated = simulated
    }
}

extension FatigueEpisode {
    var isActive: Bool { endedAt == nil }
    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }
}
