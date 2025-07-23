import Foundation
import WatchConnectivity

class SessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = SessionManager()

    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func send(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    // WatchOS-specific activation delegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
//
//  SessionManager.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-07-21.
//

