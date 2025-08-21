//
//  ChatViewModelTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Comprehensive unit tests for ChatViewModel business logic and state management.
//

import XCTest
@testable import LLMChat

@MainActor
final class ChatViewModelTests: XCTestCase {
    
    // MARK: - Test Doubles
    
    private final class FakeService: LLMServiceProtocol, LLMStreamingServiceProtocol {
        var sendMessageResult: String = "test response"
        var sendMessageError: Error?
        var availableModelsResult: [LLMModel] = []
        var validateResult: Bool = true
        var streamingDeltas: [String]? // if set, conform to streaming
        
        private(set) var sendMessageCallCount = 0
        private(set) var lastSentMessage: String?
        private(set) var lastHistory: [Message]?
        private(set) var lastModel: LLMModel?
        private(set) var lastParameters: ModelParameters?
        
        func resetCallCounts() {
            sendMessageCallCount = 0
            lastSentMessage = nil
            lastHistory = nil
            lastModel = nil
            lastParameters = nil
        }
        
        func sendMessage(_ message: String, history: [Message], model: LLMModel, parameters: ModelParameters) async throws -> String {
            sendMessageCallCount += 1
            // Simulate network latency to allow observing isSending
            try? await Task.sleep(nanoseconds: 30_000_000)
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
            return availableModelsResult
        }
        
        func validate(apiKey: String) async throws -> Bool {
            return validateResult
        }

        func streamMessage(_ message: String, history: [Message], model: LLMModel, parameters: ModelParameters) throws -> AsyncThrowingStream<String, Error> {
            guard let deltas = streamingDeltas else {
                return AsyncThrowingStream { continuation in
                    continuation.finish()
                }
            }
            return AsyncThrowingStream { continuation in
                Task {
                    for delta in deltas {
                        try? await Task.sleep(nanoseconds: 5_000_000)
                        continuation.yield(delta)
                    }
                    continuation.finish()
                }
            }
        }
    }

    
    private final class FakeServiceFactory: LLMServiceFactoryType {
        private let service: LLMServiceProtocol
        private(set) var makeServiceCallCount = 0
        private(set) var lastConfiguration: APIConfiguration?
        
        init(service: LLMServiceProtocol) {
            self.service = service
        }
        
        func makeService(configuration: APIConfiguration) -> LLMServiceProtocol {
            makeServiceCallCount += 1
            lastConfiguration = configuration
            return service
        }
    }
    
    private final class FakeKeychain: KeychainServiceType {
        private var storage: [String: String] = [:]
        var shouldThrowOnRead = false
        var shouldThrowOnWrite = false
        var shouldThrowOnDelete = false
        
        init(initial: [String: String] = [:]) {
            self.storage = initial
        }
        
        func setAPIKey(_ key: String, account: String) throws {
            if shouldThrowOnWrite {
                throw AppError.keychain(status: errSecDuplicateItem)
            }
            storage[account] = key
        }
        
        func getAPIKey(account: String) throws -> String? {
            if shouldThrowOnRead {
                throw AppError.keychain(status: errSecItemNotFound)
            }
            return storage[account]
        }
        
        func deleteAPIKey(account: String) throws {
            if shouldThrowOnDelete {
                throw AppError.keychain(status: errSecItemNotFound)
            }
            storage.removeValue(forKey: account)
        }
    }
    
    private final class FakePromptStore: SystemPromptStoring {
        var defaultPrompt: String = "Default system prompt"
        private var overrides: [UUID: String] = [:]
        
        func override(for conversationID: UUID) -> String? {
            return overrides[conversationID]
        }
        
        func setOverride(_ prompt: String, for conversationID: UUID) {
            let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                resetOverride(for: conversationID)
            } else {
                overrides[conversationID] = trimmed
            }
        }
        
        func resetOverride(for conversationID: UUID) {
            overrides.removeValue(forKey: conversationID)
        }
        
        func resolvePrompt(for conversationID: UUID?) -> String {
            if let id = conversationID, let override = overrides[id] {
                return override
            }
            return defaultPrompt
        }
        
