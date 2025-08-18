import Foundation
import Combine

// Helper function to generate normally distributed random numbers
private func randomNormal(mean: Double, std: Double) -> Double {
    let u1 = Double.random(in: 0...1)
    let u2 = Double.random(in: 0...1)
    let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    return z * std + mean
}

class EEGSimulator: ObservableObject {
    // This will publish the full dictionary of features for the model
    @Published var eegFeatures: [String: Double] = [:]
    // This will publish a single value for the UI chart
    @Published var eegChartValue: Double = 0.0
    
    private var timer: Timer?
    private var simulateFatigue = false

    // Golden fingerprint values for EEG (Poz)
    private let awakeTargetMean: Double = 0.0004
    private let awakeTargetStd: Double = 0.4502
    private let fatiguedTargetMean: Double = 0.0035
    private let fatiguedTargetStd: Double = 0.2315
    
    func start(simulateFatigue: Bool) {
        self.simulateFatigue = simulateFatigue
        stop()
        // Generate features every 2 seconds to match the model's window
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.generateAndPublishFeatures()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateAndPublishFeatures() {
        let targetMean = simulateFatigue ? fatiguedTargetMean : awakeTargetMean
        let targetStd = simulateFatigue ? fatiguedTargetStd : awakeTargetStd
        
        let noise = Double.random(in: 0.95...1.05)
        let features: [String: Double] = [
            "Poz_mean": targetMean * noise,
            "Poz_std": targetStd * noise,
            "Poz_max": targetMean + (2 * targetStd * noise),
            "Poz_min": targetMean - (2 * targetStd * noise)
        ]
        
        // Publish the full feature dictionary for the model
        self.eegFeatures = features
        // Also publish the mean value for the chart to display
        self.eegChartValue = features["Poz_mean"] ?? 0.0
    }
}
