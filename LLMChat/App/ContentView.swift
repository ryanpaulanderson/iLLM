// LLMChat/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var showSettings = false
    @State private var showModelSelection = false

    var body: some View {
        NavigationStack {
            ChatView()
                .navigationTitle(String(localized: "chat.title"))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showModelSelection = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .accessibilityLabel(String(localized: "accessibility.selectModel"))
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .accessibilityLabel(String(localized: "accessibility.openSettings"))
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(chatVM)
                }
                .sheet(isPresented: $showModelSelection) {
                    ModelSelectionView()
                        .environmentObject(chatVM)
                }
        }
        .onAppear {
            chatVM.bootstrap()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                ContentView()
                    .environmentObject(
                        ChatViewModel.preview(
                            messages: [
                                Message(content: "Hi there", role: .user),
                                Message(content: "Hello! How can I help?", role: .assistant)
                            ]
                        )
                    )
            }
            .previewDisplayName("Default")

            NavigationStack {
                ContentView()
                    .environmentObject(
                        ChatViewModel.preview(
                            messages: [Message(content: "Thinking…", role: .user)],
                            isSending: true
                        )
                    )
            }
            .previewDisplayName("Sending")
        }
    }
}