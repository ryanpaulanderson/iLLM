//
//  ModelCacheTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for ModelCache TTL logic and persistence.
//

import XCTest
import CryptoKit
@testable import LLMChat

final class ModelCacheTests: XCTestCase {
    
    // MARK: - Test Doubles
    
    private final class FakeUserDefaults: UserDefaults {
        private var storage: [String: Any] = [:]
        
        override func data(forKey defaultName: String) -> Data? {
            return storage[defaultName] as? Data
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
    
    // MARK: - Test Fixtures
    
    private var cache: ModelCache!
    private var fakeDefaults: FakeUserDefaults!
    
    override func setUp() {
        super.setUp()
        fakeDefaults = FakeUserDefaults()
        cache = ModelCache(defaults: fakeDefaults)
    }
    
    override func tearDown() {
        cache = nil
        fakeDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Save and Load Tests
    
    func test_saveAndLoad_withValidTTL_returnsModels() {
        // Given
        let testModels = [
            LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai"),
            LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: "openai")
        ]
        let provider = "openai"
        let apiKey = "test-api-key"
        let ttl: TimeInterval = 3600 // 1 hour
        
        // When
        cache.save(testModels, provider: provider, apiKey: apiKey)
        let result = cache.load(provider: provider, apiKey: apiKey, ttl: ttl)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].id, "gpt-4o")
        XCTAssertEqual(result?[1].id, "gpt-3.5-turbo")
    }
    
    func test_load_withNonExistentKey_returnsNil() {
        // When
        let result = cache.load(provider: "openai", apiKey: "non-existent", ttl: 3600)
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_load_withExpiredTTL_returnsNil_removesFromCache() {
        // Given
        let testModels = [LLMModel(id: "test", name: "Test", provider: "openai")]
        let provider = "openai"
        let apiKey = "test-key"
        
        cache.save(testModels, provider: provider, apiKey: apiKey)
        
        // When: Load with expired TTL (negative means always expired)
        let result = cache.load(provider: provider, apiKey: apiKey, ttl: -1)
        
        // Then
        XCTAssertNil(result)
        
        // Verify cache entry was removed
        let secondResult = cache.load(provider: provider, apiKey: apiKey, ttl: 3600)
        XCTAssertNil(secondResult)
    }
    
    func test_load_withCorruptedData_returnsNil_removesFromCache() {
        // Given
        let corruptData = "corrupted json data".data(using: .utf8)!
        let provider = "openai"
        let apiKey = "test-key"
        
        // Manually insert corrupted data
        let key = "models.cache.openai." + hashKey(apiKey)
        fakeDefaults.set(corruptData, forKey: key)
        
        // When
        let result = cache.load(provider: provider, apiKey: apiKey, ttl: 3600)
        
        // Then
        XCTAssertNil(result)
        
        // Verify corrupted entry was removed
        XCTAssertNil(fakeDefaults.data(forKey: key))
    }
    
    // MARK: - Key Generation Tests
    
    func test_differentApiKeys_generateDifferentCacheKeys() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        let provider = "openai"
        
        // When
        cache.save(models, provider: provider, apiKey: "key1")
        cache.save(models, provider: provider, apiKey: "key2")
        
        // Then
        let result1 = cache.load(provider: provider, apiKey: "key1", ttl: 3600)
        let result2 = cache.load(provider: provider, apiKey: "key2", ttl: 3600)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(result1?.count, 1)
        XCTAssertEqual(result2?.count, 1)
    }
    
    func test_differentProviders_generateDifferentCacheKeys() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        let apiKey = "same-key"
        
        // When
        cache.save(models, provider: "openai", apiKey: apiKey)
        cache.save(models, provider: "anthropic", apiKey: apiKey)
        
        // Then
        let openaiResult = cache.load(provider: "openai", apiKey: apiKey, ttl: 3600)
        let anthropicResult = cache.load(provider: "anthropic", apiKey: apiKey, ttl: 3600)
        
        XCTAssertNotNil(openaiResult)
        XCTAssertNotNil(anthropicResult)
    }
    
    // MARK: - Clear Tests
    
    func test_clear_removesSpecificCacheEntry() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        let provider = "openai"
        let apiKey = "test-key"
        
        cache.save(models, provider: provider, apiKey: apiKey)
        XCTAssertNotNil(cache.load(provider: provider, apiKey: apiKey, ttl: 3600))
        
        // When
        cache.clear(provider: provider, apiKey: apiKey)
        
        // Then
        XCTAssertNil(cache.load(provider: provider, apiKey: apiKey, ttl: 3600))
    }
    
    func test_clear_onlyRemovesSpecifiedEntry() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        
        cache.save(models, provider: "openai", apiKey: "key1")
        cache.save(models, provider: "openai", apiKey: "key2")
        
        // When
        cache.clear(provider: "openai", apiKey: "key1")
        
        // Then
        XCTAssertNil(cache.load(provider: "openai", apiKey: "key1", ttl: 3600))
        XCTAssertNotNil(cache.load(provider: "openai", apiKey: "key2", ttl: 3600))
    }
    
    // MARK: - TTL Edge Cases
    
    func test_load_withZeroTTL_treatsAsExpired() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        cache.save(models, provider: "openai", apiKey: "test-key")
        
        // When
        let result = cache.load(provider: "openai", apiKey: "test-key", ttl: 0)
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_load_withVeryLargeTTL_returnsModels() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        cache.save(models, provider: "openai", apiKey: "test-key")
        
        // When
        let result = cache.load(provider: "openai", apiKey: "test-key", ttl: TimeInterval.greatestFiniteMagnitude)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
    }
    
    // MARK: - Empty Models Tests
    
    func test_saveAndLoad_withEmptyModelsArray_handlesCorrectly() {
        // Given
        let emptyModels: [LLMModel] = []
        
        // When
        cache.save(emptyModels, provider: "openai", apiKey: "test-key")
        let result = cache.load(provider: "openai", apiKey: "test-key", ttl: 3600)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isEmpty ?? false)
    }
    
    // MARK: - Case Sensitivity Tests
    
    func test_providerNames_areCaseInsensitive() {
        // Given
        let models = [LLMModel(id: "test", name: "Test", provider: "openai")]
        
        // When
        cache.save(models, provider: "OpenAI", apiKey: "test-key")
        let result = cache.load(provider: "openai", apiKey: "test-key", ttl: 3600)
        
        // Then
        XCTAssertNotNil(result) // Should find it despite case difference
    }
    
    // MARK: - Helper Methods
    
    private func hashKey(_ apiKey: String) -> String {
        // This mimics the internal hashing logic for testing corrupted data
        let digest = SHA256.hash(data: Data(apiKey.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
