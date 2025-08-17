//
//  ContentView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Root content view that determines navigation style based on device
//

import SwiftUI

struct ContentView: View {
    @StateObject private var chatVM = ChatViewModel(
        serviceFactory: LLMServiceFactory(), 
        keychain: KeychainService()
    )
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
        .environmentObject(chatVM)
        .onAppear {
            chatVM.bootstrap()
        }
    }
    
    @ViewBuilder
    private var iPhoneLayout: some View {
        NavigationStack {
            ChatView()
                .navigationTitle(chatVM.selectedModel?.name ?? String(localized: "chat.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            ConversationListView(onSelect: { conversation in
                                chatVM.selectConversation(conversation)
                            })
                            .navigationTitle("Conversations")
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                                .environmentObject(chatVM)
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
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