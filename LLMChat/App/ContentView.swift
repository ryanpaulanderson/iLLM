//
//  ContentView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Root content view that determines navigation style based on device
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var chatVM: ChatViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showConversationPromptEditor = false
    @State private var showAPIKeyEditor = false
    @State private var showModelSelection = false
    @State private var showSystemPromptEditor = false
    @State private var showConversationsList = false
    @State private var showModelParametersEditor = false

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone: Use NavigationStack with simple navigation
                iPhoneLayout
            } else {
                // iPad: Use NavigationSplitView
                iPadLayout
            }
        }
        .onAppear {
            chatVM.bootstrap()
        }
    }
    
    @ViewBuilder
    private var iPhoneLayout: some View {
        NavigationStack {
            ChatView()
                .navigationTitle(chatVM.selectedModel?.name ?? String(localized: "chat.title", table: "Strings"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showConversationsList = true
                            }
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
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
                            }
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
        .background(Color(.systemBackground))
        .ignoresSafeArea()
        .overlay {
            if showConversationsList {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showConversationsList = false
                            }
                        }
                    
                    // Conversations list sliding from left
                    HStack(spacing: 0) {
                        NavigationStack {
                            ConversationListView(onSelect: { conversation in
                                chatVM.selectConversation(conversation)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showConversationsList = false
                                }
                            })
                            .environmentObject(chatVM)
                            .navigationTitle(String(localized: "conversations.title", table: "Strings"))
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showConversationsList = false
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.gray)
                                    }
                                    .accessibilityLabel(String(localized: "accessibility.close", table: "Strings"))
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.85)
                        .background(Color(.systemBackground))
                        
                        Spacer()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .leading)
                ))
            }
        }
    }
    
    @ViewBuilder
    private var iPadLayout: some View {
        ChatShellView()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif