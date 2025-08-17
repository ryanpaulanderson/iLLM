//
//  ModelCache.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: UserDefaults-backed cache for LLM model lists with TTL support.
//

import Foundation
import CryptoKit

/// Codable wrapper for cached models with timestamp to support TTL eviction.
private struct CachedModels: Codable {
    let models: [LLMModel]
    let timestamp: Date
}

/// UserDefaults-backed model list cache with SHA256-scoped keys.
/// - Note: Stores only a hash of the API key to avoid persisting secrets.
final class ModelCache: ModelCaching {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(provider: String, apiKey: String) -> String {
        let digest = SHA256.hash(data: Data(apiKey.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return "models.cache.\(provider.lowercased()).\(hash)"
    }

    func load(provider: String, apiKey: String, ttl: TimeInterval) -> [LLMModel]? {
        let k = key(provider: provider, apiKey: apiKey)
        guard let data = defaults.data(forKey: k) else { return nil }
        do {
            let cached = try JSONDecoder().decode(CachedModels.self, from: data)
            if Date().timeIntervalSince(cached.timestamp) < ttl {
                return cached.models
            } else {
                defaults.removeObject(forKey: k) // expire
                return nil
            }
        } catch {
            defaults.removeObject(forKey: k) // corrupt
            return nil
        }
    }

    func save(_ models: [LLMModel], provider: String, apiKey: String) {
        let k = key(provider: provider, apiKey: apiKey)
        do {
            let payload = CachedModels(models: models, timestamp: Date())
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: k)
        } catch {
            // Ignore cache write failures
        }
    }

    /// Removes the cached entry for debugging or invalidation scenarios.
    func clear(provider: String, apiKey: String) {
        let k = key(provider: provider, apiKey: apiKey)
        defaults.removeObject(forKey: k)
    }
}