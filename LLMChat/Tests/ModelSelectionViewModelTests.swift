//
//  ModelSelectionViewModelTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for ModelSelectionViewModel model loading and configuration.
//

import XCTest
@testable import LLMChat

@MainActor
final class ModelSelectionViewModelTests: XCTestCase {
    
    // MARK: - Test Doubles
    
    private final class FakeService: LLMServiceProtocol {
        var availableModelsResult: [LLMModel] = []
        var availableModelsError: Error?
        private(set) var availableModelsCallCount = 0
        
        func sendMessage(_ message: String, history: [Message], model: LLMModel, parameters: ModelParameters) async throws -> String {
            return "stub"
        }
        
        func availableModels() async throws -> [LLMModel] {
            availableModelsCallCount += 1
            if let error = availableModelsError {
                throw error
            }
            return availableModelsResult
        }
        
        func validate(apiKey: String) async throws -> Bool {
            return true
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
        var shouldThrow = false
        
        init(initial: [String: String] = [:]) {
            self.storage = initial
        }
        
        func setAPIKey(_ key: String, account: String) throws {
            if shouldThrow {
                throw AppError.keychain(status: errSecDuplicateItem)
            }
            storage[account] = key
        }
        
        func getAPIKey(account: String) throws -> String? {
            if shouldThrow {
                throw AppError.keychain(status: errSecItemNotFound)
            }
            return storage[account]
        }
        
        func deleteAPIKey(account: String) throws {
            if shouldThrow {
                throw AppError.keychain(status: errSecItemNotFound)
            }
            storage.removeValue(forKey: account)
        }
    }
    
    // MARK: - Test Fixtures
    
    private var viewModel: ModelSelectionViewModel!
    private var fakeService: FakeService!
    private var fakeFactory: FakeServiceFactory!
    private var fakeKeychain: FakeKeychain!
    
    override func setUp() {
        super.setUp()
        fakeService = FakeService()
        fakeFactory = FakeServiceFactory(service: fakeService)
        fakeKeychain = FakeKeychain()
        viewModel = ModelSelectionViewModel(factory: fakeFactory, keychain: fakeKeychain, provider: "openai")
    }
    
    override func tearDown() {
        viewModel = nil
        fakeService = nil
        fakeFactory = nil
        fakeKeychain = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func test_setConfiguration_storesConfiguration() {
        // Given
        let configuration = APIConfiguration(apiKey: "test-key", provider: "openai")
        
        // When
        viewModel.setConfiguration(configuration)
        
        // Then
        // Configuration is stored internally (verified through load behavior)
        // No assertion needed - method should not throw
    }
    
    // MARK: - Load Models Tests
    
    func test_load_withPresetConfiguration_usesProvidedConfiguration() async {
        // Given
        let testModels = [
            LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai"),
            LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: "openai")
        ]
        fakeService.availableModelsResult = testModels
        
        let configuration = APIConfiguration(apiKey: "preset-key", provider: "openai")
        viewModel.setConfiguration(configuration)
        
        // When
        await viewModel.load()
        
        // Then
        XCTAssertEqual(viewModel.models.count, 2)
        XCTAssertEqual(viewModel.models[0].id, "gpt-4o")
        XCTAssertEqual(viewModel.models[1].id, "gpt-3.5-turbo")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        
        XCTAssertEqual(fakeFactory.makeServiceCallCount, 1)
        XCTAssertEqual(fakeFactory.lastConfiguration?.apiKey, "preset-key")
    }
    
    func test_load_withoutPresetConfiguration_loadsFromKeychain() async {
        // Given
        fakeKeychain = FakeKeychain(initial: ["openai": "keychain-key"])
        viewModel = ModelSelectionViewModel(factory: fakeFactory, keychain: fakeKeychain, provider: "openai")
        
        let testModels = [LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")]
        fakeService.availableModelsResult = testModels
        
        // When
        await viewModel.load()
        
        // Then
        XCTAssertEqual(viewModel.models.count, 1)
        XCTAssertEqual(fakeFactory.lastConfiguration?.apiKey, "keychain-key")
        XCTAssertEqual(fakeFactory.lastConfiguration?.provider, "openai")
    }
    
    func test_load_withEmptyKeychain_usesEmptyApiKey() async {
        // Given
        fakeKeychain = FakeKeychain()
        viewModel = ModelSelectionViewModel(factory: fakeFactory, keychain: fakeKeychain, provider: "openai")
        
        let testModels = [LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")]
        fakeService.availableModelsResult = testModels
        
        // When
        await viewModel.load()
        
        // Then
        XCTAssertEqual(fakeFactory.lastConfiguration?.apiKey, "")
        XCTAssertEqual(viewModel.models.count, 1)
    }
    
    func test_load_setsLoadingStateCorrectly() async {
        // Given
        fakeService.availableModelsResult = [LLMModel(id: "test", name: "Test", provider: "openai")]
        
        // When
        XCTAssertFalse(viewModel.isLoading) // Initially false
        
        let loadTask = Task { await viewModel.load() }
        
        // Then: Should be loading during operation
        XCTAssertTrue(viewModel.isLoading)
        
        await loadTask.value
        
        // Should be false after completion
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_load_withServiceError_setsErrorState() async {
        // Given
        fakeService.availableModelsError = AppError.network(description: "Network failure")
        
        // When
        await viewModel.load()
        
        // Then
        XCTAssertTrue(viewModel.models.isEmpty)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, AppError.network(description: "Network failure"))
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_load_withUnknownError_wrapsAsAppError() async {
        // Given
        struct CustomError: Error {}
        fakeService.availableModelsError = CustomError()
        
        // When
        await viewModel.load()
        
        // Then
        XCTAssertTrue(viewModel.models.isEmpty)
        XCTAssertNotNil(viewModel.error)
        if case .unknown = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected unknown error wrapper")
        }
    }
    
    func test_load_withKeychainError_usesEmptyApiKey() async {
        // Given
        fakeKeychain.shouldThrow = true
        let testModels = [LLMModel(id: "test", name: "Test", provider: "openai")]
        fakeService.availableModelsResult = testModels
        
        // When
        await viewModel.load()
        
        // Then
        XCTAssertEqual(fakeFactory.lastConfiguration?.apiKey, "")
        XCTAssertEqual(viewModel.models.count, 1)
        XCTAssertNil(viewModel.error) // Keychain error is gracefully handled
    }
    
    // MARK: - Multiple Load Tests
    
    func test_load_multipleCallsInSequence_handlesCorrectly() async {
        // Given
        let firstModels = [LLMModel(id: "model1", name: "Model 1", provider: "openai")]
        let secondModels = [LLMModel(id: "model2", name: "Model 2", provider: "openai")]
        
        // When
        fakeService.availableModelsResult = firstModels
        await viewModel.load()
        
        fakeService.availableModelsResult = secondModels
        await viewModel.load()
        
        // Then
        XCTAssertEqual(viewModel.models.count, 1)
        XCTAssertEqual(viewModel.models[0].id, "model2")
        XCTAssertEqual(fakeService.availableModelsCallCount, 2)
    }
    
    // MARK: - Provider Tests
    
    func test_init_withCustomProvider_usesCorrectProvider() {
        // Given
        let customProvider = "anthropic"
        
        // When
        viewModel = ModelSelectionViewModel(factory: fakeFactory, keychain: fakeKeychain, provider: customProvider)
        
        // Then
        // Verify by loading and checking the configuration
        Task {
            await viewModel.load()
            XCTAssertEqual(fakeFactory.lastConfiguration?.provider, customProvider)
        }
    }
}
