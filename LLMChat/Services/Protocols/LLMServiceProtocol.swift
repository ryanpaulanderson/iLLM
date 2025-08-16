// LLMChat/Services/Protocols/LLMServiceProtocol.swift
import Foundation

protocol LLMServiceProtocol {
    func sendMessage(_ message: String, history: [Message], model: LLMModel) async throws -> String
    func availableModels() async throws -> [LLMModel]
    func validate(apiKey: String) async throws -> Bool
}