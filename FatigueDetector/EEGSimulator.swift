//
//  EEGSimulator.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import Foundation
import Combine

class EEGSimulator: ObservableObject {
    
    // @Published property so the ViewModel can subscribe to its changes.
    @Published var eegData: Double = 0.0
    
    private var timer: Timer?
    private var currentValue: Double = 0.5 // Start in the middle of the range
    
    /// Starts generating simulated EEG data.
    func start() {
        // Invalidate any existing timer to prevent duplicates.
        stop()
        
        // Create a new timer that fires every 0.1 seconds.
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.generateNewDataPoint()
        }
    }
    
    /// Stops generating data.
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateNewDataPoint() {
        // Create a small random change to simulate a wandering signal.
        let change = Double.random(in: -0.05...0.05)
        currentValue += change
        
        // Clamp the value between 0 and 1 to keep it within a range.
        currentValue = max(0.0, min(1.0, currentValue))
        
        // Add a small "drift" to make the signal slowly move up or down.
        currentValue += 0.001
        if currentValue > 1.0 { currentValue = 0.0 }
        
        // Publish the new value.
        eegData = currentValue
    }
}
