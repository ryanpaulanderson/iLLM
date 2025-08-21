 // LLMChat/Services/Protocols/LLMServiceProtocol.swift
import Foundation

/// Abstraction for Large Language Model providers.
protocol LLMServiceProtocol {
    /// Sends a user message along with chat history for context and returns the assistant's reply.
    /// - Parameters:
    ///   - message: The latest user message.
    ///   - history: Full conversation history ordered oldest to newest.
    ///   - model: Target model to use for completion.
    ///   - parameters: Optional model parameters like temperature and top-p.
    /// - Returns: Assistant reply text.
    func sendMessage(_ message: String, history: [Message], model: LLMModel, parameters: ModelParameters) async throws -> String

    /// Returns the list of available models for this provider.
    func availableModels() async throws -> [LLMModel]

    /// Validates the provided API key with a lightweight check.
    func validate(apiKey: String) async throws -> Bool
}

/// Optional capability for providers that support token streaming.
/// Implementations that conform can return incremental text deltas via `AsyncThrowingStream`.
protocol LLMStreamingServiceProtocol: LLMServiceProtocol {
    /// Streams an assistant reply as it is generated.
    /// - Parameters:
    ///   - message: The latest user message.
    ///   - history: Full conversation history ordered oldest to newest.
    ///   - model: Target model to use for completion.
    ///   - parameters: Optional model parameters like temperature and top-p.
    /// - Returns: A stream of incremental text deltas (not cumulative). The caller should append them.
    func streamMessage(_ message: String, history: [Message], model: LLMModel, parameters: ModelParameters) throws -> AsyncThrowingStream<String, Error>
}