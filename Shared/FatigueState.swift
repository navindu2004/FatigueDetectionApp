import Foundation
import SwiftUI

enum FatigueState: String, Codable, CaseIterable {
    case awake
    case fatigued

    var displayText: String {
        switch self {
        case .awake:    return "Awake"
        case .fatigued: return "Fatigued"
        }
    }

    /// Fallback color if you don't want probability-based coloring.
    var displayColor: Color {
        switch self {
        case .awake:    return .green
        case .fatigued: return .red
        }
    }
}
