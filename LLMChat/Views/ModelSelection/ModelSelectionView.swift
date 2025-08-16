// LLMChat/Views/ModelSelection/ModelSelectionView.swift
import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @StateObject private var vm: ModelSelectionViewModel
    @State private var showError = false

    @MainActor init(vm: ModelSelectionViewModel? = nil) {
        if let vm = vm {
            _vm = StateObject(wrappedValue: vm)
        } else {
            _vm = StateObject(wrappedValue: ModelSelectionViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(String(localized: "model.select.title"))
                .task {
                    await vm.load()
                }
                .onChange(of: vm.error) { _, newValue in
                    showError = newValue != nil
                }
                .alert("Error", isPresented: $showError) {
                    Button(String(localized: "alert.ok"), role: .cancel) {
                        vm.error = nil
                    }
                } message: {
                    if let error = vm.error {
                        Text(error.localizedDescription)
                    }
                }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if vm.isLoading {
            loadingView
        } else {
            modelList
        }
    }

    private var loadingView: some View {
        ProgressView(String(localized: "models.loading"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modelList: some View {
        List(vm.models) { model in
            modelRow(for: model)
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func modelRow(for model: LLMModel) -> some View {
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
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            chatVM.selectedModel = model
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