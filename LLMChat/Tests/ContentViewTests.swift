//
//  ContentViewTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for ContentView bootstrap behavior using MVVM seams.
//

import XCTest
import SwiftUI
import UIKit

@testable import LLMChat

@MainActor
final class ContentViewTests: XCTestCase {

    // MARK: - Fakes

    private final class FakeService: LLMServiceProtocol {
        var availableModelsResult: [LLMModel] = []
        var validateResult: Bool = true

        func sendMessage(_ message: String, history: [Message], model: LLMModel) async throws -> String {
            return "stub"
        }

        func availableModels() async throws -> [LLMModel] {
            return availableModelsResult
        }

        func validate(apiKey: String) async throws -> Bool {
            return validateResult
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
        private var storage: [String: String]

        init(initial: [String: String] = [:]) {
            self.storage = initial
        }

        func setAPIKey(_ key: String, account: String) throws {
            storage[account] = key
        }

        func getAPIKey(account: String) throws -> String? {
            return storage[account]
        }

        func deleteAPIKey(account: String) throws {
            storage.removeValue(forKey: account)
        }
    }

    // MARK: - Helpers

    private func hostInWindow<V: View>(_ view: V) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        // Run the runloop briefly to allow view lifecycle callbacks (onAppear) to fire.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    // MARK: - Tests

    func test_onAppear_bootstrapsViewModel_makesService() {
        // Given
        let fakeService = FakeService()
        let factory = FakeServiceFactory(service: fakeService)
        let keychain = FakeKeychain(initial: ["openai": "TEST_KEY"])
        let chatVM = ChatViewModel(serviceFactory: factory, keychain: keychain)

        // When: Present ContentView so onAppear triggers bootstrap()
        let sut = ContentView().environmentObject(chatVM)
        hostInWindow(sut)

        // Then
        XCTAssertEqual(factory.makeServiceCallCount, 1, "bootstrap should create a service exactly once")
        XCTAssertEqual(factory.lastConfiguration?.apiKey, "TEST_KEY", "bootstrap should read API key from keychain")
        XCTAssertEqual(factory.lastConfiguration?.provider.lowercased(), "openai", "bootstrap should set provider to openai")
    }

    func test_bootstrap_setsSelectedModel_fromAvailableModels() {
        // Given
        let fakeService = FakeService()
        fakeService.availableModelsResult = [
            LLMModel(id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai"),
            LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        ]
        let factory = FakeServiceFactory(service: fakeService)
        let keychain = FakeKeychain(initial: ["openai": "KEY"])
        let chatVM = ChatViewModel(serviceFactory: factory, keychain: keychain)

        // When
        let sut = ContentView().environmentObject(chatVM)
        hostInWindow(sut)

        // Then: bootstrap's async task should pick the first model
        let exp = expectation(description: "selectedModel set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let selected = chatVM.selectedModel {
                XCTAssertEqual(selected.id, "gpt-4o-mini")
            } else {
                XCTFail("selectedModel should be set after bootstrap loads models")
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
}