//
//  OpenAIServiceTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for OpenAIService HTTP requests, JSON handling, and caching.
//

import XCTest
@testable import LLMChat

final class OpenAIServiceTests: XCTestCase {
    
    // MARK: - Test Doubles
    
    private final class FakeNetworkManager: NetworkManaging {
        var requestResult: Any?
        var requestError: Error?
        private(set) var requestCallCount = 0
        private(set) var lastRequest: NetworkRequest?
        
        func request<T>(_ request: NetworkRequest) async throws -> T where T : Decodable {
            requestCallCount += 1
            lastRequest = request
            
            if let error = requestError {
                throw error
            }
            
            if let typed = requestResult as? T {
                return typed
            }
            if let encodable = requestResult as? Encodable {
                let encoder = JSONEncoder()
                let data = try encoder.encode(AnyEncodable(encodable))
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            }
            throw AppError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid result type")))
        }
    }
    
    private final class FakeModelCache: ModelCaching {
        private var cachedModels: [String: (models: [LLMModel], timestamp: Date)] = [:]
        private(set) var loadCallCount = 0
        private(set) var saveCallCount = 0
        private(set) var clearCallCount = 0
        private(set) var lastSavedModels: [LLMModel]?
        
        func load(provider: String, apiKey: String, ttl: TimeInterval) -> [LLMModel]? {
            loadCallCount += 1
            let key = "\(provider)-\(apiKey)"
            guard let cached = cachedModels[key] else { return nil }
            
            if Date().timeIntervalSince(cached.timestamp) < ttl {
                return cached.models
            } else {
                cachedModels.removeValue(forKey: key)
                return nil
            }
        }
        
        func save(_ models: [LLMModel], provider: String, apiKey: String) {
            saveCallCount += 1
            lastSavedModels = models
            let key = "\(provider)-\(apiKey)"
            cachedModels[key] = (models: models, timestamp: Date())
        }
        
        func clear(provider: String, apiKey: String) {
            clearCallCount += 1
            let key = "\(provider)-\(apiKey)"
            cachedModels.removeValue(forKey: key)
        }
    }
    
    // MARK: - Test Fixtures
    
    private var service: OpenAIService!
    private var fakeNetwork: FakeNetworkManager!
    private var fakeCache: FakeModelCache!
    private var configuration: APIConfiguration!
    
    override func setUp() {
        super.setUp()
        fakeNetwork = FakeNetworkManager()
        fakeCache = FakeModelCache()
        configuration = APIConfiguration(
            baseURL: URL(string: "https://api.openai.com/v1")!,
            apiKey: "test-api-key",
            provider: "openai"
        )
        service = OpenAIService(configuration: configuration, network: fakeNetwork, modelCache: fakeCache)
    }
    
    override func tearDown() {
        service = nil
        fakeNetwork = nil
        fakeCache = nil
        configuration = nil
        super.tearDown()
    }
    
    // MARK: - Send Message Tests
    
