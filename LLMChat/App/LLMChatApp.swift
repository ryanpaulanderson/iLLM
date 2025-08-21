//
//  LLMChatApp.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Main app entry point for LLMChat iOS application
//

import SwiftUI

@main
struct LLMChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(
                    ChatViewModel(
                        serviceFactory: LLMServiceFactory(),
                        keychain: KeychainService(),
                        promptStore: SystemPromptStore()
                    )
                )
                .background(Color(.systemBackground))
                .ignoresSafeArea()
        }
    }
}
