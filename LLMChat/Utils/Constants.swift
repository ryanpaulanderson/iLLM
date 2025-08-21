 // LLMChat/Utils/Constants.swift
import Foundation

enum Constants {
    /// OpenAI API base URL constructed safely via URLComponents.
    static var openAIBaseURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openai.com"
        components.path = "/v1/"
        guard let url = components.url else {
            preconditionFailure("Invalid OpenAI base URL components")
        }
        return url
    }

    /// String representation of the OpenAI API base URL for contexts that require String.
    static let openAIBaseURLString = "https://api.openai.com/v1/"
    
    // System Prompt defaults and keys
    static let systemPromptGlobalKey = "llmchat.systemPrompt.global"
    static let systemPromptOverridesKey = "llmchat.systemPrompt.overrides"
    static let defaultSystemPrompt = "You are Roo, a helpful, concise iOS development assistant who follows the app's style guide."
    
    // Model Selection
    static let defaultModelKey = "llmchat.defaultModel"
    
    // Model Parameters
    static let modelParametersKey = "llmchat.modelParameters"
}