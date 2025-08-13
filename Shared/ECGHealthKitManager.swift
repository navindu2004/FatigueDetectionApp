import Foundation
import HealthKit

class ECGHealthKitManager {
    let healthStore = HKHealthStore()
    
    // The ONLY types we need are ECG and Heart Rate for the workout session.
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.electrocardiogramType(),
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]
    
    /// Requests permission from the user to read HealthKit data.
    /// This should ONLY be called from the iPhone.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
