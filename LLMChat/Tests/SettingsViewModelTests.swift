//
//  SettingsViewModelTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for SettingsViewModel API key management.
//

import XCTest
@testable import LLMChat

@MainActor
final class SettingsViewModelTests: XCTestCase {
    
    // MARK: - Test Doubles
    
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
    
    // MARK: - Test Fixtures
    
    private var viewModel: SettingsViewModel!
    private var fakeKeychain: FakeKeychain!
    
    override func setUp() {
        super.setUp()
        fakeKeychain = FakeKeychain()
        viewModel = SettingsViewModel(keychain: fakeKeychain)
    }
    
    override func tearDown() {
        viewModel = nil
        fakeKeychain = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_loadsExistingAPIKey_setsApiKeyProperty() {
        // Given
        fakeKeychain = FakeKeychain(initial: ["openai": "existing-key"])
        
        // When
        viewModel = SettingsViewModel(keychain: fakeKeychain)
        
        // Then
        XCTAssertEqual(viewModel.apiKey, "existing-key")
        XCTAssertEqual(viewModel.provider, "openai")
    }
    
    func test_init_withNoExistingKey_setsEmptyApiKey() {
        // Given
        fakeKeychain = FakeKeychain()
        
        // When
        viewModel = SettingsViewModel(keychain: fakeKeychain)
        
        // Then
        XCTAssertEqual(viewModel.apiKey, "")
        XCTAssertEqual(viewModel.provider, "openai")
    }
    
    func test_init_handlesKeychainReadError_setsEmptyApiKey() {
        // Given
        fakeKeychain = FakeKeychain()
        fakeKeychain.shouldThrowOnRead = true
        
        // When
        viewModel = SettingsViewModel(keychain: fakeKeychain)
        
        // Then
        XCTAssertEqual(viewModel.apiKey, "")
    }
    
    // MARK: - Save Tests
    
    func test_save_storesApiKeyInKeychain() throws {
        // Given
        viewModel.apiKey = "new-test-key"
        
        // When
        try viewModel.save()
        
        // Then
        XCTAssertEqual(try fakeKeychain.getAPIKey(account: "openai"), "new-test-key")
    }
    
    func test_save_withKeychainError_throwsError() {
        // Given
        fakeKeychain.shouldThrowOnWrite = true
        viewModel.apiKey = "test-key"
        
        // When & Then
        XCTAssertThrowsError(try viewModel.save()) { error in
            XCTAssertTrue(error is AppError)
            if case .keychain = error as? AppError {
                // Expected error type
            } else {
                XCTFail("Expected keychain error")
            }
        }
    }
    
    func test_save_withEmptyApiKey_storesEmptyString() throws {
        // Given
        viewModel.apiKey = ""
        
        // When
        try viewModel.save()
        
        // Then
        XCTAssertEqual(try fakeKeychain.getAPIKey(account: "openai"), "")
    }
    
    // MARK: - Reset Tests
    
    func test_reset_deletesApiKeyFromKeychain_clearsProperty() throws {
        // Given
        fakeKeychain = FakeKeychain(initial: ["openai": "existing-key"])
        viewModel = SettingsViewModel(keychain: fakeKeychain)
        XCTAssertEqual(viewModel.apiKey, "existing-key") // Verify setup
        
        // When
        try viewModel.reset()
        
        // Then
        XCTAssertNil(try fakeKeychain.getAPIKey(account: "openai"))
        XCTAssertEqual(viewModel.apiKey, "")
    }
    
    func test_reset_withKeychainError_throwsError() {
        // Given
        fakeKeychain.shouldThrowOnDelete = true
        viewModel.apiKey = "some-key"
        
        // When & Then
        XCTAssertThrowsError(try viewModel.reset()) { error in
            XCTAssertTrue(error is AppError)
            if case .keychain = error as? AppError {
                // Expected error type
            } else {
                XCTFail("Expected keychain error")
            }
        }
    }
    
    func test_reset_whenNoKeyExists_succeeds() throws {
        // Given
        viewModel.apiKey = "some-value-to-clear"
        
        // When
        try viewModel.reset()
        
        // Then
        XCTAssertEqual(viewModel.apiKey, "")
    }
}
