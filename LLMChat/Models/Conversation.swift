//
//  Conversation.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Conversation model for multi-chat support
//

import Foundation

/// Represents a conversation thread in the chat application.
struct Conversation: Identifiable, Codable {
    let id: UUID
    let title: String
    let lastMessage: String?
    let timestamp: Date
    let isActive: Bool
    let lastUsedModelID: String?
    
    /// Creates a new conversation instance
    /// - Parameters:
    ///   - id: Unique identifier for the conversation (defaults to new UUID)
    ///   - title: Display title for the conversation
    ///   - lastMessage: The most recent message in the conversation
    ///   - timestamp: When the conversation was last updated
    ///   - isActive: Whether this is the currently active conversation
    ///   - lastUsedModelID: The ID of the model last used in this conversation
    init(id: UUID = UUID(), title: String, lastMessage: String? = nil, timestamp: Date = Date(), isActive: Bool = false, lastUsedModelID: String? = nil) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.isActive = isActive
        self.lastUsedModelID = lastUsedModelID
    }
}