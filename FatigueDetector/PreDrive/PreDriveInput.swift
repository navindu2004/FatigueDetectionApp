//
//  PreDriveInput.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-08-21.
//

import Foundation

struct PreDriveInput: Codable, Sendable {
    let sleepHours: Double
    let tripDurationHours: Double
    let timeOfDay: String          // "Morning", "Afternoon", "Evening", "Night"
    // Optional summaries (used by prompt engineering server-side)
    let totalDrowsy: Int?
    let totalFatigued: Int?
    // Optional health metrics
    let age: Int?
    let heightCm: Int?
    let weightKg: Int?
}

struct HealthData: Codable, Sendable {
    var age: Int?
    var height: Double?   // centimeters
    var weight: Double?   // kilograms
}

struct FatigueLog: Codable, Sendable {
    let status: String     // e.g., "Awake", "Drowsy", "Fatigued"
    let score: Int
    let timestamp: Date
}