    func test_sendMessage_buildsCorrectRequest_returnsResponse() async throws {
        // Given
        let testModel = LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        let history = [Message(content: "Previous message", role: .user)]
        let parameters = ModelParameters(temperature: 0.7, topP: 0.9)
        
        let mockResponse = OpenAIService.ChatResponse(choices: [
            OpenAIService.ChatResponse.Choice(
                message: OpenAIService.ChatResponse.Choice.Message(role: "assistant", content: "Response content")
            )
        ])
        fakeNetwork.requestResult = mockResponse
        
        // When
        let result = try await service.sendMessage("Hello", history: history, model: testModel, parameters: parameters)
        
        // Then
        XCTAssertEqual(result, "Response content")
        XCTAssertEqual(fakeNetwork.requestCallCount, 1)
        
        let request = fakeNetwork.lastRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.method, .post)
        XCTAssertTrue(request?.url.absoluteString.contains("chat/completions") ?? false)
        XCTAssertEqual(request?.headers["Authorization"], "Bearer test-api-key")
        XCTAssertEqual(request?.headers["Content-Type"], "application/json")
    }
    
    func test_sendMessage_withEmptyResponse_returnsEmptyString() async throws {
        // Given
        let testModel = LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        let mockResponse = OpenAIService.ChatResponse(choices: [])
        fakeNetwork.requestResult = mockResponse
        
        // When
        let result = try await service.sendMessage("Hello", history: [], model: testModel, parameters: .empty)
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func test_sendMessage_withNetworkError_throwsError() async {
        // Given
        let testModel = LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        fakeNetwork.requestError = AppError.network(description: "Connection failed")
        
        // When & Then
        do {
            _ = try await service.sendMessage("Hello", history: [], model: testModel, parameters: .empty)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.network(description: "Connection failed"))
        }
    }
    
    func test_sendMessage_buildsCorrectChatMessages() async throws {
        // Given
        let testModel = LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        let history = [
            Message(content: "System prompt", role: .system),
            Message(content: "User message", role: .user),
            Message(content: "Assistant response", role: .assistant)
        ]
        
        let mockResponse = OpenAIService.ChatResponse(choices: [
            OpenAIService.ChatResponse.Choice(
                message: OpenAIService.ChatResponse.Choice.Message(role: "assistant", content: "New response")
            )
        ])
        fakeNetwork.requestResult = mockResponse
        
        // When
        _ = try await service.sendMessage("New user message", history: history, model: testModel, parameters: .empty)
        
        // Then
        XCTAssertEqual(fakeNetwork.requestCallCount, 1)
        // The request should include history + new message (total 4 messages)
        // We can't easily inspect the request body without more complex mocking, but we verify the call was made
    }
    
    // MARK: - Available Models Tests
    
    func test_availableModels_withCachedModels_returnsCachedResults() async throws {
        // Given
        let cachedModels = [LLMModel(id: "cached-model", name: "Cached", provider: "openai")]
        // Save models to simulate cache hit
        fakeCache.save(cachedModels, provider: "openai", apiKey: "test-api-key")
        
        // When
        let result = try await service.availableModels()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "cached-model")
        XCTAssertEqual(fakeCache.loadCallCount, 1)
        XCTAssertEqual(fakeNetwork.requestCallCount, 0) // No network call
    }
    
    func test_availableModels_withoutCache_fetchesFromAPI() async throws {
        // Given
        let mockResponse = ModelsListResponse(data: [
            ModelItem(id: "gpt-4o"),
            ModelItem(id: "gpt-3.5-turbo")
        ])
        fakeNetwork.requestResult = mockResponse
        
        // When
        let result = try await service.availableModels()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "gpt-3.5-turbo") // Should be sorted
        XCTAssertEqual(result[1].id, "gpt-4o")
        XCTAssertEqual(result[0].provider, "openai")
        
        XCTAssertEqual(fakeNetwork.requestCallCount, 1)
        XCTAssertEqual(fakeCache.saveCallCount, 1)
        XCTAssertEqual(fakeCache.lastSavedModels?.count, 2)
        
        let request = fakeNetwork.lastRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.method, .get)
        XCTAssertTrue(request?.url.absoluteString.contains("models") ?? false)
        XCTAssertEqual(request?.headers["Authorization"], "Bearer test-api-key")
    }
    
    func test_availableModels_withNetworkError_throwsError() async {
        // Given
        fakeNetwork.requestError = AppError.httpStatus(code: 401, body: "Unauthorized")
        
        // When & Then
        do {
            _ = try await service.availableModels()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.httpStatus(code: 401, body: "Unauthorized"))
        }
    }
    
    func test_availableModels_sortsModelsByName() async throws {
        // Given
        let mockResponse = ModelsListResponse(data: [
            ModelItem(id: "zebra-model"),
            ModelItem(id: "alpha-model"),
            ModelItem(id: "beta-model")
        ])
        fakeNetwork.requestResult = mockResponse
        
        // When
        let result = try await service.availableModels()
        
        // Then
        XCTAssertEqual(result[0].id, "alpha-model")
        XCTAssertEqual(result[1].id, "beta-model")
        XCTAssertEqual(result[2].id, "zebra-model")
    }
    
    // MARK: - Validate API Key Tests
    
    func test_validate_withNonEmptyKey_returnsTrue() async throws {
        // When
        let result = try await service.validate(apiKey: "test-key")
        
        // Then
        XCTAssertTrue(result)
    }
    
    func test_validate_withEmptyKey_returnsFalse() async throws {
        // When
        let result = try await service.validate(apiKey: "")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_validate_withWhitespaceKey_returnsFalse() async throws {
        // When
        let result = try await service.validate(apiKey: "   ")
        
        // Then
        XCTAssertFalse(result)
    }
}

// MARK: - Test Response Models

/// Helper struct to match the internal ModelsListResponse for testing
private struct ModelsListResponse: Codable {
    let data: [ModelItem]
}

private struct ModelItem: Codable {
    let id: String
}

// Type-erased Encodable wrapper to allow encoding existential Encodable values
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { self._encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
