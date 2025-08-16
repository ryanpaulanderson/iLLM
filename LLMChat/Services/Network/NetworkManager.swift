  // LLMChat/Services/Network/NetworkManager.swift
 import Foundation
 #if DEBUG
 import os
 #endif
 
 /// HTTP verbs used by NetworkRequest.
 enum HTTPMethod: String {
     case get = "GET"
     case post = "POST"
 }

/// Typed network request with JSON body support.
struct NetworkRequest {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let bodyData: Data?

    init<T: Encodable>(url: URL, method: HTTPMethod, headers: [String: String] = [:], body: T?) throws {
        self.url = url
        self.method = method
        self.headers = headers
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            self.bodyData = try encoder.encode(body)
        } else {
            self.bodyData = nil
        }
    }
}

/// Minimal HTTP client.
protocol NetworkManaging {
    func request<T: Decodable>(_ request: NetworkRequest) async throws -> T
}

final class NetworkManager: NetworkManaging {
    #if DEBUG
    private let logger = Logger(subsystem: "LLMChat.Network", category: "HTTP")
    #endif

    func request<T: Decodable>(_ request: NetworkRequest) async throws -> T {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.bodyData
        for (key, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        #if DEBUG
        logger.log("➡️ \(request.method.rawValue, privacy: .public) \(request.url.absoluteString, privacy: .public)")
        #endif

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network(description: "Invalid response")
        }

        #if DEBUG
        logger.log("⬅️ status=\(http.statusCode, privacy: .public) for \(request.url.absoluteString, privacy: .public)")
        #endif

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.httpStatus(code: http.statusCode, body: body)
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decoding(error)
        }
    }
}