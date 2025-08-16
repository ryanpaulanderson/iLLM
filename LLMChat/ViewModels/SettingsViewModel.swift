// LLMChat/ViewModels/SettingsViewModel.swift
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var provider: String = "openai"

    private let keychain: KeychainServiceType

    init(keychain: KeychainServiceType) {
        self.keychain = keychain
        self.apiKey = (try? keychain.getAPIKey(account: "openai")) ?? ""
    }

    func save() throws {
        try keychain.setAPIKey(apiKey, account: "openai")
    }

    func reset() throws {
        try keychain.deleteAPIKey(account: "openai")
        apiKey = ""
    }
}