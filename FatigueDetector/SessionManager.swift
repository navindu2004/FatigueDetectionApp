//
//  SessionManager.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import Foundation
import WatchConnectivity

// We create a delegate protocol so our ViewModel can be notified of new messages.
protocol SessionManagerDelegate: AnyObject {
    func sessionDidReceiveMessage(message: [String: Any])
}

@MainActor
class SessionManager: NSObject, WCSessionDelegate, ObservableObject {
    
    // --- Singleton Setup ---
    static let shared = SessionManager()
    
    // --- Published Properties for UI ---
    @Published var isReachable: Bool = false
    
    // --- Delegate to notify other parts of the app ---
    weak var delegate: SessionManagerDelegate?
    
    private let session: WCSession
    
    // --- Initialization ---
    // The initializer is private to enforce the singleton pattern.
    private override init() {
        self.session = .default
        super.init()
        
        // Only activate the session if the device supports it.
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // --- Public Methods ---
    
    /// Sends a message dictionary to the counterpart device.
    func send(message: [String: Any]) {
        guard session.activationState == .activated && session.isReachable else {
            print("WCSession is not active or reachable.")
            return
        }
        
        session.sendMessage(message, replyHandler: nil) { error in
            // Handle any errors that occur during sending.
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate Conformance
    
    // This method is called when the session activation is complete.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
            // Update the reachability status on the main thread.
            DispatchQueue.main.async {
                self.isReachable = session.isReachable
            }
        }
    }
    
    // This is a crucial method for iOS. It's called when the watch becomes reachable or unreachable.
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed to: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    // This method is called on the iPhone when it receives a message from the watch.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("iPhone received message: \(message)")
        // Notify our delegate (the ViewModel) that a message has arrived.
        // We do this on the main thread to ensure UI updates are safe.
        DispatchQueue.main.async {
            self.delegate?.sessionDidReceiveMessage(message: message)
        }
    }
    
    // --- Required stubs for iOS ---
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // If the session deactivates, we should reactivate it.
        session.activate()
    }
}
