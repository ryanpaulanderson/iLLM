// LLMChat/ViewModels/ChatViewModel.swift
import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var isSending = false
    @Published var error: AppError?
    @Published var selectedModel: LLMModel?
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    
    // Persistence keys
    private let conversationsKey = "llmchat.conversations"
    private let messagesKeyPrefix = "llmchat.messages."

    private let serviceFactory: LLMServiceFactoryType
    private let keychain: KeychainServiceType
    private var configuration = APIConfiguration()
    private var service: LLMServiceProtocol?

    init(serviceFactory: LLMServiceFactoryType, keychain: KeychainServiceType) {
        self.serviceFactory = serviceFactory
        self.keychain = keychain
    }

    /// Bootstraps the view model by loading persisted API configuration and seeding defaults.
    func bootstrap() {
        let key = (try? keychain.getAPIKey(account: "openai"))
        configuration = APIConfiguration(baseURL: Constants.openAIBaseURL, apiKey: key ?? "", provider: "openai")
        service = serviceFactory.makeService(configuration: configuration)

        // Load persisted conversations
        loadConversations()
        
        // Seed an initial conversation if none exists
        if conversations.isEmpty {
            let newConversation = Conversation(
                title: "New Chat",
                lastMessage: nil,
                timestamp: Date(),
                isActive: true
            )
            conversations = [newConversation]
            currentConversation = newConversation
            saveConversations()
        } else {
            // Select the first active conversation or the first one
            currentConversation = conversations.first { $0.isActive } ?? conversations.first
            // Load messages for the current conversation
            if let currentConversation = currentConversation {
                loadMessages(for: currentConversation)
            }
        }

        Task {
            if selectedModel == nil {
                let svc = service ?? serviceFactory.makeService(configuration: configuration)
                if let models = try? await svc.availableModels() {
                    selectedModel = models.first
                }
            }
        }
    }

    /// Sends a user message, awaits the model reply, and appends both to the chat history.
    /// - Parameter text: The user's message text.
    func send(text: String) async {
        guard let model = selectedModel else { return }
        guard let conversation = currentConversation else { return }
        
        isSending = true
        defer { isSending = false }
        messages.append(Message(content: text, role: .user))
        
        // Save messages after adding user message
        saveMessages(for: conversation)
        
        do {
            let svc = service ?? serviceFactory.makeService(configuration: configuration)
            let reply = try await svc.sendMessage(text, history: messages, model: model)
            messages.append(Message(content: reply, role: .assistant))

            // Update the active conversation's preview
            if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
                let c = conversations[idx]
                conversations[idx] = Conversation(
                    id: c.id,
                    title: c.title,
                    lastMessage: reply,
                    timestamp: Date(),
                    isActive: c.isActive
                )
                saveConversations()
            }
            
            // Save messages after adding assistant message
            saveMessages(for: conversation)
        } catch let appErr as AppError {
            self.error = appErr
        } catch {
            self.error = AppError.unknown(error)
        }
    }

    /// Updates the API key in secure storage and refreshes the service instance.
    /// - Parameter key: The new API key to persist.
    func updateAPIKey(_ key: String) {
        do {
            try keychain.setAPIKey(key, account: "openai")
            configuration.apiKey = key
            service = serviceFactory.makeService(configuration: configuration)
        } catch let appErr as AppError {
            self.error = appErr
        } catch {
            self.error = AppError.unknown(error)
        }
    }
    
    /// Returns the current API key from the secure store for the default provider.
    func currentAPIKey() -> String {
        (try? keychain.getAPIKey(account: "openai")) ?? ""
    }
    
    /// Returns the current API configuration.
    func currentConfiguration() -> APIConfiguration {
        configuration
    }
    
    /// Clears the current conversation messages to start fresh.
    func clearConversation() {
        messages = []
        error = nil  // Also clear any existing error
    }

    /// Starts a brand new conversation and makes it active.
    /// - Returns: The newly created `Conversation`.
    func startNewConversation() -> Conversation {
        clearConversation()
        // Mark existing conversations inactive
        conversations = conversations.map {
            Conversation(id: $0.id,
                         title: $0.title,
                         lastMessage: $0.lastMessage,
                         timestamp: $0.timestamp,
                         isActive: false)
        }
        let newConversation = Conversation(
            title: "New Chat",
            lastMessage: nil,
            timestamp: Date(),
            isActive: true
        )
        // Put newest at the top
        conversations.insert(newConversation, at: 0)
        currentConversation = newConversation
        saveConversations()
        return newConversation
    }
    
    /// Selects a conversation and loads its messages
    /// - Parameter conversation: The conversation to select
    func selectConversation(_ conversation: Conversation) {
        // Mark all conversations as inactive
        conversations = conversations.map {
            Conversation(id: $0.id,
                         title: $0.title,
                         lastMessage: $0.lastMessage,
                         timestamp: $0.timestamp,
                         isActive: $0.id == conversation.id)
        }
        currentConversation = conversation
        loadMessages(for: conversation)
        saveConversations()
    }
    
    // MARK: - Persistence
    
    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
        }
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: conversationsKey)
        }
    }
    
    private func loadMessages(for conversation: Conversation) {
        let key = messagesKeyPrefix + conversation.id.uuidString
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Message].self, from: data) {
            messages = decoded
        } else {
            messages = []
        }
    }
    
    private func saveMessages(for conversation: Conversation) {
        let key = messagesKeyPrefix + conversation.id.uuidString
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

#if DEBUG
// MARK: - Preview Helpers (DEBUG only)
extension ChatViewModel {
    /// Creates a ChatViewModel pre-populated for SwiftUI previews.
    /// - Parameters:
    ///   - messages: Seed transcript messages.
    ///   - isSending: Simulate "thinking" state.
    ///   - selectedModel: Optional model to use.
    /// - Returns: A configured ChatViewModel instance for previews.
    static func preview(messages: [Message] = [],
                        isSending: Bool = false,
                        selectedModel: LLMModel? = nil) -> ChatViewModel {
        let vm = ChatViewModel(serviceFactory: LLMServiceFactory(), keychain: KeychainService())
        vm._setPreviewState(messages: messages, isSending: isSending, selectedModel: selectedModel)
        return vm
    }

    /// Internal-only: mutates private(set) state for previews in the same file.
    fileprivate func _setPreviewState(messages: [Message], isSending: Bool, selectedModel: LLMModel?) {
        self.messages = messages
        self.isSending = isSending
        self.selectedModel = selectedModel
    }
}
#endif