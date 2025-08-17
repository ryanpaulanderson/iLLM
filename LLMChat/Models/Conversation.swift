//
//  Conversation.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Conversation model for multi-chat support skeleton
//

import Foundation

struct Conversation: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let lastMessage: String?
    let timestamp: Date
    let isActive: Bool
    
    init(title: String, lastMessage: String? = nil, timestamp: Date = Date(), isActive: Bool = false) {
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.isActive = isActive
    }
}

// MARK: - Mock Data
extension Conversation {
    static let mockConversations: [Conversation] = [
        Conversation(
            title: "Current Chat",
            lastMessage: "This is the active conversation",
            timestamp: Date(),
            isActive: true
        ),
        Conversation(
            title: "Previous Discussion",
            lastMessage: "Thanks for the help!",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Conversation(
            title: "Code Review",
            lastMessage: "The implementation looks good",
            timestamp: Date().addingTimeInterval(-7200)
        )
    ]
}