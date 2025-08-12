//
//  ECGHealthKitManager.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import Foundation
import HealthKit
import Combine

@MainActor
class ECGHealthKitManager: ObservableObject {
    
    let ecgPublisher = PassthroughSubject<[Double], Never>()
    
    private let healthStore = HKHealthStore()
    private let ecgType = HKObjectType.electrocardiogramType()
    
    // FIXED: The 'anchor' must be managed in a thread-safe way.
    // Making it a non-isolated property of a MainActor class is the simplest fix.
    private var anchor: HKQueryAnchor?
    private var ecgQuery: HKAnchoredObjectQuery?
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: [ecgType]) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func startECGQuery() {
        stopECGQuery()
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        // This is the handler that receives new data.
        // It runs on a background thread by default.
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, newAnchor, error in
            
            // We switch to the MainActor to safely update our properties and call our processing func.
            Task { @MainActor in
                if let error = error {
                    print("ECG Query Update Error: \(error.localizedDescription)")
                    return
                }
                self.anchor = newAnchor
                if let ecgSamples = samples as? [HKElectrocardiogram] {
                    self.process(ecgSamples)
                }
            }
        }
        
        let query = HKAnchoredObjectQuery(
            type: ecgType,
            predicate: predicate,
            anchor: self.anchor, // Use the stored anchor
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler
        )
        
        query.updateHandler = updateHandler
        
        self.ecgQuery = query
        healthStore.execute(query)
        print("ECG query started.")
    }
    
    func stopECGQuery() {
        if let query = ecgQuery {
            healthStore.stop(query)
            ecgQuery = nil
            print("ECG query stopped.")
        }
    }
    
    // This function is now guaranteed to be called on the main actor.
    private func process(_ samples: [HKElectrocardiogram]) {
        for sample in samples {
            // This query is more compatible and fetches the voltage data for a specific ECG sample.
            let voltageQuery = HKElectrocardiogramQuery(sample) { [weak self] (query, result) in
                guard let self = self else { return }
                
                Task { @MainActor in
                    do {
                        switch result {
                        case .measurement(let measurement):
                            // This block will be called repeatedly for each voltage point in the ECG.
                            if let voltage = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                                let voltValue = voltage.doubleValue(for: .volt())
                                // We publish each data point as it arrives.
                                // The receiving ViewModel on the iPhone can batch them.
                                self.ecgPublisher.send([voltValue])
                            }
                        case .done:
                            // No more data for this ECG sample.
                            print("Finished processing one ECG sample.")
                        case .error(let error):
                            print("HKElectrocardiogramQuery failed with error: \(error.localizedDescription)")
                        @unknown default:
                            fatalError("An unknown result type was received from HKElectrocardiogramQuery.")
                        }
                    }
                }
            }
            // Execute the query on the health store.
            self.healthStore.execute(voltageQuery)
        }
    }
}
