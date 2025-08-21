//
//  TestUtilities.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Shared test utilities, fakes, and helpers for consistent testing across the app.
//

import Foundation
import XCTest
@testable import LLMChat

// MARK: - Test Data Factories

enum TestDataFactory {
    static func sampleMessage(
        content: String = "Test message",
        role: MessageRole = .user,
        timestamp: Date = Date()
    ) -> Message {
        Message(content: content, role: role, timestamp: timestamp)
    }
    
    static func sampleConversation(
        title: String = "Test Conversation",
        lastMessage: String? = nil,
        isActive: Bool = false,
        lastUsedModelID: String? = nil
    ) -> Conversation {
        Conversation(
            title: title,
            lastMessage: lastMessage,
            isActive: isActive,
            lastUsedModelID: lastUsedModelID
        )
    }
    
    static func sampleLLMModel(
        id: String = "test-model",
        name: String = "Test Model",
        provider: String = "openai"
    ) -> LLMModel {
        LLMModel(id: id, name: name, provider: provider)
    }
    
    static func sampleAPIConfiguration(
        apiKey: String = "test-api-key",
        provider: String = "openai"
    ) -> APIConfiguration {
        APIConfiguration(apiKey: apiKey, provider: provider)
    }
    
    static func sampleModelParameters(
        temperature: Double? = 0.7,
        topP: Double? = 0.9
    ) -> ModelParameters {
        ModelParameters(temperature: temperature, topP: topP)
    }
}

// MARK: - Reusable Test Doubles

final class MockLLMService: LLMServiceProtocol {
    var sendMessageResult: String = "Mock response"
    var sendMessageError: Error?
    var availableModelsResult: [LLMModel] = []
    var availableModelsError: Error?
    var validateResult: Bool = true
    var validateError: Error?
    
    private(set) var sendMessageCallCount = 0
    private(set) var availableModelsCallCount = 0
    private(set) var validateCallCount = 0
    
    private(set) var lastSentMessage: String?
    private(set) var lastHistory: [Message]?
    private(set) var lastModel: LLMModel?
    private(set) var lastParameters: ModelParameters?
    private(set) var lastValidatedKey: String?
    
    func sendMessage(_ message: String, history: [Message], model: LLMModel, parameters: ModelParameters) async throws -> String {
        sendMessageCallCount += 1
        lastSentMessage = message
        lastHistory = history
        lastModel = model
        lastParameters = parameters
        
        if let error = sendMessageError {
            throw error
        }
        return sendMessageResult
    }
    
    func availableModels() async throws -> [LLMModel] {
        availableModelsCallCount += 1
        
        if let error = availableModelsError {
            throw error
        }
        return availableModelsResult
    }
    
    func validate(apiKey: String) async throws -> Bool {
        validateCallCount += 1
        lastValidatedKey = apiKey
        
        if let error = validateError {
            throw error
        }
        return validateResult
    }
    
    func reset() {
        sendMessageCallCount = 0
        availableModelsCallCount = 0
        validateCallCount = 0
        lastSentMessage = nil
        lastHistory = nil
        lastModel = nil
        lastParameters = nil
        lastValidatedKey = nil
        sendMessageError = nil
        availableModelsError = nil
        validateError = nil
    }
}

final class MockServiceFactory: LLMServiceFactoryType {
    private let service: LLMServiceProtocol
    private(set) var makeServiceCallCount = 0
    private(set) var lastConfiguration: APIConfiguration?
    
    init(service: LLMServiceProtocol = MockLLMService()) {
        self.service = service
    }
    
    func makeService(configuration: APIConfiguration) -> LLMServiceProtocol {
        makeServiceCallCount += 1
        lastConfiguration = configuration
        return service
    }
    
    func reset() {
        makeServiceCallCount = 0
        lastConfiguration = nil
    }
}

final class MockKeychainService: KeychainServiceType {
    private var storage: [String: String] = [:]
    var shouldThrowOnRead = false
    var shouldThrowOnWrite = false
    var shouldThrowOnDelete = false
    var errorToThrow: Error = AppError.keychain(status: errSecItemNotFound)
    
    private(set) var setAPIKeyCallCount = 0
    private(set) var getAPIKeyCallCount = 0
    private(set) var deleteAPIKeyCallCount = 0
    
