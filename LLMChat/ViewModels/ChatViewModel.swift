// LLMChat/ViewModels/ChatViewModel.swift
import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var isSending = false
    @Published var error: AppError?
    @Published var selectedModel: LLMModel?

    private let serviceFactory: LLMServiceFactoryType
    private let keychain: KeychainServiceType
    private var configuration = APIConfiguration()
    private var service: LLMServiceProtocol?

    init(serviceFactory: LLMServiceFactoryType, keychain: KeychainServiceType) {
        self.serviceFactory = serviceFactory
        self.keychain = keychain
    }

    /// Bootstraps the view model by loading persisted API configuration and seeding a default model.
    func bootstrap() {
        let key = (try? keychain.getAPIKey(account: "openai"))
        configuration = APIConfiguration(baseURL: Constants.openAIBaseURL, apiKey: key ?? "", provider: "openai")
        service = serviceFactory.makeService(configuration: configuration)

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
        isSending = true
        defer { isSending = false }
        messages.append(Message(content: text, role: .user))
        do {
            let svc = service ?? serviceFactory.makeService(configuration: configuration)
            let reply = try await svc.sendMessage(text, history: messages, model: model)
            messages.append(Message(content: reply, role: .assistant))
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