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
    @Published private(set) var modelParameters: ModelParameters = .empty
    
    // Persistence keys
    private let conversationsKey = "llmchat.conversations"
    private let messagesKeyPrefix = "llmchat.messages."

    private let serviceFactory: LLMServiceFactoryType
    private let keychain: KeychainServiceType
    private var promptStore: SystemPromptStoring
    private var configuration = APIConfiguration()
    private var service: LLMServiceProtocol?

    init(serviceFactory: LLMServiceFactoryType, keychain: KeychainServiceType, promptStore: SystemPromptStoring = SystemPromptStore()) {
        self.serviceFactory = serviceFactory
        self.keychain = keychain
        self.promptStore = promptStore
    }

    /// Bootstraps the view model by loading persisted API configuration and seeding defaults.
    func bootstrap() {
        let key = (try? keychain.getAPIKey(account: "openai"))
        configuration = APIConfiguration(baseURL: Constants.openAIBaseURL, apiKey: key ?? "", provider: "openai")
        service = serviceFactory.makeService(configuration: configuration)

        // Load persisted conversations so the user can access them
        loadConversations()
        // Mark all existing conversations inactive
        conversations = conversations.map { c in
            Conversation(id: c.id,
                         title: c.title,
                         lastMessage: c.lastMessage,
                         timestamp: c.timestamp,
                         isActive: false,
                         lastUsedModelID: c.lastUsedModelID)
        }
        // Always start a brand-new active conversation at the top
        let defaultModelID = UserDefaults.standard.string(forKey: Constants.defaultModelKey)
        let newConversation = Conversation(
            title: "New Chat",
            lastMessage: nil,
            timestamp: Date(),
            isActive: true,
            lastUsedModelID: defaultModelID
        )
        conversations.insert(newConversation, at: 0)
        currentConversation = newConversation
        messages = []
        saveConversations()

        // Load model parameters
        loadModelParameters()

        Task {
            if selectedModel == nil {
                let svc = service ?? serviceFactory.makeService(configuration: configuration)
                if let models = try? await svc.availableModels() {
                    // Restore the model for the current conversation if we have a lastUsedModelID
                    if let currentConversation = currentConversation, let modelID = currentConversation.lastUsedModelID {
                        await restoreModelForConversation(modelID: modelID)
                    } else {
                        // Fallback: Try to load saved default model first
                        if let savedModel = loadDefaultModel(from: models) {
                            selectedModel = savedModel
                        } else {
                            selectedModel = models.first
                        }
                    }
                }
            }
        }
    }

    /// Sends a user message, awaits the model reply, and appends both to the chat history.
    /// - Parameter text: The user's message text.
    func send(text: String) async {
        guard let model = selectedModel else { return }
        guard let conversation = currentConversation else { return }

        // Build wire history BEFORE appending the new user message to the UI transcript.
        let prior = messages
        var wireHistory = prior
        if prior.isEmpty {
            // Seed a system prompt only for a brand-new conversation
            let systemPrompt = promptStore.resolvePrompt(for: conversation.id)
            wireHistory.insert(Message(content: systemPrompt, role: .system), at: 0)
        }

        isSending = true
        // Yield to allow observers (tests/UI) to observe the sending state
        await Task.yield()
        defer { isSending = false }

        // Show the user's message immediately in the UI
        messages.append(Message(content: text, role: .user))
        // Persist after appending the user message
        saveMessages(for: conversation)

        do {
            let svc = service ?? serviceFactory.makeService(configuration: configuration)
            // Prefer streaming when available
            if let streaming = svc as? LLMStreamingServiceProtocol {
                var accumulated = ""
                var receivedAnyDelta = false
                // Append a placeholder assistant message we will mutate as chunks arrive
                messages.append(Message(content: "", role: .assistant))
                do {
                    let stream = try streaming.streamMessage(text, history: wireHistory, model: model, parameters: modelParameters)
                    for try await delta in stream {
                        receivedAnyDelta = true
                        accumulated += delta
                        // Update the last assistant message in place for real-time UI updates
                        if let lastIndex = messages.indices.last, messages[lastIndex].role == .assistant {
                            messages[lastIndex] = Message(content: accumulated, role: .assistant)
                        }
                    }
                } catch {
                    // Swallow streaming errors and fallback to non-streaming path below
                    receivedAnyDelta = false
                }

                if receivedAnyDelta {
                    // Update the active conversation's preview and save the model used
                    if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
                        let c = conversations[idx]
                        conversations[idx] = Conversation(
                            id: c.id,
                            title: c.title,
                            lastMessage: accumulated,
                            timestamp: Date(),
                            isActive: c.isActive,
                            lastUsedModelID: model.id
                        )
                        saveConversations()
                    }
                    // Persist after finishing the assistant message
                    saveMessages(for: conversation)
                } else {
                    // No streaming chunks arrived. Remove placeholder and fallback to non-streaming request.
                    if let lastIndex = messages.indices.last, messages[lastIndex].role == .assistant {
                        messages.remove(at: lastIndex)
                    }
                    let reply = try await svc.sendMessage(text, history: wireHistory, model: model, parameters: modelParameters)
                    messages.append(Message(content: reply, role: .assistant))

                    if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
                        let c = conversations[idx]
                        conversations[idx] = Conversation(
                            id: c.id,
                            title: c.title,
                            lastMessage: reply,
                            timestamp: Date(),
                            isActive: c.isActive,
                            lastUsedModelID: model.id
                        )
                        saveConversations()
                    }
                    saveMessages(for: conversation)
                }
            } else {
                // Fallback to non-streaming
                let reply = try await svc.sendMessage(text, history: wireHistory, model: model, parameters: modelParameters)
                messages.append(Message(content: reply, role: .assistant))

                // Update the active conversation's preview and save the model used
                if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
                    let c = conversations[idx]
                    conversations[idx] = Conversation(
                        id: c.id,
                        title: c.title,
                        lastMessage: reply,
                        timestamp: Date(),
                        isActive: c.isActive,
                        lastUsedModelID: model.id
                    )
                    saveConversations()
                }
                // Persist after appending the assistant message
                saveMessages(for: conversation)
            }
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

    /// Regenerates the last assistant response by removing it and re-sending the conversation.
    func regenerateLastResponse() async {
        guard let model = selectedModel else { return }
        guard let conversation = currentConversation else { return }
        guard !messages.isEmpty else { return }
        
        // Find the last assistant message
        guard let lastMessage = messages.last, lastMessage.role == .assistant else { return }
        
        // Find the corresponding user message (the one before the assistant message)
        guard messages.count >= 2 else { return }
        let userMessageIndex = messages.count - 2
        guard messages[userMessageIndex].role == .user else { return }
        
        let userMessage = messages[userMessageIndex]
        
        // Remove the last assistant message
        messages.removeLast()
        
        // Build wire history up to the user message (excluding it since send() will add it)
        let priorMessages = Array(messages.prefix(userMessageIndex))
        var wireHistory = priorMessages
        
        // Add system prompt if this is the first exchange
        if priorMessages.isEmpty {
            let systemPrompt = promptStore.resolvePrompt(for: conversation.id)
            wireHistory.insert(Message(content: systemPrompt, role: .system), at: 0)
        }
        
        isSending = true
        // Yield to allow observers (tests/UI) to observe the sending state
        await Task.yield()
        defer { isSending = false }
        
        do {
            let svc = service ?? serviceFactory.makeService(configuration: configuration)
            let reply = try await svc.sendMessage(userMessage.content, history: wireHistory, model: model, parameters: modelParameters)
            messages.append(Message(content: reply, role: .assistant))

            // Update the active conversation's preview
            if let idx = conversations.firstIndex(where: { $0.id == conversation.id }) {
                let c = conversations[idx]
                conversations[idx] = Conversation(
                    id: c.id,
                    title: c.title,
                    lastMessage: reply,
                    timestamp: Date(),
                    isActive: c.isActive,
                    lastUsedModelID: model.id
                )
                saveConversations()
            }

            // Persist the updated messages
            saveMessages(for: conversation)
        } catch let appErr as AppError {
            self.error = appErr
        } catch {
            self.error = AppError.unknown(error)
        }
    }

    /// Returns true if the last message can be regenerated (i.e., it's from the assistant and there's a user message before it).
    var canRegenerateLastMessage: Bool {
        guard messages.count >= 2 else { return false }
        guard let lastMessage = messages.last, lastMessage.role == .assistant else { return false }
        guard messages[messages.count - 2].role == .user else { return false }
        return true
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
                         isActive: false,
                         lastUsedModelID: $0.lastUsedModelID)
        }
        let defaultModelID = UserDefaults.standard.string(forKey: Constants.defaultModelKey)
        let newConversation = Conversation(
            title: "New Chat",
            lastMessage: nil,
            timestamp: Date(),
            isActive: true,
            lastUsedModelID: defaultModelID
        )
        // Put newest at the top
        conversations.insert(newConversation, at: 0)
        currentConversation = newConversation
        saveConversations()
        
        // Restore the model for the new conversation
        if let modelID = defaultModelID {
            Task {
                await restoreModelForConversation(modelID: modelID)
            }
        }
        
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
                         isActive: $0.id == conversation.id,
                         lastUsedModelID: $0.lastUsedModelID)
        }
        currentConversation = conversation
        loadMessages(for: conversation)
        
        // Restore the model that was last used with this conversation
        if let modelID = conversation.lastUsedModelID {
            Task {
                await restoreModelForConversation(modelID: modelID)
            }
        }
        
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
        // Prune any overrides for conversations that no longer exist
        let ids = Set(conversations.map { $0.id })
        promptStore.removeStaleOverrides(validIDs: ids)
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

    // MARK: - System Prompt Management

    /// Returns the current global system prompt (with default fallback).
    func currentGlobalSystemPrompt() -> String {
        promptStore.defaultPrompt
    }

    /// Updates the global system prompt (empty/whitespace reverts to default).
    func updateGlobalSystemPrompt(_ prompt: String) {
        promptStore.defaultPrompt = prompt
    }

    /// Returns the per-conversation override, if any (nil means use global).
    /// - Parameter id: Conversation ID.
    func conversationPromptOverride(for id: UUID) -> String? {
        promptStore.override(for: id)
    }

    /// Sets or clears a per-conversation prompt override.
    /// - Parameters:
    ///   - id: Conversation ID.
    ///   - prompt: New prompt; empty/whitespace clears the override.
    func updateConversationPrompt(_ id: UUID, to prompt: String) {
        promptStore.setOverride(prompt, for: id)
    }

    /// Resets/removes a per-conversation prompt override.
    /// - Parameter id: Conversation ID.
    func resetConversationPrompt(_ id: UUID) {
        promptStore.resetOverride(for: id)
    }

    // MARK: - Model Parameters Management

    /// Returns the current model parameters.
    func currentModelParameters() -> ModelParameters {
        modelParameters
    }

    /// Updates the model parameters and saves them.
    /// - Parameter parameters: New parameters to apply.
    func updateModelParameters(_ parameters: ModelParameters) {
        modelParameters = parameters
        saveModelParameters()
    }

    /// Resets model parameters to empty (uses provider defaults).
    func resetModelParameters() {
        modelParameters = .empty
        saveModelParameters()
    }

    /// Loads model parameters from UserDefaults.
    private func loadModelParameters() {
        if let data = UserDefaults.standard.data(forKey: Constants.modelParametersKey),
           let decoded = try? JSONDecoder().decode(ModelParameters.self, from: data) {
            modelParameters = decoded
        } else {
            modelParameters = .empty
        }
    }

    /// Saves model parameters to UserDefaults.
    private func saveModelParameters() {
        if let encoded = try? JSONEncoder().encode(modelParameters) {
            UserDefaults.standard.set(encoded, forKey: Constants.modelParametersKey)
        }
    }

    // MARK: - Default Model Management

    /// Sets a model as the default and saves it to UserDefaults.
    /// - Parameter model: The model to set as default.
    func setDefaultModel(_ model: LLMModel) {
        selectedModel = model
        saveDefaultModel(model)
    }

    /// Returns the currently saved default model ID, if any.
    func savedDefaultModelID() -> String? {
        UserDefaults.standard.string(forKey: Constants.defaultModelKey)
    }

    /// Saves the default model to UserDefaults.
    private func saveDefaultModel(_ model: LLMModel) {
        UserDefaults.standard.set(model.id, forKey: Constants.defaultModelKey)
    }

    /// Loads the saved default model from the available models list.
    /// - Parameter models: Available models to search in.
    /// - Returns: The matching model if found and valid.
    private func loadDefaultModel(from models: [LLMModel]) -> LLMModel? {
        guard let savedID = UserDefaults.standard.string(forKey: Constants.defaultModelKey) else {
            return nil
        }
        return models.first { $0.id == savedID }
    }

    /// Restores the model for a conversation, falling back to default if model not found.
    /// - Parameter modelID: The model ID to restore.
    private func restoreModelForConversation(modelID: String) async {
        let svc = service ?? serviceFactory.makeService(configuration: configuration)
        guard let models = try? await svc.availableModels() else { return }
        
        // Try to find the exact model
        if let model = models.first(where: { $0.id == modelID }) {
            selectedModel = model
            return
        }
        
        // Fallback to saved default model
        if let defaultModel = loadDefaultModel(from: models) {
            selectedModel = defaultModel
            return
        }
        
        // Ultimate fallback to first available model
        selectedModel = models.first
    }

    // MARK: - Conversation Management

    /// Deletes a conversation and its associated messages.
    /// - Parameter conversation: The conversation to delete.
    /// - Returns: True if deletion was successful, false otherwise.
    @discardableResult
    func deleteConversation(_ conversation: Conversation) -> Bool {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return false
        }

        // Delete the conversation's messages from storage
        let messageKey = messagesKeyPrefix + conversation.id.uuidString
        UserDefaults.standard.removeObject(forKey: messageKey)

        // Remove from conversations array
        conversations.remove(at: index)

        // If we deleted the currently active conversation, handle appropriately
        if currentConversation?.id == conversation.id {
            if conversations.isEmpty {
                // Create a new conversation if this was the last one
                let defaultModelID = UserDefaults.standard.string(forKey: Constants.defaultModelKey)
                let newConversation = Conversation(
                    title: "New Chat",
                    lastMessage: nil,
                    timestamp: Date(),
                    isActive: true,
                    lastUsedModelID: defaultModelID
                )
                conversations = [newConversation]
                currentConversation = newConversation
                messages = []
                
                // Restore the model for the new conversation
                if let modelID = defaultModelID {
                    Task {
                        await restoreModelForConversation(modelID: modelID)
                    }
                }
            } else {
                // Select the first available conversation
                let firstConversation = conversations[0]
                selectConversation(firstConversation)
            }
        }

        // Save updated conversations
        saveConversations()
        return true
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