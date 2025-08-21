import Foundation
import SwiftUI
import SwiftData

@MainActor
final class PreDriveViewModel: ObservableObject {
    @Published var sleep: String = ""
    @Published var duration: String = ""
    @Published var timeOfDay: String = "Morning"

    @Published var isLoading = false
    @Published var error: String?
    @Published var assessment: RiskAssessment?

    private let service: PreDriveServicing

    init(service: PreDriveServicing) { self.service = service }

    func analyze(
        modelContext: ModelContext,
        currentState: String // "Awake" | "Drowsy" | "Fatigued"
    ) async {
        error = nil
        assessment = nil

        guard let s = Double(sleep), let d = Double(duration), s >= 0, d > 0 else {
            error = "Please fill in valid values for sleep and duration."
            return
        }

        // Load saved health metrics (from SettingsView)
        let defaults = UserDefaults.standard
        let age = defaults.object(forKey: "health.age") as? Int
        let height = defaults.object(forKey: "health.height") as? Double
        let weight = defaults.object(forKey: "health.weight") as? Double
        let health = HealthData(age: age, height: height, weight: weight)

        // Fetch recent fatigue logs from SwiftData (last 7 days)
        let history: [FatigueLog] = fetchRecentFatigueLogs(modelContext: modelContext, injectCurrent: currentState)

        isLoading = true
        defer { isLoading = false }

        do {
            let body = PreDriveInput(
                sleep: s,
                duration: d,
                timeOfDay: timeOfDay,
                healthData: health,
                fatigueHistory: history
            )
            let result = try await service.analyze(input: body)
            self.assessment = result
        } catch {
            self.error = "Could not fetch assessment. Please try again."
        }
    }

    private func fetchRecentFatigueLogs(modelContext: ModelContext, injectCurrent state: String) -> [FatigueLog] {
        var logs: [FatigueLog] = []

        // 1) Add the "current" state as a most-recent log (optional but useful)
        let now = Date()
        let score = (state == "Awake" ? 0 : (state == "Drowsy" ? 1 : 2))
        logs.append(FatigueLog(status: state, score: score, timestamp: now))

        // 2) Pull recent saved events (last 7 days) from SwiftData
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        // If your SwiftData entity is `FatigueEvent` with properties `timestamp: Date` and `state: FatigueState`
        let descriptor = FetchDescriptor<FatigueEvent>(
            predicate: #Predicate { $0.timestamp >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let events = try? modelContext.fetch(descriptor) {
            for e in events.prefix(200) {
                let status = e.state.displayText   // e.g., "Awake" | "Drowsy" | "Fatigued"
                let score = (status == "Awake" ? 0 : (status == "Drowsy" ? 1 : 2))
                logs.append(FatigueLog(status: status, score: score, timestamp: e.timestamp))
            }
        }

        return logs
    }
}
