// LLMChat/ViewModels/ModelSelectionViewModel.swift
import Foundation

@MainActor
final class ModelSelectionViewModel: ObservableObject {
    @Published var models: [LLMModel] = []
    @Published var isLoading = false
    @Published var error: AppError?

    private let factory: LLMServiceFactoryType
    private let keychain: KeychainServiceType
    private let provider: String

    init(factory: LLMServiceFactoryType = LLMServiceFactory(),
         keychain: KeychainServiceType = KeychainService(),
         provider: String = "openai") {
        self.factory = factory
        self.keychain = keychain
        self.provider = provider
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let apiKey = (try? keychain.getAPIKey(account: provider)) ?? ""
            let config = APIConfiguration(apiKey: apiKey, provider: provider)
            let service = factory.makeService(configuration: config)
            models = try await service.availableModels()
        } catch let appErr as AppError {
            error = appErr
        } catch {
            error = .unknown(error)
        }
    }
}