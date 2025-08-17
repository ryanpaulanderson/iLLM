// LLMChat/Services/LLMService/OpenAIService.swift
import Foundation

final class OpenAIService: LLMServiceProtocol {
    private let configuration: APIConfiguration
    private let network: NetworkManaging
    private let modelCache: ModelCaching

    init(configuration: APIConfiguration, network: NetworkManaging, modelCache: ModelCaching = ModelCache()) {
        self.configuration = configuration
        self.network = network
        self.modelCache = modelCache
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

        let request = try NetworkRequest(
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
        // 1) Return cached models if present and fresh
        let provider = configuration.provider
        let apiKey = configuration.apiKey
        if let cached = modelCache.load(provider: provider, apiKey: apiKey, ttl: 4 * 60 * 60) {
            return cached
        }

        // 2) Fetch live from OpenAI /v1/models
        struct ModelsListResponse: Decodable { let data: [ModelItem] }
        struct ModelItem: Decodable { let id: String }

        let url = configuration.baseURL.appendingPathComponent("models")
        let request = try NetworkRequest(
            url: url,
            method: .get,
            headers: [
                "Authorization": "Bearer \(apiKey)"
            ],
            body: Optional<String>.none
        )
        let response: ModelsListResponse = try await network.request(request)

        // 3) Map to LLMModel and cache
        let models = response.data
            .map { LLMModel(id: $0.id, name: $0.id, provider: provider) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        modelCache.save(models, provider: provider, apiKey: apiKey)
        return models
    }

    func validate(apiKey: String) async throws -> Bool {
        // MVP: simple non-empty validation; expand with a lightweight call if desired
        return !apiKey.isEmpty
    }
}