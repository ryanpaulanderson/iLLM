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
    @State private var showAPIKeyEditor = false
    @State private var showModelSelection = false
    @State private var selectedConversation: Conversation?
    @State private var didSetInitialVisibility = false
    @State private var hasInitializedSelection = false
    @State private var showConversationPromptEditor = false
    @State private var showSystemPromptEditor = false
    @State private var showModelParametersEditor = false
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                ConversationListView(onSelect: { conv in
                    // Select the conversation in the view model
                    chatVM.selectConversation(conv)
                    selectedConversation = conv
                    
                    // Navigate to chat view
                    withAnimation {
                        if horizontalSizeClass == .compact {
                            columnVisibility = .detailOnly
                        } else {
                            columnVisibility = .doubleColumn
                        }
                    }
                })
                    .environmentObject(chatVM)
                    .frame(minWidth: 250, idealWidth: 300)
            },
            content: {
                if shouldShowChat {
                    chatDetail
                } else {
                    // Sidebar-only state on compact; do not render a detail view.
                    EmptyView()
                }
            },
            detail: {
                // No separate inspector; settings live under the gear menu
                EmptyView()
            }
        )
        .background(Color(.systemBackground))
        .ignoresSafeArea()
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            chatVM.bootstrap()
            
            // Select first conversation and navigate to chat view initially
            if !hasInitializedSelection {
                if let firstConversation = chatVM.conversations.first {
                    selectedConversation = firstConversation
                    chatVM.selectConversation(firstConversation)
                }
                hasInitializedSelection = true
            }
            
            // Only set initial column visibility once; don't override user's manual navigation
            if !didSetInitialVisibility {
                if horizontalSizeClass == .compact {
                    // Start with chat view on iPhone
                    columnVisibility = .detailOnly
                } else {
                    // Show both sidebar and chat on iPad
                    columnVisibility = .doubleColumn
                }
                didSetInitialVisibility = true
            }
        }
        .onChange(of: horizontalSizeClass) { _, newValue in
            // Respect size class changes (e.g., rotation) without fighting user taps
            withAnimation {
                columnVisibility = (newValue == .compact) ? .detailOnly : .doubleColumn
            }
        }
        .onChange(of: columnVisibility) { _, newValue in
            // When user taps Back on compact, NavigationSplitView sets visibility to .all (sidebar).
            // Clear selection so content doesn't immediately re-push to detail.
            if horizontalSizeClass == .compact && newValue == .all {
                selectedConversation = nil
            }
        }
    }
}

extension ChatShellView {
    // MARK: - Helpers
    
    private var shouldShowChat: Bool {
        // Always show chat when a conversation is selected
        return selectedConversation != nil || chatVM.conversations.first { $0.isActive } != nil
    }
    
    @ViewBuilder
    private var chatDetail: some View {
        ChatView()
            .environmentObject(chatVM)  // Ensure ChatView uses the same ChatViewModel instance
            .navigationTitle(chatVM.selectedModel?.name ?? String(localized: "chat.title", table: "Strings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Unified settings menu with all items
                    Menu {
                        Button {
                            showConversationPromptEditor = true
                        } label: {
                            Label(String(localized: "conversationPrompt.editor.title", table: "Strings"), systemImage: "text.badge.star")
                        }
                        .disabled(chatVM.currentConversation == nil)
                        Button {
                            showAPIKeyEditor = true
                        } label: {
                            Label(String(localized: "settings.apiKey.placeholder", table: "Strings"), systemImage: "key.fill")
                        }
                        Button {
                            showModelSelection = true
                        } label: {
                            Label(String(localized: "models.select", table: "Strings"), systemImage: "slider.horizontal.3")
                        }
                        Button {
                            showSystemPromptEditor = true
                        } label: {
                            Label(String(localized: "systemPrompt.editor.title", table: "Strings"), systemImage: "text.alignleft")
                        }
                        Button {
                            showModelParametersEditor = true
                        } label: {
                            Label(String(localized: "modelParams.title", table: "Strings"), systemImage: "slider.horizontal.below.rectangle")
                        }
                    } label: {
                        Image(systemName: "gear")
                            .accessibilityLabel(String(localized: "accessibility.openSettings", table: "Strings"))
                    }
                }
            }
            .sheet(isPresented: $showConversationPromptEditor) {
                if let conv = chatVM.currentConversation {
                    ConversationPromptEditorView(conversationID: conv.id)
                        .environmentObject(chatVM)
                } else {
                    Text("No active conversation")
                }
            }
            .sheet(isPresented: $showAPIKeyEditor) {
                APIKeyInputView(onSave: { key in
                    chatVM.updateAPIKey(key)
                    showAPIKeyEditor = false
                }, onCancel: {
                    showAPIKeyEditor = false
                })
                .environmentObject(chatVM)
            }
            .sheet(isPresented: $showModelSelection) {
                ModelSelectionView()
                    .environmentObject(chatVM)
            }
            .sheet(isPresented: $showSystemPromptEditor) {
                NavigationStack {
                    SystemPromptEditorView()
                        .environmentObject(chatVM)
                }
            }
            .sheet(isPresented: $showModelParametersEditor) {
                NavigationStack {
                    ModelParametersEditorView()
                        .environmentObject(chatVM)
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