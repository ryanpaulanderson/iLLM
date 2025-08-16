// LLMChat/Utils/Errors.swift
import Foundation
import Security

enum AppError: LocalizedError, Identifiable, Equatable {
    var id: String { localizedDescription }

    case network(description: String)
    case httpStatus(code: Int, body: String)
    case decoding(Error)
    case keychain(status: OSStatus)
    case unknown(Error)
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.network(let a), .network(let b)):
            return a == b
        case (.httpStatus(let codeA, let bodyA), .httpStatus(let codeB, let bodyB)):
            return codeA == codeB && bodyA == bodyB
        case (.decoding(let a), .decoding(let b)):
            return a.localizedDescription == b.localizedDescription
        case (.keychain(let a), .keychain(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }

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