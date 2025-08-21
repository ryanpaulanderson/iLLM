//
//  SystemPromptStoreTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for SystemPromptStore global and per-conversation prompt management.
//

import XCTest
@testable import LLMChat

final class SystemPromptStoreTests: XCTestCase {
    
    // MARK: - Test Doubles
    
    private final class FakeUserDefaults: UserDefaults {
        private var storage: [String: Any] = [:]
        
        override func string(forKey defaultName: String) -> String? {
            return storage[defaultName] as? String
        }
        
        override func set(_ value: Any?, forKey defaultName: String) {
            storage[defaultName] = value
        }
        
        override func removeObject(forKey defaultName: String) {
            storage.removeValue(forKey: defaultName)
        }
        
        override func dictionary(forKey defaultName: String) -> [String : Any]? {
            return storage[defaultName] as? [String: Any]
        }
        
        func clear() {
            storage.removeAll()
        }
    }
    
    // MARK: - Test Fixtures
    
    private var store: SystemPromptStore!
    private var fakeDefaults: FakeUserDefaults!
    
    override func setUp() {
        super.setUp()
        fakeDefaults = FakeUserDefaults()
        store = SystemPromptStore(defaults: fakeDefaults)
    }
    
    override func tearDown() {
        store = nil
        fakeDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Default Prompt Tests
    
    func test_defaultPrompt_withNoStoredValue_returnsConstantsDefault() {
        // When
        let result = store.defaultPrompt
        
        // Then
        XCTAssertEqual(result, Constants.defaultSystemPrompt)
    }
    
    func test_defaultPrompt_withStoredValue_returnsStoredValue() {
        // Given
        fakeDefaults.set("Custom default prompt", forKey: Constants.systemPromptGlobalKey)
        
        // When
        let result = store.defaultPrompt
        
        // Then
        XCTAssertEqual(result, "Custom default prompt")
    }
    
    func test_defaultPrompt_withWhitespaceOnlyValue_returnsConstantsDefault() {
        // Given
        fakeDefaults.set("   \n\t   ", forKey: Constants.systemPromptGlobalKey)
        
        // When
        let result = store.defaultPrompt
        
        // Then
        XCTAssertEqual(result, Constants.defaultSystemPrompt)
    }
    
    func test_setDefaultPrompt_storesValueCorrectly() {
        // Given
        let customPrompt = "You are a helpful coding assistant"
        
        // When
        store.defaultPrompt = customPrompt
        
        // Then
        XCTAssertEqual(fakeDefaults.string(forKey: Constants.systemPromptGlobalKey), customPrompt)
        XCTAssertEqual(store.defaultPrompt, customPrompt)
    }
    
    func test_setDefaultPrompt_withEmptyString_removesStoredValue() {
        // Given
        store.defaultPrompt = "Some prompt"
        XCTAssertNotNil(fakeDefaults.string(forKey: Constants.systemPromptGlobalKey))
        
        // When
        store.defaultPrompt = ""
        
        // Then
        XCTAssertNil(fakeDefaults.string(forKey: Constants.systemPromptGlobalKey))
        XCTAssertEqual(store.defaultPrompt, Constants.defaultSystemPrompt)
    }
    
    func test_setDefaultPrompt_withWhitespaceString_removesStoredValue() {
        // Given
        store.defaultPrompt = "Some prompt"
        
        // When
        store.defaultPrompt = "   \n\t   "
        
        // Then
        XCTAssertNil(fakeDefaults.string(forKey: Constants.systemPromptGlobalKey))
        XCTAssertEqual(store.defaultPrompt, Constants.defaultSystemPrompt)
    }
    
    func test_setDefaultPrompt_withLongPrompt_clampsTo4000Characters() {
        // Given
        let longPrompt = String(repeating: "a", count: 5000)
        
        // When
        store.defaultPrompt = longPrompt
        
        // Then
        let storedPrompt = store.defaultPrompt
        XCTAssertEqual(storedPrompt.count, 4000)
        XCTAssertTrue(storedPrompt.allSatisfy { $0 == "a" })
    }
    
    // MARK: - Conversation Override Tests
    
    func test_setOverride_storesOverrideCorrectly() {
        // Given
        let conversationID = UUID()
        let overridePrompt = "Conversation-specific prompt"
        
        // When
        store.setOverride(overridePrompt, for: conversationID)
        
        // Then
        XCTAssertEqual(store.override(for: conversationID), overridePrompt)
    }
    
    func test_setOverride_withEmptyString_removesOverride() {
        // Given
        let conversationID = UUID()
        store.setOverride("Initial prompt", for: conversationID)
        XCTAssertNotNil(store.override(for: conversationID))
        
        // When
        store.setOverride("", for: conversationID)
        
        // Then
        XCTAssertNil(store.override(for: conversationID))
    }
    
    func test_setOverride_withWhitespaceString_removesOverride() {
        // Given
        let conversationID = UUID()
        store.setOverride("Initial prompt", for: conversationID)
        
        // When
        store.setOverride("   \n\t   ", for: conversationID)
        
        // Then
        XCTAssertNil(store.override(for: conversationID))
    }
    
    func test_setOverride_withLongPrompt_clampsTo4000Characters() {
        // Given
        let conversationID = UUID()
        let longPrompt = String(repeating: "b", count: 5000)
        
        // When
        store.setOverride(longPrompt, for: conversationID)
        
        // Then
        let storedOverride = store.override(for: conversationID)
        XCTAssertEqual(storedOverride?.count, 4000)
        XCTAssertTrue(storedOverride?.allSatisfy { $0 == "b" } ?? false)
    }
    
    func test_resetOverride_removesOverride() {
        // Given
        let conversationID = UUID()
        store.setOverride("Override to remove", for: conversationID)
        XCTAssertNotNil(store.override(for: conversationID))
        
        // When
        store.resetOverride(for: conversationID)
        
        // Then
        XCTAssertNil(store.override(for: conversationID))
    }
    
    func test_override_withNonExistentConversation_returnsNil() {
        // Given
        let conversationID = UUID()
        
        // When
        let result = store.override(for: conversationID)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Resolve Prompt Tests
    
    func test_resolvePrompt_withOverride_returnsOverride() {
        // Given
        let conversationID = UUID()
        store.defaultPrompt = "Global prompt"
        store.setOverride("Override prompt", for: conversationID)
        
        // When
        let result = store.resolvePrompt(for: conversationID)
        
        // Then
        XCTAssertEqual(result, "Override prompt")
    }
    
    func test_resolvePrompt_withoutOverride_returnsDefault() {
        // Given
        let conversationID = UUID()
        store.defaultPrompt = "Global prompt"
        
        // When
        let result = store.resolvePrompt(for: conversationID)
        
        // Then
        XCTAssertEqual(result, "Global prompt")
    }
    
    func test_resolvePrompt_withNilConversationID_returnsDefault() {
        // Given
        store.defaultPrompt = "Global prompt"
        
        // When
        let result = store.resolvePrompt(for: nil)
        
        // Then
        XCTAssertEqual(result, "Global prompt")
    }
    
    func test_resolvePrompt_withEmptyOverride_returnsDefault() {
        // Given
        let conversationID = UUID()
        store.defaultPrompt = "Global prompt"
        
        // Manually set empty override (simulating data corruption or edge case)
        let overrides = [conversationID.uuidString: "   "]
        fakeDefaults.set(overrides, forKey: Constants.systemPromptOverridesKey)
        
        // When
        let result = store.resolvePrompt(for: conversationID)
        
        // Then
        XCTAssertEqual(result, "Global prompt")
    }
    
    // MARK: - Remove Stale Overrides Tests
    
    func test_removeStaleOverrides_removesInvalidConversations() {
        // Given
        let validID1 = UUID()
        let validID2 = UUID()
        let staleID = UUID()
        
        store.setOverride("Valid 1", for: validID1)
        store.setOverride("Valid 2", for: validID2)
        store.setOverride("Stale", for: staleID)
        
        // Verify all are present
        XCTAssertNotNil(store.override(for: validID1))
        XCTAssertNotNil(store.override(for: validID2))
        XCTAssertNotNil(store.override(for: staleID))
        
        // When
        store.removeStaleOverrides(validIDs: Set([validID1, validID2]))
        
        // Then
        XCTAssertNotNil(store.override(for: validID1))
        XCTAssertNotNil(store.override(for: validID2))
        XCTAssertNil(store.override(for: staleID))
    }
    
    func test_removeStaleOverrides_withEmptyValidSet_removesAllOverrides() {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        
        store.setOverride("Override 1", for: id1)
        store.setOverride("Override 2", for: id2)
        
        // When
        store.removeStaleOverrides(validIDs: Set())
        
        // Then
        XCTAssertNil(store.override(for: id1))
        XCTAssertNil(store.override(for: id2))
    }
    
    func test_removeStaleOverrides_withNoOverrides_succeeds() {
        // When & Then
        XCTAssertNoThrow(store.removeStaleOverrides(validIDs: Set([UUID()])))
    }
    
    // MARK: - Multiple Conversations Tests
    
    func test_multipleConversationOverrides_workIndependently() {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        
        // When
        store.setOverride("Prompt 1", for: id1)
        store.setOverride("Prompt 2", for: id2)
        store.setOverride("Prompt 3", for: id3)
        
        // Then
        XCTAssertEqual(store.override(for: id1), "Prompt 1")
        XCTAssertEqual(store.override(for: id2), "Prompt 2")
        XCTAssertEqual(store.override(for: id3), "Prompt 3")
        
        // When: Reset one
        store.resetOverride(for: id2)
        
        // Then: Others remain
        XCTAssertEqual(store.override(for: id1), "Prompt 1")
        XCTAssertNil(store.override(for: id2))
        XCTAssertEqual(store.override(for: id3), "Prompt 3")
    }
}
