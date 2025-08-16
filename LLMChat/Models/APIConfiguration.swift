 // LLMChat/Models/APIConfiguration.swift
import Foundation

/// API configuration describing the target base URL, credentials, and provider identifier.
struct APIConfiguration: Codable, Equatable {
    var baseURL: URL
    var apiKey: String
    var provider: String

    /// Initialize a configuration.
    /// - Parameters:
    ///   - baseURL: Base URL of the provider. Defaults to the OpenAI v1 base URL.
    ///   - apiKey: Secret API key used for authentication.
    ///   - provider: Provider identifier (e.g., "openai").
    init(baseURL: URL = Constants.openAIBaseURL, apiKey: String = "", provider: String = "openai") {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.provider = provider
    }
}