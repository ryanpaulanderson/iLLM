// LLMChat/Services/LLMService/OpenAIService.swift
import Foundation

final class OpenAIService: LLMServiceProtocol {
    private let configuration: APIConfiguration
    private let network: NetworkManaging

    init(configuration: APIConfiguration, network: NetworkManaging) {
        self.configuration = configuration
        self.network = network
    }

    // MARK: - DTOs

    struct ChatRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
    }

    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    // MARK: - LLMServiceProtocol

    func sendMessage(_ message: String, history: [Message], model: LLMModel) async throws -> String {
        let url = configuration.baseURL.appendingPathComponent("chat/completions")
        let msgs: [ChatMessage] =
            history.map { ChatMessage(role: $0.role.rawValue, content: $0.content) }
            + [ChatMessage(role: "user", content: message)]
        let body = ChatRequest(model: model.id, messages: msgs)

        let request = NetworkRequest(
            url: url,
            method: .post,
            headers: [
                "Authorization": "Bearer \(configuration.apiKey)",
                "Content-Type": "application/json"
            ],
            body: body
        )

        let response: ChatResponse = try await network.request(request)
        return response.choices.first?.message.content ?? ""
    }

    func availableModels() async throws -> [LLMModel] {
        // MVP: hardcoded shortlist; replace with live fetch if needed
        return [
            LLMModel(id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai"),
            LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai"),
            LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: "openai")
        ]
    }

    func validate(apiKey: String) async throws -> Bool {
        // MVP: simple non-empty validation; expand with a lightweight call if desired
        return !apiKey.isEmpty
    }
}