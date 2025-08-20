// FatigueDetector/PreDrive/RiskAssessment.swift
import Foundation

/// Backend response for the Pre‑Drive analysis.
struct RiskAssessment: Codable, Equatable {
    enum Level: String, Codable { case low = "Low", moderate = "Moderate", high = "High" }
    var riskLevel: Level
    var explanation: String
    var recommendations: [String]
}
