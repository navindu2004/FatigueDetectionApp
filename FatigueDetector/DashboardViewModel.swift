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
    private let eegSimulator = EEGSimulator()
    private let fatigueClassifier = FatigueClassifier()
    private let workoutManager = WorkoutManager() // The new manager
    private let permissionManager = ECGHealthKitManager() // For permissions only
    private var cancellables = Set<AnyCancellable>()
    
    private var ecgBuffer: [Double] = []
    private var eegBuffer: [Double] = []
    private var processingTimer: Timer?
    
    private let windowSizeInSeconds = 2.0
    private let requiredSamples = 20 // We'll assume EEG and ECG now arrive at the same rate for simplicity
    
    init() {
        self.sessionManager.delegate = self
        
        sessionManager.$isReachable
            .receive(on: DispatchQueue.main)
            .assign(to: \.isWatchConnected, on: self)
            .store(in: &cancellables)
            
        eegSimulator.$eegData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDataPoint in self?.addNewEEGDataPoint(newDataPoint) }
            .store(in: &cancellables)
            
        // Subscribe to the ECG data coming from the new WorkoutManager
        workoutManager.ecgPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ecgValues in self?.addNewECGDataPoints(ecgValues) }
            .store(in: &cancellables)
            
        // Request permission as soon as the app launches
        permissionManager.requestAuthorization { _ in }
    }
    
    // MARK: - SessionManagerDelegate
    func sessionDidReceiveMessage(message: [String: Any]) {
        if let action = message["action"] as? String {
            switch action {
            case "startMonitoring":
                startSession()
            case "stopMonitoring":
                stopSession()
            default:
                break
            }
        }
    }
    
    private func startSession() {
        print("Start session message received from watch.")
        isMonitoringActive = true
        fatigueLevel = .awake
        ecgDataPoints.removeAll(); eegDataPoints.removeAll()
        ecgBuffer.removeAll(); eegBuffer.removeAll()
        
        workoutManager.startWorkout() // Start the workout on the phone
        eegSimulator.start()
        
        processingTimer = Timer.scheduledTimer(withTimeInterval: windowSizeInSeconds, repeats: true) { [weak self] _ in
            self?.processDataWindow()
        }
    }
    
    private func stopSession() {
        print("Stop session message received from watch.")
        isMonitoringActive = false
        workoutManager.stopWorkout()
        eegSimulator.stop()
        processingTimer?.invalidate()
        processingTimer = nil
    }
    
    private func processDataWindow() {
        guard ecgBuffer.count >= requiredSamples, eegBuffer.count >= requiredSamples else {
            return
        }
        
        let ecgWindow = Array(ecgBuffer.suffix(requiredSamples))
        let eegWindow = Array(eegBuffer.suffix(requiredSamples))
        
        var features: [String: Double] = [:]
        let allSignalNames = ["ECG", "Poz", "Fz", "Cz", "C3", "C4", "F3", "F4", "P3", "P4", "HR"]
        for signalName in allSignalNames {
            let dataWindow: [Double]
            if signalName == "ECG" { dataWindow = ecgWindow }
            else if signalName == "Poz" { dataWindow = eegWindow }
            else { dataWindow = Array(repeating: 0.0, count: requiredSamples) }
            
            features["\(signalName)_mean"] = dataWindow.mean()
            features["\(signalName)_std"] = dataWindow.std()
            features["\(signalName)_max"] = dataWindow.max() ?? 0.0
            features["\(signalName)_min"] = dataWindow.min() ?? 0.0
        }
        
        let prediction = fatigueClassifier.predict(features: features)
        self.fatigueLevel = prediction
        
        if prediction == .fatigued {
            sessionManager.send(message: ["action": "fatigueAlert"])
        }
        
        ecgBuffer.removeFirst(ecgBuffer.count - requiredSamples)
        eegBuffer.removeFirst(eegBuffer.count - requiredSamples)
    }

    private func addNewECGDataPoints(_ points: [Double]) {
        guard isMonitoringActive else { return }
        ecgBuffer.append(contentsOf: points)
        ecgDataPoints.append(contentsOf: points)
        if ecgDataPoints.count > 100 {
            ecgDataPoints.removeFirst(ecgDataPoints.count - 100)
        }
    }
    
    private func addNewEEGDataPoint(_ point: Double) {
        guard isMonitoringActive else { return }
        eegBuffer.append(point)
        eegDataPoints.append(point)
        if eegDataPoints.count > 100 {
            eegDataPoints.removeFirst()
        }
    }
}

// Simple extensions (keep these at the bottom)
extension Array where Element == Double {
    func mean() -> Double {
        guard !self.isEmpty else { return 0.0 }
        return self.reduce(0, +) / Double(self.count)
    }
    
    func std() -> Double {
        guard self.count > 1 else { return 0.0 }
        let meanValue = self.mean()
        let sumOfSquaredDiffs = self.reduce(0) { $0 + ($1 - meanValue) * ($1 - meanValue) }
        return sqrt(sumOfSquaredDiffs / Double(self.count - 1))
    }
}
