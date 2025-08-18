import Foundation
import Combine

// The helper function is no longer needed here.

class ECGSimulator {
    // We now publish a dictionary of features, not raw data.
    let ecgFeaturePublisher = PassthroughSubject<[String: Double], Never>()
    private var timer: Timer?
    private var simulateFatigue = false
    
    // Use the golden fingerprint values for ECG
    private let awakeTargetMean: Double = -0.0002
    private let awakeTargetStd: Double = 0.6020
    private let fatiguedTargetMean: Double = 0.0012
    private let fatiguedTargetStd: Double = 0.3213
    
    func start(simulateFatigue: Bool) {
        self.simulateFatigue = simulateFatigue
        stop()
        // Generate and send features every 2 seconds, matching the model's window.
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
        
        // --- THIS IS THE KEY CHANGE ---
        // Instead of generating a full wave, we create the exact features the model needs.
        // We add a tiny bit of random noise to simulate real-world variance.
        let noise = Double.random(in: 0.95...1.05)
        let features: [String: Double] = [
            "ECG_mean": targetMean * noise,
            "ECG_std": targetStd * noise,
            // Estimate max/min based on mean and std (a common statistical practice)
            "ECG_max": targetMean + (2 * targetStd * noise),
            "ECG_min": targetMean - (2 * targetStd * noise)
        ]
        
        ecgFeaturePublisher.send(features)
    }
}
