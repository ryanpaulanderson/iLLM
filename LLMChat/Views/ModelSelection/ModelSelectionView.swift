// LLMChat/Views/ModelSelection/ModelSelectionView.swift
import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.dismiss) private var dismiss
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
                HStack {
                    Text(model.name)
                    
                    // Show "Default" badge for the saved default model
                    if model.id == chatVM.savedDefaultModelID() {
                        Text(String(localized: "models.default", table: "Strings"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
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
            dismiss() // Auto-dismiss after selecting a model
        }
        .contextMenu {
            Button {
                chatVM.setDefaultModel(model)
            } label: {
                Label(String(localized: "models.setDefault", table: "Strings"), systemImage: "star.fill")
            }
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