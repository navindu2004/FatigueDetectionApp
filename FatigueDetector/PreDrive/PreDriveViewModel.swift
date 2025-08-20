// FatigueDetector/FatigueDetector/PreDrive/PreDriveViewModel.swift
import Foundation
import SwiftUI

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

    func analyze(health: (age: Int?, height: Int?, weight: Int?) = (nil, nil, nil),
                 history: (drowsy: Int?, fatigued: Int?) = (nil, nil)) async {
        error = nil
        assessment = nil

        guard let s = Double(sleep), let d = Double(duration), s >= 0, d > 0 else {
            error = "Please fill in valid values for sleep and duration."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let input = PreDriveInput(
                sleepHours: s,
                  tripDurationHours: d,
                  timeOfDay: timeOfDay,
                  totalDrowsy: history.drowsy,
                  totalFatigued: history.fatigued,
                  age: health.age,
                  heightCm: health.height,
                  weightKg: health.weight
            )
            let result = try await service.analyze(input: input)
            self.assessment = result
        } catch {
            self.error = "Could not fetch assessment. Please try again."
        }
    }
}
