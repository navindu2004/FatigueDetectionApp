import Foundation

@MainActor
class WatchViewModel: ObservableObject, WatchSessionManagerDelegate {
    @Published var isMonitoringActive = false
    @Published var showAlertView = false
    
    private let sessionManager = WatchSessionManager.shared
    
    init() {
        self.sessionManager.delegate = self
    }
    
    func toggleMonitoring() {
        isMonitoringActive.toggle()
        
        let action = isMonitoringActive ? "startMonitoring" : "stopMonitoring"
        print("Watch sending action: \(action)")
        sessionManager.send(message: ["action": action])
    }
    
    func sessionDidReceiveMessage(message: [String: Any]) {
        if let action = message["action"] as? String, action == "fatigueAlert" {
            showAlertView = true
        }
    }
}