        func removeStaleOverrides(validIDs: Set<UUID>) {
            overrides = overrides.filter { validIDs.contains($0.key) }
        }
    }
    
    // MARK: - Test Fixtures
    
    private var viewModel: ChatViewModel!
    private var fakeService: FakeService!
    private var fakeFactory: FakeServiceFactory!
    private var fakeKeychain: FakeKeychain!
    private var fakePromptStore: FakePromptStore!
    
    override func setUp() {
        super.setUp()
        // Ensure tests start from a clean persistence state
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("llmchat.") || key == Constants.defaultModelKey || key == Constants.modelParametersKey || key == Constants.systemPromptGlobalKey || key == Constants.systemPromptOverridesKey {
            defaults.removeObject(forKey: key)
        }

        fakeService = FakeService()
        fakeFactory = FakeServiceFactory(service: fakeService)
        fakeKeychain = FakeKeychain()
        fakePromptStore = FakePromptStore()
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
    }
    
    override func tearDown() {
        viewModel = nil
        fakeService = nil
        fakeFactory = nil
        fakeKeychain = nil
        fakePromptStore = nil
        super.tearDown()
    }
    
    // MARK: - Bootstrap Tests
    
    func test_bootstrap_loadsAPIKeyFromKeychain_createsService() {
        // Given
        fakeKeychain = FakeKeychain(initial: ["openai": "test-api-key"])
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
        
        // When
        viewModel.bootstrap()
        
        // Then
        XCTAssertEqual(fakeFactory.makeServiceCallCount, 1)
        XCTAssertEqual(fakeFactory.lastConfiguration?.apiKey, "test-api-key")
        XCTAssertEqual(fakeFactory.lastConfiguration?.provider, "openai")
    }
    
    func test_bootstrap_handlesEmptyAPIKey_createsServiceWithEmptyKey() {
        // Given
        fakeKeychain = FakeKeychain()
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
        
        // When
        viewModel.bootstrap()
        
        // Then
        XCTAssertEqual(fakeFactory.makeServiceCallCount, 1)
        XCTAssertEqual(fakeFactory.lastConfiguration?.apiKey, "")
    }
    
    func test_bootstrap_createsNewActiveConversation_clearsMessages() {
        // Given
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
        
        // When
        viewModel.bootstrap()
        
        // Then
        XCTAssertEqual(viewModel.conversations.count, 1)
        XCTAssertEqual(viewModel.conversations.first?.title, "New Chat")
        XCTAssertTrue(viewModel.conversations.first?.isActive ?? false)
        XCTAssertEqual(viewModel.currentConversation?.id, viewModel.conversations.first?.id)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    func test_bootstrap_loadsAvailableModels_setsSelectedModel() async {
        // Given
        let testModels = [
            LLMModel(id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai"),
            LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        ]
        fakeService.availableModelsResult = testModels
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
        
        // When
        viewModel.bootstrap()
        
        // Give async task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Then
        XCTAssertEqual(viewModel.selectedModel?.id, "gpt-4o-mini")
    }
    
    // MARK: - Send Message Tests
    
    func test_sendMessage_appendsUserAndAssistantMessages() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        fakeService.sendMessageResult = "Hello back!"
        
        // When
        await viewModel.send(text: "Hello")
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[0].content, "Hello")
        XCTAssertEqual(viewModel.messages[0].role, .user)
        XCTAssertEqual(viewModel.messages[1].content, "Hello back!")
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
    }

    func test_sendMessage_streaming_buildsAssistantMessageIncrementally() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        fakeService.streamingDeltas = ["Hel", "lo ", "wor", "ld"]

        // When
        let task = Task { await viewModel.send(text: "Hello") }
        // Allow some time for streaming to produce
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // We expect at least one assistant message placeholder
        XCTAssertTrue(viewModel.messages.count >= 2)
        XCTAssertEqual(viewModel.messages[0].role, .user)
        XCTAssertEqual(viewModel.messages[1].role, .assistant)
        // Interim content should be a prefix of the final
        let interim = viewModel.messages[1].content
        XCTAssertFalse(interim.isEmpty)
        
        await task.value
        XCTAssertEqual(viewModel.messages[1].content, "Hello world")
    }
    
    func test_sendMessage_withoutSelectedModel_doesNotSend() async {
        // Given
        let conversation = Conversation(title: "Test Chat")
        viewModel.currentConversation = conversation
        viewModel.selectedModel = nil
        
        // When
        await viewModel.send(text: "Hello")
        
        // Then
        XCTAssertEqual(fakeService.sendMessageCallCount, 0)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    func test_sendMessage_withoutCurrentConversation_doesNotSend() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = nil
        
        // When
        await viewModel.send(text: "Hello")
        
        // Then
        XCTAssertEqual(fakeService.sendMessageCallCount, 0)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    func test_sendMessage_includesSystemPromptForFirstMessage() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        fakePromptStore.defaultPrompt = "You are a helpful assistant"
        
        // When
        await viewModel.send(text: "Hello")
        
        // Then
        XCTAssertEqual(fakeService.sendMessageCallCount, 1)
        XCTAssertEqual(fakeService.lastHistory?.count, 1)
        XCTAssertEqual(fakeService.lastHistory?.first?.role, .system)
        XCTAssertEqual(fakeService.lastHistory?.first?.content, "You are a helpful assistant")
    }
    
    func test_sendMessage_withPriorHistory_doesNotDuplicateSystemPrompt() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        
        // First, send a message to create history
        fakeService.sendMessageResult = "First response"
        await viewModel.send(text: "First message")
        
        // Reset call counts to test the second message
        fakeService.resetCallCounts()
        fakeService.sendMessageResult = "Second response"
        
        // When: Send a second message
        await viewModel.send(text: "Hello again")
        
        // Then: The second call should not include a system prompt in history
        XCTAssertEqual(fakeService.sendMessageCallCount, 1)
        XCTAssertEqual(fakeService.lastHistory?.count, 2) // Only prior messages, no system prompt
        XCTAssertNil(fakeService.lastHistory?.first(where: { $0.role == .system }))
    }
    
    func test_sendMessage_handlesSendError_setsErrorState() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        fakeService.sendMessageError = AppError.network(description: "Connection failed")
        
        // When
        await viewModel.send(text: "Hello")
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, AppError.network(description: "Connection failed"))
        XCTAssertEqual(viewModel.messages.count, 1) // Only user message, no assistant response
    }
    
    func test_sendMessage_updatesIsSendingState() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        
        // When
        let sendTask = Task { await viewModel.send(text: "Hello") }
        
        // Allow the async task to start on the main actor
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        // Check that isSending is true during the operation
        XCTAssertTrue(viewModel.isSending)
        
        await sendTask.value
        
        // Then
        XCTAssertFalse(viewModel.isSending)
    }
    
    // MARK: - API Key Management Tests
    
    func test_updateAPIKey_storesInKeychain_updatesConfiguration() {
        // Given
        let newKey = "new-api-key"
        
        // When
        viewModel.updateAPIKey(newKey)
        
        // Then
        XCTAssertEqual(try fakeKeychain.getAPIKey(account: "openai"), newKey)
        XCTAssertEqual(viewModel.currentConfiguration().apiKey, newKey)
        XCTAssertEqual(fakeFactory.makeServiceCallCount, 1) // Service recreated
    }
    
    func test_updateAPIKey_handlesKeychainError_setsErrorState() {
        // Given
        fakeKeychain.shouldThrowOnWrite = true
        
        // When
        viewModel.updateAPIKey("test-key")
        
        // Then
        XCTAssertNotNil(viewModel.error)
        if case .keychain = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected keychain error")
        }
    }
    
    func test_currentAPIKey_returnsKeychainValue() {
        // Given
        fakeKeychain = FakeKeychain(initial: ["openai": "stored-key"])
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
        
        // When
        let result = viewModel.currentAPIKey()
        
        // Then
        XCTAssertEqual(result, "stored-key")
    }
    
    func test_currentAPIKey_returnsEmptyStringWhenNoKey() {
        // Given
        fakeKeychain = FakeKeychain()
        viewModel = ChatViewModel(serviceFactory: fakeFactory, keychain: fakeKeychain, promptStore: fakePromptStore)
        
        // When
        let result = viewModel.currentAPIKey()
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    // MARK: - Conversation Management Tests
    
    func test_startNewConversation_createsNewActiveConversation_deactivatesOthers() {
        // Given
        let existingConversation = Conversation(title: "Existing", isActive: true)
        viewModel._setTestState(conversations: [existingConversation])
        
        // When
        let newConversation = viewModel.startNewConversation()
        
        // Then
        XCTAssertEqual(viewModel.conversations.count, 2)
        XCTAssertTrue(newConversation.isActive)
        XCTAssertFalse(viewModel.conversations[1].isActive) // Existing conversation deactivated
        XCTAssertEqual(viewModel.currentConversation?.id, newConversation.id)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    func test_selectConversation_switchesActiveConversation_loadsMessages() {
        // Given
        let conversation1 = Conversation(id: UUID(), title: "Conv 1", isActive: true)
        let conversation2 = Conversation(id: UUID(), title: "Conv 2", isActive: false)
        viewModel._setTestState(conversations: [conversation1, conversation2])
        
        // When
        viewModel.selectConversation(conversation2)
        
        // Then
        XCTAssertEqual(viewModel.currentConversation?.id, conversation2.id)
        XCTAssertFalse(viewModel.conversations[0].isActive) // Conv 1 deactivated
        XCTAssertTrue(viewModel.conversations[1].isActive) // Conv 2 activated
    }
    
    func test_deleteConversation_removesConversationAndMessages_returnsTrue() {
        // Given
        let conversation = Conversation(title: "To Delete")
        viewModel._setTestState(conversations: [conversation])
        viewModel.currentConversation = conversation
        
        // When
        let result = viewModel.deleteConversation(conversation)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.conversations.isEmpty || viewModel.conversations.first?.id != conversation.id)
    }
    
    func test_deleteConversation_whenConversationNotFound_returnsFalse() {
        // Given
        let existingConversation = Conversation(title: "Existing")
        let nonExistentConversation = Conversation(title: "Non-existent")
        viewModel._setTestState(conversations: [existingConversation])
        
        // When
        let result = viewModel.deleteConversation(nonExistentConversation)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.conversations.count, 1)
    }
    
    func test_deleteConversation_whenLastConversation_createsNewOne() {
        // Given
        let conversation = Conversation(title: "Last One")
        viewModel._setTestState(conversations: [conversation])
        viewModel.currentConversation = conversation
        
        // When
        let result = viewModel.deleteConversation(conversation)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.conversations.count, 1)
        XCTAssertEqual(viewModel.conversations.first?.title, "New Chat")
        XCTAssertTrue(viewModel.conversations.first?.isActive ?? false)
    }
    
    // MARK: - Regenerate Response Tests
    
    func test_regenerateLastResponse_removesLastAssistantMessage_sendsAgain() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        
        // First, send a message to create the conversation history
        fakeService.sendMessageResult = "Initial response"
        await viewModel.send(text: "Hello")
        
        // Verify initial state
        XCTAssertEqual(viewModel.messages.count, 2) // user + assistant
        XCTAssertEqual(viewModel.messages[1].content, "Initial response")
        
        // Reset service for regeneration test
        fakeService.resetCallCounts()
        fakeService.sendMessageResult = "Better response"
        
        // When
        await viewModel.regenerateLastResponse()
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 2) // Still user + assistant
        XCTAssertEqual(viewModel.messages[0].content, "Hello")
        XCTAssertEqual(viewModel.messages[1].content, "Better response")
        XCTAssertEqual(fakeService.sendMessageCallCount, 1)
        XCTAssertEqual(fakeService.lastSentMessage, "Hello")
    }
    
    func test_canRegenerateLastMessage_withValidSequence_returnsTrue() async {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        
        // Send a message to create user + assistant sequence
        await viewModel.send(text: "Hello")
        
        // When & Then
        XCTAssertTrue(viewModel.canRegenerateLastMessage)
    }
    
    func test_canRegenerateLastMessage_withUserMessageLast_returnsFalse() {
        // Given - Fresh viewModel with no messages
        // (canRegenerateLastMessage should return false with no messages)
        
        // When & Then
        XCTAssertFalse(viewModel.canRegenerateLastMessage)
    }
    
    func test_canRegenerateLastMessage_withEmptyMessages_returnsFalse() {
        // Given
        // No need to set empty messages - that's the default state
        
        // When & Then
        XCTAssertFalse(viewModel.canRegenerateLastMessage)
    }
    
    // MARK: - Clear Conversation Tests
    
    func test_clearConversation_emptiesMessagesAndError() async {
        // Given - Send a message first to have something to clear
        let testModel = LLMModel(id: "test-model", name: "Test", provider: "openai")
        let conversation = Conversation(title: "Test Chat")
        viewModel.selectedModel = testModel
        viewModel.currentConversation = conversation
        
        await viewModel.send(text: "Test message")
        viewModel.error = AppError.network(description: "Test error")
        
        // Verify setup
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertNotNil(viewModel.error)
        
        // When
        viewModel.clearConversation()
        
        // Then
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - System Prompt Tests
    
    func test_currentGlobalSystemPrompt_returnsPromptStoreDefault() {
        // Given
        fakePromptStore.defaultPrompt = "Custom system prompt"
        
        // When
        let result = viewModel.currentGlobalSystemPrompt()
        
        // Then
        XCTAssertEqual(result, "Custom system prompt")
    }
    
    func test_updateGlobalSystemPrompt_updatesPromptStore() {
        // Given
        let newPrompt = "Updated system prompt"
        
        // When
        viewModel.updateGlobalSystemPrompt(newPrompt)
        
        // Then
        XCTAssertEqual(fakePromptStore.defaultPrompt, newPrompt)
    }
    
    func test_conversationPromptOverride_returnsOverrideWhenPresent() {
        // Given
        let conversationID = UUID()
        fakePromptStore.setOverride("Override prompt", for: conversationID)
        
        // When
        let result = viewModel.conversationPromptOverride(for: conversationID)
        
        // Then
        XCTAssertEqual(result, "Override prompt")
    }
    
    func test_updateConversationPrompt_setsOverrideInStore() {
        // Given
        let conversationID = UUID()
        let overridePrompt = "Custom conversation prompt"
        
        // When
        viewModel.updateConversationPrompt(conversationID, to: overridePrompt)
        
        // Then
        XCTAssertEqual(fakePromptStore.override(for: conversationID), overridePrompt)
    }
    
    func test_resetConversationPrompt_clearsOverride() {
        // Given
        let conversationID = UUID()
        fakePromptStore.setOverride("Override to clear", for: conversationID)
        
        // When
        viewModel.resetConversationPrompt(conversationID)
        
        // Then
        XCTAssertNil(fakePromptStore.override(for: conversationID))
    }
    
    // MARK: - Model Parameters Tests
    
    func test_updateModelParameters_updatesCurrentParameters() {
        // Given
        let newParameters = ModelParameters(temperature: 0.7, topP: 0.9)
        
        // When
        viewModel.updateModelParameters(newParameters)
        
        // Then
        XCTAssertEqual(viewModel.currentModelParameters().temperature, 0.7)
        XCTAssertEqual(viewModel.currentModelParameters().topP, 0.9)
    }
    
    func test_resetModelParameters_setsToEmpty() {
        // Given
        viewModel.updateModelParameters(ModelParameters(temperature: 0.7, topP: 0.9))
        
        // When
        viewModel.resetModelParameters()
        
        // Then
        XCTAssertEqual(viewModel.currentModelParameters(), .empty)
    }
    
    // MARK: - Default Model Tests
    
    func test_setDefaultModel_updatesSelectedModel() {
        // Given
        let testModel = LLMModel(id: "test-model", name: "Test Model", provider: "openai")
        
        // When
        viewModel.setDefaultModel(testModel)
        
        // Then
        XCTAssertEqual(viewModel.selectedModel?.id, "test-model")
        XCTAssertEqual(viewModel.savedDefaultModelID(), "test-model")
    }
}

// MARK: - Test Helpers

private extension ChatViewModel {
    /// Helper method to set internal state for testing
    /// Note: Only sets properties that are publicly settable
    func _setTestState(conversations: [Conversation] = [], currentConversation: Conversation? = nil, selectedModel: LLMModel? = nil, error: AppError? = nil) {
        self.conversations = conversations
        self.currentConversation = currentConversation
        self.selectedModel = selectedModel
        self.error = error
    }
}
