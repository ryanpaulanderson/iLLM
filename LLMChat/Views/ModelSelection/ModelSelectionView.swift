// LLMChat/Views/ModelSelection/ModelSelectionView.swift
import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @StateObject private var vm: ModelSelectionViewModel

    @MainActor init(vm: ModelSelectionViewModel = ModelSelectionViewModel()) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
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
            .alert(item: $vm.error) { err in
                Alert(title: Text("Error"),
                      message: Text(err.localizedDescription),
                      dismissButton: .default(Text("OK")))
    // keep existing view code
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