// LLMChat/Views/ModelSelection/ModelSelectionView.swift
import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @StateObject private var vm: ModelSelectionViewModel

    @MainActor init(vm: ModelSelectionViewModel? = nil) {
        if let vm = vm {
            _vm = StateObject(wrappedValue: vm)
        } else {
            _vm = StateObject(wrappedValue: ModelSelectionViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            content
        }
    }

    // Extracted to reduce type-checking complexity.
    @ViewBuilder
    private var content: some View {
        Group {
            if vm.isLoading {
                ProgressView(String(localized: "models.loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(vm.models) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                            Text(model.id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if model.id == chatVM.selectedModel?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        chatVM.selectedModel = model
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "model.select.title"))
        .task {
            await vm.load()
        }
        .alert(item: $vm.error) { _ in
            Button(String(localized: "alert.ok"), role: .cancel) { }
        } message: { err in
            Text(err.localizedDescription)
        }
    }
    
    #if DEBUG
    struct ModelSelectionView_Previews: PreviewProvider {
        static var previews: some View {
            ModelSelectionView(
                vm: .preview(models: [
                    LLMModel(id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai"),
                    LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
                ])
            )
            .environmentObject(
                ChatViewModel.preview(
                    selectedModel: LLMModel(id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai")
                )
            )
        }
    }
    #endif
}