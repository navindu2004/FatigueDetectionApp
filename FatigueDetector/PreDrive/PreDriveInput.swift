//
//  PreDriveInput.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-21.
//

import Foundation


struct PreDriveInput: Codable, Sendable {
    let sleep: Double
    let duration: Double
    let timeOfDay: String
    let healthData: HealthData
    let fatigueHistory: [FatigueLog]   // recent logs or summary items
}

struct HealthData: Codable, Sendable {
    var age: Int?
    var height: Double?   // centimeters
    var weight: Double?   // kilograms
}

struct FatigueLog: Codable, Sendable {
    let status: String     // "Awake" | "Drowsy" | "Fatigued"
    let score: Int         // 0|1|2 if you want
    let timestamp: Date
}

