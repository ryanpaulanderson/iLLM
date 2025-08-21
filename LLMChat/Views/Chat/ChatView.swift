// LLMChat/Views/Chat/ChatView.swift
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var vm: ChatViewModel
    @State private var input: String = ""

    var body: some View {
        ScrollViewReader { proxy in
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
                            Text(String(localized: "chat.thinking", table: "Strings"))
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .listRowSeparator(.hidden)
                    }
                    // Bottom anchor to ensure we can always scroll to latest content (including typing row)
                    Color.clear
                        .frame(height: 1)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .id("BOTTOM")
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .onChange(of: vm.messages.count, initial: false) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: vm.isSending, initial: false) { _, _ in
                    scrollToBottom(proxy)
                }
                .onAppear {
                    scrollToBottom(proxy)
                }

                Divider()

                MessageInputView(text: $input, onSend: {
                    let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Task { await vm.send(text: text) }
                    input = ""
                })
                .padding(.horizontal)
                .padding(.bottom)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
        }
        .alert(item: $vm.error) { err in
            Alert(title: Text(String(localized: "alert.error.title", table: "Strings")),
                  message: Text(err.localizedDescription),
                  dismissButton: .default(Text(String(localized: "alert.ok", table: "Strings"))))
        }
    }

    // MARK: - Scrolling

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        // Defer to next runloop so List lays out before scrolling
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
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