    init(initial: [String: String] = [:]) {
        self.storage = initial
    }
    
    func setAPIKey(_ key: String, account: String) throws {
        setAPIKeyCallCount += 1
        if shouldThrowOnWrite {
            throw errorToThrow
        }
        storage[account] = key
    }
    
    func getAPIKey(account: String) throws -> String? {
        getAPIKeyCallCount += 1
        if shouldThrowOnRead {
            throw errorToThrow
        }
        return storage[account]
    }
    
    func deleteAPIKey(account: String) throws {
        deleteAPIKeyCallCount += 1
        if shouldThrowOnDelete {
            throw errorToThrow
        }
        storage.removeValue(forKey: account)
    }
    
    func reset() {
        storage.removeAll()
        shouldThrowOnRead = false
        shouldThrowOnWrite = false
        shouldThrowOnDelete = false
        setAPIKeyCallCount = 0
        getAPIKeyCallCount = 0
        deleteAPIKeyCallCount = 0
    }
}

final class MockNetworkManager: NetworkManaging {
    var requestResult: Any?
    var requestError: Error?
    private(set) var requestCallCount = 0
    private(set) var lastRequest: NetworkRequest?
    
    func request<T>(_ request: NetworkRequest) async throws -> T where T: Decodable {
        requestCallCount += 1
        lastRequest = request
        
        if let error = requestError {
            throw error
        }
        
        guard let result = requestResult as? T else {
            throw AppError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Mock result type mismatch")))
        }
        
        return result
    }
    
    func streamLines(_ request: NetworkRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // By default, finish immediately; tests can subclass/override if needed
            continuation.finish()
        }
    }
    
    func reset() {
        requestResult = nil
        requestError = nil
        requestCallCount = 0
        lastRequest = nil
    }
}

final class MockModelCache: ModelCaching {
    private var cachedModels: [String: (models: [LLMModel], timestamp: Date)] = [:]
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0
    private(set) var lastSavedModels: [LLMModel]?
    private(set) var lastSavedProvider: String?
    private(set) var lastSavedAPIKey: String?
    
    func load(provider: String, apiKey: String, ttl: TimeInterval) -> [LLMModel]? {
        loadCallCount += 1
        let key = cacheKey(provider: provider, apiKey: apiKey)
        
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
        lastSavedProvider = provider
        lastSavedAPIKey = apiKey
        
        let key = cacheKey(provider: provider, apiKey: apiKey)
        cachedModels[key] = (models: models, timestamp: Date())
    }
    
    func clear(provider: String, apiKey: String) {
        clearCallCount += 1
        let key = cacheKey(provider: provider, apiKey: apiKey)
        cachedModels.removeValue(forKey: key)
    }
    
    private func cacheKey(provider: String, apiKey: String) -> String {
        return "\(provider)-\(apiKey.hashValue)"
    }
    
    func reset() {
        cachedModels.removeAll()
        loadCallCount = 0
        saveCallCount = 0
        clearCallCount = 0
        lastSavedModels = nil
        lastSavedProvider = nil
        lastSavedAPIKey = nil
    }
}

final class MockSystemPromptStore: SystemPromptStoring {
    var defaultPrompt: String = "Default test prompt"
    private var overrides: [UUID: String] = [:]
    
    private(set) var setOverrideCallCount = 0
    private(set) var resetOverrideCallCount = 0
    private(set) var removeStaleOverridesCallCount = 0
    
    func override(for conversationID: UUID) -> String? {
        return overrides[conversationID]
    }
    
    func setOverride(_ prompt: String, for conversationID: UUID) {
        setOverrideCallCount += 1
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            resetOverride(for: conversationID)
        } else {
            overrides[conversationID] = trimmed
        }
    }
    
    func resetOverride(for conversationID: UUID) {
        resetOverrideCallCount += 1
        overrides.removeValue(forKey: conversationID)
    }
    
    func resolvePrompt(for conversationID: UUID?) -> String {
        if let id = conversationID, let override = overrides[id] {
            return override
        }
        return defaultPrompt
    }
    
    func removeStaleOverrides(validIDs: Set<UUID>) {
        removeStaleOverridesCallCount += 1
        overrides = overrides.filter { validIDs.contains($0.key) }
    }
    
    func reset() {
        overrides.removeAll()
        setOverrideCallCount = 0
        resetOverrideCallCount = 0
        removeStaleOverridesCallCount = 0
    }
}

