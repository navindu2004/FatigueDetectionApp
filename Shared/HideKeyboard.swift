// FatigueDetector/FatigueDetector/PreDrive/HideKeyboard.swift

import SwiftUI

#if canImport(UIKit) && !os(watchOS)
extension View {
    /// Dismisses the iOS keyboard by resigning first responder.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#else
// On watchOS (and other platforms), provide a no-op so calls still compile.
extension View {
    func hideKeyboard() { /* no-op on watchOS */ }
}
#endif
