// FatigueDetector/FatigueDetector/PreDrive/PreDriveService.swift

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

    // MARK: - Helpers (sanitize accidental ```json blocks)
    private func extractJSONBytes(from string: String) -> Data? {
        // If it's already valid JSON, return it.
        if let data = string.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }
        // Try fenced ```json … ``` or ``` … ```
        let patterns = [
            #"```json\s*(\{[\s\S]*\})\s*```"#,
            #"```\s*(\{[\s\S]*\})\s*```"#
        ]
        for p in patterns {
            if let r = try? NSRegularExpression(pattern: p, options: .caseInsensitive) {
                let ns = string as NSString
                if let m = r.firstMatch(in: string, range: NSRange(location: 0, length: ns.length)),
                   m.numberOfRanges >= 2 {
                    let sub = ns.substring(with: m.range(at: 1))
                    if let data = sub.data(using: .utf8),
                       (try? JSONSerialization.jsonObject(with: data)) != nil {
                        return data
                    }
                }
            }
        }
        return nil
    }

    // MARK: - API
    /// POST {baseURL}/predrive/analyze
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
            let body = String(data: data, encoding: .utf8) ?? ""
            throw PreDriveServiceError.server("HTTP \(http.statusCode). Body: \(body)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // First attempt: decode as-is
        if let direct = try? decoder.decode(RiskAssessment.self, from: data) {
            return direct
        }

        // Fallback: try to salvage JSON from a markdown code block
        if let text = String(data: data, encoding: .utf8),
           let cleaned = extractJSONBytes(from: text),
           let parsed = try? decoder.decode(RiskAssessment.self, from: cleaned) {
            return parsed
        }

        let fallback = String(data: data, encoding: .utf8) ?? "Unrecognized response"
        throw PreDriveServiceError.decoding(fallback)
    }
}
