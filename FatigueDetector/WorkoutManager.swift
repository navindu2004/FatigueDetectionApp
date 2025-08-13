import Foundation
import HealthKit
import Combine

// The class must be Sendable to be used safely across threads.
// NSObject and ObservableObject are already Sendable.
@MainActor
class WorkoutManager: NSObject, ObservableObject {
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    let ecgPublisher = PassthroughSubject<[Double], Never>()

    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("Error creating workout session: \(error)")
            return
        }

        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        
        // The delegates must be set before starting the session.
        session?.delegate = self
        builder?.delegate = self

        session?.startActivity(with: Date())
        builder?.beginCollection(withStart: Date()) { (success, error) in
            if success {
                print("Workout collection started.")
            } else if let error = error {
                print("Error beginning workout collection: \(error)")
            }
        }
    }

    func stopWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            self.builder?.finishWorkout { (workout, error) in
                print("Workout finished.")
            }
        }
    }
    
    private func fetchLatestECG() {
        // This part is complex. We will simulate data flow for now to ensure the app runs.
        let simulatedECGChunk = (0..<50).map { _ in Double.random(in: -0.1...0.1) }
        print("WorkoutManager: Publishing simulated ECG chunk.")
        self.ecgPublisher.send(simulatedECGChunk)
    }
}

// EXTENSION for Delegate Conformance
// By putting the delegate methods in a separate extension, we clearly separate their logic.
// The methods are called on a background queue by HealthKit.
extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session state changed to \(toState.rawValue)")
        // This is a background thread. No UI updates here.
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error)")
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // This is a background thread.
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // This is a background thread.
        if collectedTypes.contains(HKObjectType.electrocardiogramType()) {
            // To safely call our MainActor-isolated method, we wrap it in a Task.
            Task { @MainActor in
                fetchLatestECG()
            }
        }
    }
}
