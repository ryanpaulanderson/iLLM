// LLMChat/Services/Network/NetworkManager.swift
import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct NetworkRequest {
    let url: URL
    let method: HTTPMethod
    let headers: [String:String]
    let bodyData: Data?

    init<T: Encodable>(url: URL, method: HTTPMethod, headers: [String:String] = [:], body: T?) {
        self.url = url
        self.method = method
        self.headers = headers
        if let body = body {
            self.bodyData = try? JSONEncoder().encode(body)
        } else {
            self.bodyData = nil
        }
    }
}

protocol NetworkManaging {
    func request<T: Decodable>(_ request: NetworkRequest) async throws -> T
}

final class NetworkManager: NetworkManaging {
    func request<T: Decodable>(_ request: NetworkRequest) async throws -> T {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.bodyData
        for (key, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network(description: "Invalid response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.httpStatus(code: http.statusCode, body: body)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.decoding(error)
        }
    }
}