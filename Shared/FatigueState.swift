import Foundation
import SwiftUI

enum FatigueState {
    case awake
    case drowsy
    case fatigued
    
    var displayText: String {
        switch self {
        case .awake: "Awake"
        case .drowsy: "Drowsy"
        case .fatigued: "Fatigued"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .awake: .green
        case .drowsy: .yellow
        case .fatigued: .red
        }
    }
}
