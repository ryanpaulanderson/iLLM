//  SystemPromptStore.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Global and per-conversation system prompt storage using UserDefaults.
//

import Foundation

/// Abstraction for storing and resolving system prompts.
protocol SystemPromptStoring {
    /// The global default system prompt. Empty or whitespace values revert to `Constants.defaultSystemPrompt`.
    var defaultPrompt: String { get set }

    /// Returns an override prompt for a given conversation if present.
    /// - Parameter conversationID: The conversation's UUID.
    func override(for conversationID: UUID) -> String?

    /// Sets or clears an override prompt for a given conversation.
    /// - Parameters:
    ///   - prompt: The override prompt. Empty/whitespace clears the override.
    ///   - conversationID: The conversation's UUID.
    func setOverride(_ prompt: String, for conversationID: UUID)

    /// Removes any override for a given conversation.
    /// - Parameter conversationID: The conversation's UUID.
    func resetOverride(for conversationID: UUID)

    /// Resolves the prompt to use for a conversation by preferring the override (when present and non-empty),
    /// otherwise returning the global default.
    /// - Parameter conversationID: Optional conversation UUID.
    func resolvePrompt(for conversationID: UUID?) -> String

    /// Removes stored overrides that no longer correspond to existing conversations.
    /// - Parameter validIDs: The set of conversation IDs that still exist.
    func removeStaleOverrides(validIDs: Set<UUID>)
}

/// UserDefaults-backed store for system prompts.
struct SystemPromptStore: SystemPromptStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Global Prompt

    var defaultPrompt: String {
        get {
            let raw = defaults.string(forKey: Constants.systemPromptGlobalKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if raw.isEmpty { return Constants.defaultSystemPrompt }
            return clamp(raw)
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                defaults.removeObject(forKey: Constants.systemPromptGlobalKey)
            } else {
                defaults.set(clamp(trimmed), forKey: Constants.systemPromptGlobalKey)
            }
        }
    }

    // MARK: - Per-Conversation Overrides

    func override(for conversationID: UUID) -> String? {
        loadOverrides()[conversationID.uuidString]
    }

    func setOverride(_ prompt: String, for conversationID: UUID) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            resetOverride(for: conversationID)
            return
        }
        var map = loadOverrides()
        map[conversationID.uuidString] = clamp(trimmed)
        saveOverrides(map)
    }

    func resetOverride(for conversationID: UUID) {
        var map = loadOverrides()
        map.removeValue(forKey: conversationID.uuidString)
        saveOverrides(map)
    }

    func resolvePrompt(for conversationID: UUID?) -> String {
        if let id = conversationID, let ov = override(for: id) {
            let trimmed = ov.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return clamp(trimmed) }
        }
        return defaultPrompt
    }

    func removeStaleOverrides(validIDs: Set<UUID>) {
        let valid = Set(validIDs.map { $0.uuidString })
        var map = loadOverrides()
        map = map.filter { key, _ in valid.contains(key) }
        saveOverrides(map)
    }

    // MARK: - Helpers

    private func loadOverrides() -> [String: String] {
        (defaults.dictionary(forKey: Constants.systemPromptOverridesKey) as? [String: String]) ?? [:]
    }

    private func saveOverrides(_ map: [String: String]) {
        defaults.set(map, forKey: Constants.systemPromptOverridesKey)
    }

    /// Soft limit system prompts to 4000 characters.
    private func clamp(_ s: String) -> String {
        if s.count <= 4000 { return s }
        let idx = s.index(s.startIndex, offsetBy: 4000)
        return String(s[..<idx])
    }
}