// LLMChat/ViewModels/ChatViewModel.swift
import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isSending = false
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

    func bootstrap() {
        if let key = try? keychain.getAPIKey(account: "openai"), let base = URL(string: Constants.openAIBaseURL) {
            configuration = APIConfiguration(baseURL: base, apiKey: key ?? "", provider: "openai")
            service = serviceFactory.makeService(configuration: configuration)
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

    func send(text: String) async {
        guard let model = selectedModel else { return }
        isSending = true
        messages.append(Message(content: text, role: .user))
        do {
            let svc = service ?? serviceFactory.makeService(configuration: configuration)
            let reply = try await svc.sendMessage(text, history: messages, model: model)
            messages.append(Message(content: reply, role: .assistant))
        } catch let appErr as AppError {
            error = appErr
        } catch {
            error = .unknown(error)
        }
        isSending = false
    }

    func updateAPIKey(_ key: String) {
        do {
            try keychain.setAPIKey(key, account: "openai")
            configuration.apiKey = key
            service = serviceFactory.makeService(configuration: configuration)
        } catch let appErr as AppError {
            error = appErr
        } catch {
            error = .unknown(error)
        }
    }
}