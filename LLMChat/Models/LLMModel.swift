// LLMChat/Models/LLMModel.swift
import Foundation

struct LLMModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let provider: String
    let maxTokens: Int
    let supportsFunctions: Bool

    init(id: String, name: String, provider: String, maxTokens: Int = 4096, supportsFunctions: Bool = false) {
        self.id = id
        self.name = name
        self.provider = provider
        self.maxTokens = maxTokens
        self.supportsFunctions = supportsFunctions
    }
}