// LLMChat/Views/ModelSelection/ModelSelectionView.swift
import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @StateObject private var vm = ModelSelectionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading models...")
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
            .navigationTitle("Select Model")
            .task {
                await vm.load()
            }
            .alert(item: $vm.error) { err in
                Alert(title: Text("Error"),
                      message: Text(err.localizedDescription),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}