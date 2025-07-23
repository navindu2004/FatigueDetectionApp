//
//  ECGManager.swift
//  FatigueDetectorWatchApp Watch App Extension
//

import Foundation
import HealthKit
import WatchConnectivity

class ECGManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let ecgType = HKObjectType.electrocardiogramType()

    @Published var latestClassification: String = "No Data"
    @Published var voltageValues: [Double] = []

    init() {
        requestAuthorization()
    }

    // Step 1: Ask for permission
    private func requestAuthorization() {
        healthStore.requestAuthorization(toShare: nil, read: [ecgType]) { success, error in
            if !success {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                print("✅ HealthKit ECG permission granted")
                self.fetchLatestECG()
            }
        }
    }

    // Step 2: Fetch most recent ECG
    func fetchLatestECG() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: ecgType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in
            guard let sample = results?.first as? HKElectrocardiogram else {
                print("❗ No ECG sample found")
                return
            }
            self?.handleECG(sample)
        }
        healthStore.execute(query)
    }

    // Step 3: Extract voltage and classification
    private func handleECG(_ ecg: HKElectrocardiogram) {
        let classification: String
        switch ecg.classification {
        case .notSet: classification = "Not Set"
        case .sinusRhythm: classification = "Sinus Rhythm"
        case .atrialFibrillation: classification = "AFib"
        case .inconclusiveLowHeartRate: classification = "Inconclusive: Low HR"
        case .inconclusiveHighHeartRate: classification = "Inconclusive: High HR"
        case .inconclusivePoorReading: classification = "Inconclusive: Poor Reading"
        case .inconclusiveOther: classification = "Inconclusive: Other"
        case .unrecognized: classification = "Unrecognized"
        @unknown default: classification = "Unknown"
        }

        DispatchQueue.main.async {
            self.latestClassification = classification
        }

        var voltages: [Double] = []
        let voltageQuery = HKElectrocardiogramQuery(electrocardiogram: ecg) { (query, voltageMeasurement, done, error) in
            if let error = error {
                print("❌ Error reading ECG voltages: \(error.localizedDescription)")
                return
            }

            if let voltage = voltageMeasurement?.quantity(for: .appleWatchSimilarToLeadI)?
                .doubleValue(for: HKUnit.volt()) {
                voltages.append(voltage)
            }

            if done {
                DispatchQueue.main.async {
                    self.voltageValues = voltages
                    SessionManager.shared.send(message: [
                        "ecgClassification": classification,
                        "ecgVoltage": voltages.prefix(50)
                    ])
                }
            }
        }

        healthStore.execute(voltageQuery)
    }
}
