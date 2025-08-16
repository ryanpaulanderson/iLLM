// LLMChat/Models/Message.swift
import Foundation

enum MessageRole: String, Codable, CaseIterable {
    case system, user, assistant
}

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

    var isFromUser: Bool { role == .user }
}