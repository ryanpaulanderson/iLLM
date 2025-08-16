// LLMChat/Views/Chat/ChatView.swift
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var vm: ChatViewModel
    @State private var input: String = ""

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(vm.messages) { message in
                    MessageBubbleView(message: message)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                if vm.isSending {
                    HStack {
                        ProgressView()
                        Text(String(localized: "chat.thinking"))
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)

            Divider()

            MessageInputView(text: $input, onSend: {
                let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                Task { await vm.send(text: text) }
                input = ""
            })
            .padding(.horizontal)
            .padding(.bottom)
        }
        .alert(item: $vm.error) { err in
            Alert(title: Text(String(localized: "alert.error.title")),
                  message: Text(err.localizedDescription),
                  dismissButton: .default(Text(String(localized: "alert.ok"))))
        }
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatView()
                .environmentObject(
                    ChatViewModel.preview(
                        messages: [
                            Message(content: "Hello", role: .user),
                            Message(content: "Hi! 👋", role: .assistant)
                        ]
                    )
                )
                .previewDisplayName("With Messages")

            ChatView()
                .environmentObject(
                    ChatViewModel.preview(
                        messages: [Message(content: "Typing…", role: .user)],
                        isSending: true
                    )
                )
                .previewDisplayName("Sending")
        }
    }
}
#endif