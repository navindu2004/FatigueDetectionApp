//
//  DashboardViewModel.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject, SessionManagerDelegate {
    
    @Published var isWatchConnected = false
    @Published var isMonitoringActive = false
    @Published var fatigueLevel: FatigueState = .awake
    @Published var ecgDataPoints: [Double] = []
    @Published var eegDataPoints: [Double] = []
    
    private let sessionManager = SessionManager.shared
    private let eegSimulator = EEGSimulator() // This will now be found
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.sessionManager.delegate = self
        
        sessionManager.$isReachable
            .receive(on: DispatchQueue.main)
            .assign(to: \.isWatchConnected, on: self)
            .store(in: &cancellables)
            
        eegSimulator.$eegData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDataPoint in
                self?.addNewEEGDataPoint(newDataPoint)
            }
            .store(in: &cancellables)
    }
    
    func startMonitoring() {
        guard isWatchConnected else {
            print("Cannot start monitoring: Watch is not connected.")
            return
        }
        
        print("Starting monitoring session...")
        isMonitoringActive = true
        
        ecgDataPoints.removeAll()
        eegDataPoints.removeAll()
        
        sessionManager.send(message: ["action": "startMonitoring"])
        eegSimulator.start()
    }
    
    func stopMonitoring() {
        print("Stopping monitoring session...")
        isMonitoringActive = false
        
        sessionManager.send(message: ["action": "stopMonitoring"])
        eegSimulator.stop()
    }
    
    func sessionDidReceiveMessage(message: [String: Any]) {
        if let ecgValues = message["ecgData"] as? [Double] {
            addNewECGDataPoints(ecgValues)
        }
    }
    
    private func addNewECGDataPoints(_ points: [Double]) {
        guard isMonitoringActive else { return }
        ecgDataPoints.append(contentsOf: points)
        if ecgDataPoints.count > 100 {
            ecgDataPoints.removeFirst(ecgDataPoints.count - 100)
        }
    }
    
    private func addNewEEGDataPoint(_ point: Double) {
        guard isMonitoringActive else { return }
        eegDataPoints.append(point)
        if eegDataPoints.count > 100 {
            eegDataPoints.removeFirst(eegDataPoints.count - 100)
        }
    }
}

enum FatigueState {
    case awake, drowsy, fatigued
    
    var displayText: String {
        switch self {
        case .awake: "Awake"
        case .drowsy: "Drowsy"
        case .fatigued: "Fatigued" // FIXED: Was 'fatigue', now 'fatigued'
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
