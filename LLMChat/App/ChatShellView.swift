//
//  ChatShellView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Main shell view with NavigationSplitView for multi-chat support
//

import SwiftUI

struct ChatShellView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showSettings = false
    @State private var showModelSelection = false
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                ConversationListView()
                    .environmentObject(chatVM)
                    .frame(minWidth: 250, idealWidth: 300)
            },
            content: {
                ChatView()
                    .environmentObject(chatVM)  // Ensure ChatView uses the same ChatViewModel instance
                    .navigationTitle(chatVM.selectedModel?.name ?? String(localized: "chat.title"))
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(false)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            // Settings button - toggles inspector on iPad, sheet on iPhone
                            Button {
                                if horizontalSizeClass == .regular {
                                    withAnimation {
                                        if columnVisibility == .all {
                                            columnVisibility = .doubleColumn
                                        } else {
                                            columnVisibility = .all
                                        }
                                    }
                                } else {
                                    showSettings = true
                                }
                            } label: {
                                Image(systemName: "gear")
                                    .accessibilityLabel(String(localized: "accessibility.openSettings"))
                            }
                        }
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsSheetView()
                            .environmentObject(chatVM)
                    }
            },
            detail: {
                // Inspector column for settings (iPad only)
                SettingsInspectorView(columnVisibility: $columnVisibility)
                    .environmentObject(chatVM)
                    .frame(minWidth: 300, idealWidth: 350)
            }
        )
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            chatVM.bootstrap()
            // On compact devices, show only content
            if horizontalSizeClass == .compact {
                columnVisibility = .detailOnly
            }
        }
    }
}

// MARK: - Settings Sheet View (for iPhone)
private struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatVM: ChatViewModel
    @StateObject private var modelVM = ModelSelectionViewModel()
    @State private var apiKey: String = ""
    @State private var isLoadingModels = false
    
    var body: some View {
        NavigationStack {
            Form {
                // API Key Section
                Section(String(localized: "settings.section.apikey")) {
                    SecureField(String(localized: "settings.apiKey.placeholder"), text: $apiKey)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    HStack {
                        Button(String(localized: "settings.save")) {
                            chatVM.updateAPIKey(apiKey)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Spacer()
                        
                        if !apiKey.isEmpty {
                            Button(role: .destructive) {
                                apiKey = ""
                                chatVM.updateAPIKey("")
                            } label: {
                                Text(String(localized: "settings.clearApiKey"))
                            }
                        }
                    }
                }
                
                // Model Selection Section
                Section(String(localized: "models.section.title")) {
                    if isLoadingModels {
                        HStack {
                            ProgressView()
                            Text(String(localized: "models.loading"))
                                .foregroundStyle(.secondary)
                        }
                    } else if modelVM.models.isEmpty {
                        Button {
                            Task {
                                isLoadingModels = true
                                await modelVM.load()
                                isLoadingModels = false
                            }
                        } label: {
                            Label(String(localized: "models.load"), systemImage: "arrow.clockwise")
                        }
                    } else {
                        ForEach(modelVM.models) { model in
                            Button {
                                chatVM.selectedModel = model
                                dismiss()  // Close settings when model is selected
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name)
                                            .foregroundStyle(.primary)
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
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    .accessibilityLabel(String(localized: "accessibility.close"))
                }
            }
            .onAppear {
                apiKey = chatVM.currentAPIKey()
                modelVM.setConfiguration(chatVM.currentConfiguration())
                if !apiKey.isEmpty {
                    Task {
                        isLoadingModels = true
                        await modelVM.load()
                        isLoadingModels = false
                    }
                }
            }
        }
    }
}

// MARK: - Settings Inspector View (for iPad)
private struct SettingsInspectorView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @StateObject private var modelVM = ModelSelectionViewModel()
    @State private var apiKey: String = ""
    @State private var isLoadingModels = false
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var body: some View {
        Form {
            // API Key Section
            Section(String(localized: "settings.section.apikey")) {
                SecureField(String(localized: "settings.apiKey.placeholder"), text: $apiKey)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                
                HStack {
                    Button(String(localized: "settings.save")) {
                        chatVM.updateAPIKey(apiKey)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Spacer()
                    
                    if !apiKey.isEmpty {
                        Button(role: .destructive) {
                            apiKey = ""
                            chatVM.updateAPIKey("")
                        } label: {
                            Text(String(localized: "settings.clearApiKey"))
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            // Model Selection Section
            Section(String(localized: "models.section.title")) {
                if isLoadingModels {
                    HStack {
                        ProgressView()
                        Text(String(localized: "models.loading"))
                            .foregroundStyle(.secondary)
                    }
                } else if modelVM.models.isEmpty {
                    Button {
                        Task {
                            isLoadingModels = true
                            await modelVM.load()
                            isLoadingModels = false
                        }
                    } label: {
                        Label(String(localized: "models.load"), systemImage: "arrow.clockwise")
                    }
                } else {
                    ForEach(modelVM.models) { model in
                        Button {
                            chatVM.selectedModel = model
                            // Close inspector on iPad when model is selected
                            withAnimation {
                                columnVisibility = .doubleColumn
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.name)
                                        .foregroundStyle(.primary)
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
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "settings.title"))
        .onAppear {
            apiKey = chatVM.currentAPIKey()
            modelVM.setConfiguration(chatVM.currentConfiguration())
            if !apiKey.isEmpty {
                Task {
                    isLoadingModels = true
                    await modelVM.load()
                    isLoadingModels = false
                }
            }
        }
    }
}

// MARK: - Previews
#if DEBUG
struct ChatShellView_Previews: PreviewProvider {
    static var previews: some View {
        ChatShellView()
            .environmentObject(
                ChatViewModel.preview(
                    messages: [
                        Message(content: "Hello", role: .user),
                        Message(content: "Hi there!", role: .assistant)
                    ]
                )
            )
            .previewDisplayName("iPad")
            .previewDevice("iPad Pro (11-inch)")
        
        ChatShellView()
            .environmentObject(ChatViewModel.preview())
            .previewDisplayName("iPhone")
            .previewDevice("iPhone 15")
    }
}
#endif