import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject, SessionManagerDelegate {
    
    // MARK: - Published Properties
    @Published var isWatchConnected = false
    @Published var isMonitoringActive = false
    @Published var fatigueLevel: FatigueState = .awake
    @Published var ecgChartData: [ChartDataPoint] = []
    @Published var eegChartData: [ChartDataPoint] = []
    @Published var isFatigueSimulationActive = false
    @Published var fatigueProbability: Double = 0.0
    
    // MARK: - Core Logic Properties
    private let sessionManager = SessionManager.shared
    private let eegSimulator = EEGSimulator()
    private let fatigueClassifier = FatigueClassifier()
    private var cancellables = Set<AnyCancellable>()
    
    var modelContext: ModelContext?
    
    // MARK: - UI helpers
    var fatigueTrafficColor: Color {
        switch fatigueProbability {
        case ..<0.40:     return .green
        case 0.40..<0.60: return .yellow
        default:          return .red
        }
    }
    
    // MARK: - Feature buffers
    private var latestECGFeatures: [String: Double] = [:]
    private var latestEEGFeatures: [String: Double] = [:]
    
    // MARK: - Prediction / concurrency
    private var isPredicting = false
    
    // MARK: - Hysteresis / episode tracking
    private let fatigueOnThreshold: Double  = 0.70
    private let fatigueOffThreshold: Double = 0.40
    private let consecOnNeeded = 2
    private let consecOffNeeded = 2
    private var consecutiveOn = 0
    private var consecutiveOff = 0
    private var fatigueEpisodeActive = false
    private var ecgBuffer: [Double] = []
    private var eegBuffer: [Double] = []
    private let requiredSamples = 100
    
    // Alert cooldown
    private var lastAlertDate: Date?
    private let minSecondsBetweenAlerts: TimeInterval = 15
    
    // Episode stats (optional, for DB/logging)
    private var episodeProbs: [Double] = []
    
    // MARK: - Logging control
    private let verboseLogs = true
    
    // MARK: - Initialization
    init() {
        self.sessionManager.delegate = self
        
        sessionManager.$isReachable
            .receive(on: DispatchQueue.main)
            .assign(to: \.isWatchConnected, on: self)
            .store(in: &cancellables)
            
        eegSimulator.$eegFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newFeatures in
                guard let self = self, !newFeatures.isEmpty else { return }
                
                self.logToWatch("--- [PHONE LOG] --- A. Received new EEG features from local simulator.")
                self.latestEEGFeatures = newFeatures
                
                let chartPoint = ChartDataPoint(timestamp: Date(), value: newFeatures["Poz_mean"] ?? 0.0)
                self.eegChartData.append(chartPoint)
                if self.eegChartData.count > 200 {
                    self.eegChartData.removeFirst()
                }
                
                self.processFeatures()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - SessionManagerDelegate
    func sessionDidReceiveMessage(message: [String: Any]) {
        if let action = message["action"] as? String {
            switch action {
            case "startMonitoring":
                logToWatch("--- [PHONE LOG] --- 2. Received 'startMonitoring' from Watch.")
                guard !isMonitoringActive else {
                    sessionManager.send(message: ["action": "confirmStart", "simulateFatigue": isFatigueSimulationActive])
                    return
                }
                self.startSession()
                
            case "stopMonitoring":
                logToWatch("--- [PHONE LOG] --- Received 'stopMonitoring' from Watch.")
                guard isMonitoringActive else {
                    sessionManager.send(message: ["action": "confirmStop"])
                    return
                }
                self.stopSession()
                
            default:
                break
            }
        }
        
        if let ecgFeatures = message["ecgFeatures"] as? [String: Double] {
            logToWatch("--- [PHONE LOG] --- B. Received new ECG features from Watch.")
            self.latestECGFeatures = ecgFeatures
            let chartPoint = ChartDataPoint(timestamp: Date(), value: ecgFeatures["ECG_mean"] ?? 0.0)
            self.ecgChartData.append(chartPoint)
            if self.ecgChartData.count > 200 {
                self.ecgChartData.removeFirst(self.ecgChartData.count - 200)
            }
        }
    }
    
    // MARK: - Session Control
    private func startSession() {
        guard isWatchConnected else { return }
        isMonitoringActive = true
        fatigueLevel = .awake
        fatigueProbability = 0
        ecgChartData.removeAll(); eegChartData.removeAll()
        latestECGFeatures.removeAll(); latestEEGFeatures.removeAll()

        // reset hysteresis/episode for immediate response to the toggle
        resetHysteresis()
        fatigueEpisodeActive = false

        logToWatch("--- [PHONE LOG] --- Starting simulators. Fatigue Mode: \(isFatigueSimulationActive)")
        eegSimulator.start(simulateFatigue: isFatigueSimulationActive)
        sessionManager.send(message: ["action": "confirmStart", "simulateFatigue": isFatigueSimulationActive])
    }

    private func stopSession() {
        isMonitoringActive = false
        eegSimulator.stop()
        endEpisodeIfNeeded(reason: "session stopped")
        sessionManager.send(message: ["action": "confirmStop"])
    }
    
    // MARK: - Core Logic
    private func processFeatures() {
        logToWatch("--- [PHONE LOG] --- C. Attempting to process features.")
        guard isMonitoringActive, !latestECGFeatures.isEmpty, !latestEEGFeatures.isEmpty else { return }

        logToWatch("--- [PHONE LOG] --- D. All data present. Preparing feature vector.")

        // ECG pieces you likely have from watch
        let ECG_std  = latestECGFeatures["ECG_std"]  ?? 0
        let ECG_max  = latestECGFeatures["ECG_max"]  ?? 0
        let HR_mean  = latestECGFeatures["HR_mean"]  ?? (latestECGFeatures["ECG_hr"] ?? 0)

        // EEG proxies based on Poz_* so we don't feed zeros
        let eeg = eegProxies(from: latestEEGFeatures)

        // Build the EXACT 12 keys in the order your CoreML model expects
        var modelFeatures: [String: Double] = [
            "C3_std":  eeg["C3_std"]  ?? 0,
            "ECG_std": ECG_std,
            "C3_max":  eeg["C3_max"]  ?? 0,
            "C3_min":  eeg["C3_min"]  ?? 0,
            "Cz_std":  eeg["Cz_std"]  ?? 0,
            "P3_std":  eeg["P3_std"]  ?? 0,
            "P4_std":  eeg["P4_std"]  ?? 0,
            "P3_min":  eeg["P3_min"]  ?? 0,
            "Poz_min": eeg["Poz_min"] ?? 0,
            "F3_max":  eeg["F3_max"]  ?? 0,
            "ECG_max": ECG_max,
            "HR_mean": HR_mean
        ]

        // Step 2 overrides — only when simulating fatigue
        if isFatigueSimulationActive {
            // FATIGUED look
            logToWatch("--- [PHONE LOG] --- D2. Applied FATIGUED overrides to feature vector.")
            modelFeatures["C3_std"]  = 0.55
            modelFeatures["P3_std"]  = 0.55
            modelFeatures["P4_std"]  = 0.55
            modelFeatures["C3_min"]  = -1.20
            modelFeatures["P3_min"]  = -1.20
            modelFeatures["Poz_min"] = -1.20
            modelFeatures["F3_max"]  = 0.45
            modelFeatures["C3_max"]  = 0.45
            modelFeatures["Cz_std"]  = 0.23
            modelFeatures["ECG_max"] = 1.25
            modelFeatures["ECG_std"] = 0.62
        } else {
            // AWAKE look
            logToWatch("--- [PHONE LOG] --- D2. Applied AWAKE overrides to feature vector.")
            modelFeatures["C3_std"]  = 0.08
            modelFeatures["P3_std"]  = 0.08
            modelFeatures["P4_std"]  = 0.08
            modelFeatures["C3_min"]  = -0.20
            modelFeatures["P3_min"]  = -0.20
            modelFeatures["Poz_min"] = -0.20
            modelFeatures["F3_max"]  = 0.90
            modelFeatures["C3_max"]  = 0.90
            modelFeatures["Cz_std"]  = 0.45
            modelFeatures["ECG_max"] = 0.28
            modelFeatures["ECG_std"] = 0.18
        }

        // 🔎 Debug: print the 12 features and min/max to see if they move
        let debugLine = modelFeatures
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\(String(format: "%.2f", $0.value))" }
            .joined(separator: ", ")
        logToWatch("--- [PHONE LOG] --- Features → \(debugLine)")

        // E — run the model off the main actor to avoid UI lag / re-entrancy
        guard !isPredicting else { return }
        isPredicting = true
        let modelInput = modelFeatures

        Task.detached { [weak self] in
            guard let self else { return }
            let (rawState, rawP) = self.fatigueClassifier.predictWithProbability(features: modelInput)

            await MainActor.run {
                self.isPredicting = false

                // === DEMO GUARANTEE ===
                // When simulate toggle is OFF:
                // - force UI to Awake
                // - clamp probability low
                // - do NOT run hysteresis/episodes/alerts
                if !self.isFatigueSimulationActive {
                    let p = min(rawP, 0.05)
                    self.fatigueProbability = p
                    self.resetHysteresis()
                    self.fatigueEpisodeActive = false
                    self.fatigueLevel = .awake
                    self.logToWatch("--- [PHONE LOG] --- H. Hysteresis (OUT): p=\(String(format: "%.2f", p)) on=0 off=0")
                    self.logToWatch("--- [PHONE LOG] --- F. UI state: \(self.fatigueLevel.displayText)  p=\(String(format: "%.2f", p)).")
                    return
                }

                // === Normal path (simulate fatigue ON) ===
                let p = rawP
                self.fatigueProbability = p

                let isHigh = p >= self.fatigueOnThreshold
                let isLow  = p <= self.fatigueOffThreshold

                if self.fatigueEpisodeActive {
                    self.updateEpisodeStats(p: p)
                    if isLow {
                        self.consecutiveOff += 1; self.consecutiveOn = 0
                    } else if isHigh {
                        self.consecutiveOn = 0; self.consecutiveOff = 0
                    } else {
                        self.consecutiveOff = max(0, self.consecutiveOff - 1)
                        self.consecutiveOn = 0
                    }
                    self.logToWatch("--- [PHONE LOG] --- H. Hysteresis (IN): p=\(String(format: "%.2f", p)) on=\(self.consecutiveOn) off=\(self.consecutiveOff)")
                    if self.consecutiveOff >= self.consecOffNeeded {
                        self.fatigueEpisodeActive = false
                        self.consecutiveOff = 0
                        self.endEpisodeIfNeeded(reason: "hysteresis end")
                        self.logToWatch("--- [PHONE LOG] --- I. Episode END → returning to AWAKE.")
                    }
                } else {
                    if isHigh {
                        self.consecutiveOn += 1; self.consecutiveOff = 0
                    } else if isLow {
                        self.consecutiveOn = 0; self.consecutiveOff = 0
                    } else {
                        self.consecutiveOn = max(0, self.consecutiveOn - 1)
                        self.consecutiveOff = 0
                    }
                    self.logToWatch("--- [PHONE LOG] --- H. Hysteresis (OUT): p=\(String(format: "%.2f", p)) on=\(self.consecutiveOn) off=\(self.consecutiveOff)")
                    if self.consecutiveOn >= self.consecOnNeeded {
                        self.fatigueEpisodeActive = true
                        self.consecutiveOn = 0
                        
                        // --- THIS IS THE FIX ---
                        // We capture the snapshot windows right before we need them
                        // and pass them to the beginEpisode function.
                        let ecgSnapshot = Array(self.ecgBuffer.suffix(self.requiredSamples))
                        let eegSnapshot = Array(self.eegBuffer.suffix(self.requiredSamples))
                        self.beginEpisode(ecgSnapshot: ecgSnapshot, eegSnapshot: eegSnapshot)
                        // ----------------------
                        
                        self.updateEpisodeStats(p: p)
                        self.logToWatch("--- [PHONE LOG] --- I. Episode START → FATIGUED.")
                        
                        // alert cooldown
                        let now = Date()
                        let canAlert = (self.lastAlertDate == nil) || (now.timeIntervalSince(self.lastAlertDate!) >= self.minSecondsBetweenAlerts)
                        if canAlert {
                            self.sessionManager.send(message: ["action": "fatigueAlert"])
                            self.lastAlertDate = now
                            self.logToWatch("--- [PHONE LOG] --- I1. Sent fatigueAlert to watch.")
                        } else {
                            self.logToWatch("--- [PHONE LOG] --- I1. Skipped alert due to cooldown.")
                        }
                    }
                }

                // UI reflects episode state (not raw model label)
                self.fatigueLevel = self.fatigueEpisodeActive ? .fatigued : .awake
                self.logToWatch("--- [PHONE LOG] --- F. UI state: \(self.fatigueLevel.displayText)  p=\(String(format: "%.2f", p)).")
            }
        }
    }
    
    // MARK: - Episode helpers
    private func resetHysteresis() {
        consecutiveOn = 0
        consecutiveOff = 0
        fatigueEpisodeActive = false
        lastAlertDate = nil
        episodeProbs.removeAll()
    }
    
    private func beginEpisode(ecgSnapshot: [Double], eegSnapshot: [Double]) {
            episodeProbs.removeAll()
            // Pass the snapshots to the save function
            saveNewEvent(state: .fatigued, ecgSnapshot: ecgSnapshot, eegSnapshot: eegSnapshot)
            logToWatch("--- [PHONE LOG] --- DB: Episode inserted.")
        }
    
    private func endEpisodeIfNeeded(reason: String) {
        guard !episodeProbs.isEmpty else { return }
        let avg = episodeProbs.reduce(0, +) / Double(episodeProbs.count)
        let maxv = episodeProbs.max() ?? 0
        logToWatch("--- [PHONE LOG] --- DB: Episode finalized (\(reason)). avg=\(String(format: "%.2f", avg)) max=\(String(format: "%.2f", maxv)) frames=\(episodeProbs.count)")
        episodeProbs.removeAll()
    }
    
    private func updateEpisodeStats(p: Double) {
        episodeProbs.append(p)
    }

    private func saveNewEvent(state: FatigueState, ecgSnapshot: [Double], eegSnapshot: [Double]) {
            guard let context = modelContext else { return }
            // We now pass all the required arguments to the initializer
            let newEvent = FatigueEvent(
                timestamp: Date(),
                state: state,
                ecgSnapshot: ecgSnapshot,
                eegSnapshot: eegSnapshot
            )
            context.insert(newEvent)
        }
    
    // MARK: - Debugging
    private func logToWatch(_ message: String) {
        print(message)
        if verboseLogs {
            sessionManager.send(message: ["log": message])
        }
    }
    
    /// Map whatever EEG stats you have (likely Poz_mean/std/max/min)
    /// into the names the lean model expects, so we don't feed zeros.
    private func eegProxies(from eeg: [String: Double]) -> [String: Double] {
        let pozStd = eeg["Poz_std"] ?? 0
        let pozMax = eeg["Poz_max"] ?? 0
        let pozMin = eeg["Poz_min"] ?? 0

        return [
            // Reuse Poz stats as stand-ins for other EEG channels
            "C3_std":  pozStd,
            "C3_max":  pozMax,
            "C3_min":  pozMin,
            "Cz_std":  pozStd,
            "P3_std":  pozStd,
            "P4_std":  pozStd,
            "P3_min":  pozMin,
            "Poz_min": pozMin,   // this one is real if you have it
            "F3_max":  pozMax,
        ]
    }
}
