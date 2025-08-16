// LLMChat/Models/Message.swift
import Foundation

/// Role of a chat message emitted by the system, user, or assistant.
enum MessageRole: String, Codable, CaseIterable {
    case system, user, assistant
}

 /// Represents a single chat transcript entry.
struct Message: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date

    init(id: UUID = UUID(), content: String, role: MessageRole, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }

    /// Convenience flag indicating whether this message was authored by the end user.
    var isFromUser: Bool { role == .user }
}