//
//  WatchViewModel.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import Foundation
import Combine

@MainActor
class WatchViewModel: ObservableObject, WatchSessionManagerDelegate {
    
    // --- Published Properties ---
    @Published var isMonitoringActive = false
    @Published var showAlertView = false
    
    // --- Private Properties ---
    private let ecgManager = ECGHealthKitManager()
    private let sessionManager = WatchSessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // --- Initialization ---
    init() {
        // Set this ViewModel as the delegate for the session manager.
        self.sessionManager.delegate = self
        
        // Subscribe to the ECG data stream from the HealthKit manager.
        ecgManager.ecgPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ecgValues in
                // When new ECG data arrives, send it to the iPhone.
                self?.sendECGDataToPhone(ecgValues)
            }
            .store(in: &cancellables)
    }
    
    // --- Public Methods ---
    
    /// Toggles the monitoring state.
    func toggleMonitoring() {
        isMonitoringActive.toggle()
        
        if isMonitoringActive {
            startSession()
        } else {
            stopSession()
        }
    }
    
    // MARK: - WatchSessionManagerDelegate Conformance
    
    /// Called by the session manager when a message arrives from the iPhone.
    func sessionDidReceiveMessage(message: [String: Any]) {
        // Check for a "fatigueAlert" action from the iPhone.
        if let action = message["action"] as? String, action == "fatigueAlert" {
            didReceiveFatigueAlert()
        }
    }
    
    // --- Private Helper Methods ---
    
    /// Starts the entire monitoring process.
    private func startSession() {
        showAlertView = false // Ensure alert is hidden when starting a new session
        
        // First, request HealthKit authorization.
        ecgManager.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            
            // If authorized, proceed to start everything.
            if authorized {
                print("HealthKit access granted.")
                // Start the HealthKit query to listen for ECGs.
                self.ecgManager.startECGQuery()
                // Send a message to the iPhone to let it know we've started.
                self.sessionManager.send(message: ["action": "startMonitoring"])
            } else {
                print("HealthKit access denied.")
                // If not authorized, we can't monitor. Reset the state.
                self.isMonitoringActive = false
            }
        }
    }
    
    /// Stops the monitoring process.
    private func stopSession() {
        ecgManager.stopECGQuery()
        sessionManager.send(message: ["action": "stopMonitoring"])
        print("Monitoring stopped on watch.")
    }
    
    /// Called when the ViewModel is alerted of a fatigue event.
    private func didReceiveFatigueAlert() {
        print("Received fatigue alert from iPhone!")
        showAlertView = true
    }
    
    /// Sends a batch of ECG data to the connected iPhone.
    private func sendECGDataToPhone(_ values: [Double]) {
        // Only send data if the session is active and the phone is reachable.
        guard isMonitoringActive, sessionManager.isReachable else { return }
        
        let message = ["ecgData": values]
        sessionManager.send(message: message)
    }
}
