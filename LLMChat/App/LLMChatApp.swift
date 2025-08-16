// LLMChat/App/LLMChatApp.swift
import SwiftUI

@main
struct LLMChatApp: App {
    @StateObject private var chatVM = ChatViewModel(
        serviceFactory: LLMServiceFactory(),
        keychain: KeychainService()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatVM)
        }
    }
}
