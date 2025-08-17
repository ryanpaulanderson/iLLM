// LLMChat/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatShellView()
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