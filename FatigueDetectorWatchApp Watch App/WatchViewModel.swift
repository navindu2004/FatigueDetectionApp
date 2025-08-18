import Foundation
import Combine

@MainActor
class WatchViewModel: ObservableObject, WatchSessionManagerDelegate {
    
    @Published var isMonitoringActive = false
    @Published var showAlertView = false
    
    private let ecgSimulator = ECGSimulator()
    private let sessionManager = WatchSessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.sessionManager.delegate = self
        
        ecgSimulator.ecgFeaturePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ecgFeatures in
                self?.sendECGFeaturesToPhone(ecgFeatures)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Actions
    func toggleMonitoring() {
        let action = isMonitoringActive ? "stopMonitoring" : "startMonitoring"
        print("--- [WATCH LOG] --- 1. User tapped button. Sending '\(action)' to iPhone.")
        sessionManager.send(message: ["action": action])
    }
    
    // MARK: - SessionManagerDelegate
    func sessionDidReceiveMessage(message: [String: Any]) {
        
        // --- THIS IS THE NEW LOGIC ---
        // First, check if the message is a log message and print it.
        if let logMessage = message["log"] as? String {
            print(logMessage)
        }
        
        // Then, handle any actions in the message.
        if let action = message["action"] as? String {
            switch action {
            case "fatigueAlert":
                print("--- [WATCH LOG] --- 5. Received 'fatigueAlert' from iPhone. Showing alert.")
                self.showAlertView = true
            case "confirmStart":
                let simulateFatigue = message["simulateFatigue"] as? Bool ?? false
                print("--- [WATCH LOG] --- 3. Received 'confirmStart' from iPhone. Fatigue Mode: \(simulateFatigue)")
                self.startSession(simulateFatigue: simulateFatigue)
            case "confirmStop":
                print("--- [WATCH LOG] --- Received 'confirmStop' from iPhone.")
                self.stopSession()
            default:
                break
            }
        }
    }
    
    // MARK: - Session Control
    private func startSession(simulateFatigue: Bool) {
        isMonitoringActive = true
        showAlertView = false
        ecgSimulator.start(simulateFatigue: simulateFatigue)
    }

    private func stopSession() {
        isMonitoringActive = false
        ecgSimulator.stop()
    }
    
    private func sendECGFeaturesToPhone(_ features: [String: Double]) {
        guard isMonitoringActive, sessionManager.isReachable else { return }
        print("--- [WATCH LOG] --- 4. Sending ECG features to iPhone.")
        let message: [String: Any] = ["ecgFeatures": features]
        sessionManager.send(message: message)
    }
}
