//
//  PreDriveService.swift
//  FatigueDetector
//

import Foundation

// MARK: - Protocol
protocol PreDriveServicing {
    func analyze(input: PreDriveInput) async throws -> RiskAssessment
}

// MARK: - Error mapping
enum PreDriveServiceError: LocalizedError {
    case badURL
    case network(String)
    case server(String)
    case decoding(String)
    case invalidStatus(Int)

    var errorDescription: String? {
        switch self {
        case .badURL:                       return "Invalid backend URL."
        case .network(let msg):             return "Network error: \(msg)"
        case .server(let msg):              return "Server error: \(msg)"
        case .decoding(let msg):            return "Response decoding failed: \(msg)"
        case .invalidStatus(let code):      return "Unexpected HTTP status: \(code)"
        }
    }
}

// MARK: - Concrete implementation
final class PreDriveService: @unchecked Sendable, PreDriveServicing {

    private let session: URLSession
    private let baseURL: URL

    /// Designated init (DI-friendly)
    init(baseURL: URL) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest  = 20
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.baseURL = baseURL
    }

    /// Convenience init that reads from `PreDriveConfig`
    convenience init() {
        guard let url = URL(string: PreDriveConfig.baseURL) else {
            fatalError("PreDriveConfig.baseURL is not a valid URL")
        }
        self.init(baseURL: url)
    }

    // POST {baseURL}/predrive/analyze
    func analyze(input: PreDriveInput) async throws -> RiskAssessment {
        let url = baseURL.appendingPathComponent("predrive/analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(input)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PreDriveServiceError.network("No HTTPURLResponse.")
        }
        guard (200...299).contains(http.statusCode) else {
            // try to surface server text if any
            let body = String(data: data, encoding: .utf8) ?? ""
            throw PreDriveServiceError.invalidStatus(http.statusCode == 200 ? 0 : http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(RiskAssessment.self, from: data)
        } catch {
            let fallback = String(data: data, encoding: .utf8) ?? "Unrecognized response"
            throw PreDriveServiceError.decoding(fallback)
        }
    }
}
