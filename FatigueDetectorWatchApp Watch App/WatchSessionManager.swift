//
//  WatchSessionManager.swift
//  FatigueDetectorWatchApp Watch App
//
//  Created by Navindu Premaratne on 2025-08-12.
//

import Foundation
import WatchConnectivity

// A delegate protocol for the watch side as well.
protocol WatchSessionManagerDelegate: AnyObject {
    func sessionDidReceiveMessage(message: [String: Any])
}

@MainActor
class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {

    // --- Singleton Setup ---
    static let shared = WatchSessionManager()
    
    // --- Published Properties for UI ---
    @Published var isReachable: Bool = false
    
    // --- Delegate ---
    weak var delegate: WatchSessionManagerDelegate?
    
    private let session: WCSession
    
    // --- Initialization ---
    private override init() {
        self.session = .default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // --- Public Methods ---
    
    /// Sends a message dictionary to the iPhone.
    func send(message: [String: Any]) {
        guard session.activationState == .activated && session.isReachable else {
            print("WCSession is not active or reachable on the watch.")
            return
        }
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message from watch: \(error.localizedDescription)")
        }
    }

    // MARK: - WCSessionDelegate Conformance
    
    // Called when the session activation is complete.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("Watch WCSession activated with state: \(activationState.rawValue)")
            DispatchQueue.main.async {
                self.isReachable = session.isReachable
            }
        }
    }

    // Called when the iPhone's reachability changes.
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch WCSession reachability changed to: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    // Called on the watch when it receives a message from the iPhone.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Watch received message: \(message)")
        DispatchQueue.main.async {
            self.delegate?.sessionDidReceiveMessage(message: message)
        }
    }
}
