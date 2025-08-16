// LLMChat/Utils/Errors.swift
import Foundation
import Security

enum AppError: LocalizedError, Identifiable {
    var id: String { localizedDescription }

    case network(description: String)
    case httpStatus(code: Int, body: String)
    case decoding(Error)
    case keychain(status: OSStatus)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(let description): return description
        case .httpStatus(let code, let body): return "HTTP \(code): \(body)"
        case .decoding(let error): return "Decoding error: \(error.localizedDescription)"
        case .keychain(let status): return "Keychain error: \(status)"
        case .unknown(let error): return "Unknown error: \(error.localizedDescription)"
        }
    }
}