// LLMChat/Services/LLMService/LLMServiceFactory.swift
import Foundation

protocol LLMServiceFactoryType {
    func makeService(configuration: APIConfiguration) -> LLMServiceProtocol
}

private enum Provider: String {
    case openai
}

final class LLMServiceFactory: LLMServiceFactoryType {
    func makeService(configuration: APIConfiguration) -> LLMServiceProtocol {
        switch Provider(rawValue: configuration.provider.lowercased()) ?? .openai {
        case .openai:
            return OpenAIService(configuration: configuration, network: NetworkManager())
        }
    }
}