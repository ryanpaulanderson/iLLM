//
//  ModelCaching.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Protocol for caching LLM model lists.
//

import Foundation

/// Abstraction for a simple models cache.
protocol ModelCaching {
    /// Loads cached models for a provider+apiKey if not expired.
    /// - Parameters:
    ///   - provider: Provider identifier, e.g. "openai".
    ///   - apiKey: The API key used to scope cache entries (hashed; never stored in plaintext).
    ///   - ttl: Time interval in seconds that cached entries remain valid.
    /// - Returns: Cached models if available and fresh; otherwise nil.
    func load(provider: String, apiKey: String, ttl: TimeInterval) -> [LLMModel]?

    /// Saves models into cache for provider+apiKey scope.
    func save(_ models: [LLMModel], provider: String, apiKey: String)
}