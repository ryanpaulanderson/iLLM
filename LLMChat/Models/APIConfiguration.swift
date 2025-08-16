// LLMChat/Models/APIConfiguration.swift
import Foundation

struct APIConfiguration: Codable, Equatable {
    var baseURL: URL
    var apiKey: String
    var provider: String

    init(baseURL: URL = URL(string: Constants.openAIBaseURL)!, apiKey: String = "", provider: String = "openai") {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.provider = provider
    }
}