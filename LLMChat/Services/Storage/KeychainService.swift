// LLMChat/Services/Storage/KeychainService.swift
import Foundation
import Security

/// Minimal interface for securely storing and retrieving API keys.
protocol KeychainServiceType {
    /// Stores or updates the API key for a given account.
    /// - Parameters:
    ///   - key: API key plaintext. Callers must avoid logging this value.
    ///   - account: Namespaces the key (e.g., provider identifier).
    func setAPIKey(_ key: String, account: String) throws

    /// Retrieves the API key for a given account.
    /// - Parameter account: Provider identifier used as the account name.
    /// - Returns: The API key string if present; otherwise nil.
    func getAPIKey(account: String) throws -> String?

    /// Deletes the API key for a given account.
    /// - Parameter account: Provider identifier used as the account name.
    func deleteAPIKey(account: String) throws
}

final class KeychainService: KeychainServiceType {
    private let service = "LLMChat.APIKey"

    /// Stores or updates the API key for a given account in the Keychain.
    /// - Parameters:
    ///   - key: API key plaintext.
    ///   - account: Account name (e.g., provider id).
    func setAPIKey(_ key: String, account: String) throws {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw AppError.keychain(status: status) }
    }

    /// Fetches the API key for the specified account from the Keychain.
    /// - Parameter account: Account name (e.g., provider id).
    /// - Returns: Key string if found; otherwise nil.
    func getAPIKey(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw AppError.keychain(status: status) }
        guard let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Deletes the API key for the specified account from the Keychain.
    /// - Parameter account: Account name (e.g., provider id).
    func deleteAPIKey(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw AppError.keychain(status: status) }
    }
}