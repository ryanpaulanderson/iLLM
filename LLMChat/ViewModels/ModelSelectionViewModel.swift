// LLMChat/ViewModels/ModelSelectionViewModel.swift
import Foundation

@MainActor
final class ModelSelectionViewModel: ObservableObject {
    @Published private(set) var models: [LLMModel] = []
    @Published private(set) var isLoading = false
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

    /// Loads available models for the configured provider.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let apiKey = (try? keychain.getAPIKey(account: provider)) ?? ""
            let config = APIConfiguration(apiKey: apiKey, provider: provider)
            let service = factory.makeService(configuration: config)
            models = try await service.availableModels()
        } catch let appErr as AppError {
            self.error = appErr
        } catch {
            self.error = AppError.unknown(error)
        }
}
    // LLMChat/ViewModels/ModelSelectionViewModel.swift (preview helpers)
    #if DEBUG
    extension ModelSelectionViewModel {
        static func preview(models: [LLMModel] = [],
                            isLoading: Bool = false,
                            error: AppError? = nil) -> ModelSelectionViewModel {
            let vm = ModelSelectionViewModel()
            vm._setPreviewState(models: models, isLoading: isLoading, error: error)
            return vm
        }
    
        // Internal-only mutator to support previews.
        fileprivate func _setPreviewState(models: [LLMModel], isLoading: Bool, error: AppError?) {
            self.models = models
            self.isLoading = isLoading
            self.error = error
        }
    }
    #endif