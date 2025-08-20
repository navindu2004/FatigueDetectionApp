//
//  PreDriveConfig.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-21.
//

enum PreDriveConfig {
    #if targetEnvironment(simulator)
    static let baseURL = "http://localhost:8787"
    #else
    static let baseURL = "http://192.168.1.203:8787" // <— your Mac’s LAN IP
    #endif
}
