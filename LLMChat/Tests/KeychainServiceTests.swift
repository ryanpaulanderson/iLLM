//
//  KeychainServiceTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for KeychainService secure storage operations.
//

import XCTest
import Security
@testable import LLMChat

final class KeychainServiceTests: XCTestCase {
    
    private var service: KeychainService!
    private let testService = "LLMChat.APIKey.Test" // Use different service for testing
    
    override func setUp() {
        super.setUp()
        service = KeychainService()
        
        // Clean up any existing test data
        cleanUpTestKeychain()
    }
    
    override func tearDown() {
        cleanUpTestKeychain()
        service = nil
        super.tearDown()
    }
    
    private func cleanUpTestKeychain() {
        // Clean up test data from keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: testService
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Set API Key Tests
    
    func test_setAPIKey_storesKeySuccessfully() throws {
        // Given
        let testKey = "test-api-key-12345"
        let account = "test-account"
        
        // When
        try service.setAPIKey(testKey, account: account)
        
        // Then
        let retrievedKey = try service.getAPIKey(account: account)
        XCTAssertEqual(retrievedKey, testKey)
    }
    
    func test_setAPIKey_updatesExistingKey() throws {
        // Given
        let account = "test-account"
        try service.setAPIKey("old-key", account: account)
        
        // When
        try service.setAPIKey("new-key", account: account)
        
        // Then
        let retrievedKey = try service.getAPIKey(account: account)
        XCTAssertEqual(retrievedKey, "new-key")
    }
    
    func test_setAPIKey_withEmptyKey_storesEmptyString() throws {
        // Given
        let account = "test-account"
        
        // When
        try service.setAPIKey("", account: account)
        
        // Then
        let retrievedKey = try service.getAPIKey(account: account)
        XCTAssertEqual(retrievedKey, "")
    }
    
    func test_setAPIKey_withUnicodeCharacters_storesAndRetrievesCorrectly() throws {
        // Given
        let unicodeKey = "test-🔑-émojî-key"
        let account = "unicode-test"
        
        // When
        try service.setAPIKey(unicodeKey, account: account)
        
        // Then
        let retrievedKey = try service.getAPIKey(account: account)
        XCTAssertEqual(retrievedKey, unicodeKey)
    }
    
    // MARK: - Get API Key Tests
    
    func test_getAPIKey_withNonExistentAccount_returnsNil() throws {
        // When
        let result = try service.getAPIKey(account: "non-existent-account")
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_getAPIKey_withDifferentAccounts_returnsCorrectKeys() throws {
        // Given
        try service.setAPIKey("openai-key", account: "openai")
        try service.setAPIKey("anthropic-key", account: "anthropic")
        
        // When
        let openaiKey = try service.getAPIKey(account: "openai")
        let anthropicKey = try service.getAPIKey(account: "anthropic")
        
        // Then
        XCTAssertEqual(openaiKey, "openai-key")
        XCTAssertEqual(anthropicKey, "anthropic-key")
    }
    
    // MARK: - Delete API Key Tests
    
    func test_deleteAPIKey_removesExistingKey() throws {
        // Given
        let account = "test-account"
        try service.setAPIKey("key-to-delete", account: account)
        
        // Verify key exists
        XCTAssertNotNil(try service.getAPIKey(account: account))
        
        // When
        try service.deleteAPIKey(account: account)
        
        // Then
        let retrievedKey = try service.getAPIKey(account: account)
        XCTAssertNil(retrievedKey)
    }
    
    func test_deleteAPIKey_withNonExistentAccount_succeeds() throws {
        // When & Then
        XCTAssertNoThrow(try service.deleteAPIKey(account: "non-existent"))
    }
    
    func test_deleteAPIKey_multipleAccounts_deletesOnlySpecified() throws {
        // Given
        try service.setAPIKey("key1", account: "account1")
        try service.setAPIKey("key2", account: "account2")
        
        // When
        try service.deleteAPIKey(account: "account1")
        
        // Then
        XCTAssertNil(try service.getAPIKey(account: "account1"))
        XCTAssertEqual(try service.getAPIKey(account: "account2"), "key2")
    }
    
    // MARK: - Integration Tests
    
    func test_fullCycle_setGetDelete_worksCorrectly() throws {
        // Given
        let account = "full-cycle-test"
        let apiKey = "full-cycle-api-key"
        
        // When & Then: Set
        try service.setAPIKey(apiKey, account: account)
        
        // Get
        let retrievedKey = try service.getAPIKey(account: account)
        XCTAssertEqual(retrievedKey, apiKey)
        
        // Delete
        try service.deleteAPIKey(account: account)
        let deletedKey = try service.getAPIKey(account: account)
        XCTAssertNil(deletedKey)
    }
    
    func test_multipleAccountsIndependence() throws {
        // Given
        let accounts = ["openai", "anthropic", "google", "azure"]
        let keys = ["key1", "key2", "key3", "key4"]
        
        // When: Store keys for all accounts
        for (account, key) in zip(accounts, keys) {
            try service.setAPIKey(key, account: account)
        }
        
        // Then: Verify all keys are stored correctly
        for (account, expectedKey) in zip(accounts, keys) {
            let retrievedKey = try service.getAPIKey(account: account)
            XCTAssertEqual(retrievedKey, expectedKey, "Key for account \(account) should match")
        }
        
        // When: Delete one account
        try service.deleteAPIKey(account: "anthropic")
        
        // Then: Verify only that account is deleted
        XCTAssertNil(try service.getAPIKey(account: "anthropic"))
        XCTAssertEqual(try service.getAPIKey(account: "openai"), "key1")
        XCTAssertEqual(try service.getAPIKey(account: "google"), "key3")
        XCTAssertEqual(try service.getAPIKey(account: "azure"), "key4")
    }
}