final class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    override func data(forKey defaultName: String) -> Data? {
        return storage[defaultName] as? Data
    }
    
    override func dictionary(forKey defaultName: String) -> [String : Any]? {
        return storage[defaultName] as? [String: Any]
    }
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
    
    func clear() {
        storage.removeAll()
    }
}

// MARK: - Test Helpers

extension XCTestCase {
    
    /// Waits for an async operation to complete with a timeout
    func waitForAsyncOperation(timeout: TimeInterval = 1.0, operation: @escaping () async throws -> Void) async throws {
        let expectation = XCTestExpectation(description: "Async operation")
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    /// Asserts that an async operation throws a specific error
    func assertAsyncThrows<T, E: Error & Equatable>(
        _ expectedError: E,
        _ operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected operation to throw \(expectedError)", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected \(type(of: expectedError)) but got \(type(of: error))", file: file, line: line)
        }
    }
    
    /// Asserts that an async operation doesn't throw
    func assertAsyncNoThrow<T>(
        _ operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> T? {
        do {
            return try await operation()
        } catch {
            XCTFail("Expected operation not to throw, but got: \(error)", file: file, line: line)
            return nil
        }
    }
}

// MARK: - Constants for Testing

enum TestConstants {
    static let testAPIKey = "test-api-key-12345"
    static let testProvider = "openai"
    static let testBaseURL = URL(string: "https://api.openai.com/v1")!
    
    static let sampleModels = [
        LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai"),
        LLMModel(id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai"),
        LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: "openai")
    ]
    
    static let sampleMessages = [
        Message(content: "Hello", role: .user),
        Message(content: "Hi there! How can I help you?", role: .assistant),
        Message(content: "What's the weather like?", role: .user)
    ]
    
    static let sampleConversations = [
        Conversation(title: "Weather Chat", lastMessage: "It's sunny today", isActive: true),
        Conversation(title: "Coding Help", lastMessage: "Here's the solution", isActive: false),
        Conversation(title: "General Questions", lastMessage: nil, isActive: false)
    ]
}

// MARK: - Mock OpenAI Response Data

enum MockOpenAIData {
    static func chatResponse(content: String = "Mock response") -> OpenAIService.ChatResponse {
        return OpenAIService.ChatResponse(choices: [
            OpenAIService.ChatResponse.Choice(
                message: OpenAIService.ChatResponse.Choice.Message(
                    role: "assistant",
                    content: content
                )
            )
        ])
    }
    
    static func modelsListResponse(modelIDs: [String] = ["gpt-4o", "gpt-3.5-turbo"]) -> ModelsListResponse {
        return ModelsListResponse(data: modelIDs.map { ModelItem(id: $0) })
    }
    
    struct ModelsListResponse: Decodable {
        let data: [ModelItem]
    }
    
    struct ModelItem: Decodable {
        let id: String
    }
}

// MARK: - Test Extensions

// MARK: - ChatViewModel Test Extensions
// Note: Individual test files should define their own _setTestState methods 
// since _setPreviewState is fileprivate and not accessible across files.

// MARK: - Async Testing Utilities

final class AsyncTestUtilities {
    
    /// Creates an expectation that waits for a published value to change
    static func waitForPublishedValue<T: Equatable>(
        _ publisher: Published<T>.Publisher,
        expectedValue: T,
        timeout: TimeInterval = 1.0
    ) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "Published value change")
        
        let cancellable = publisher
            .filter { $0 == expectedValue }
            .sink { _ in
                expectation.fulfill()
            }
        
        // Keep the cancellable alive
        withExtendedLifetime(cancellable) {}
        
        return expectation
    }
    
    /// Waits for a condition to become true with polling
    static func waitForCondition(
        timeout: TimeInterval = 1.0,
        pollInterval: TimeInterval = 0.1,
        condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        
        throw NSError(domain: "AsyncTestUtilities", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Condition not met within timeout"
        ])
    }
}
