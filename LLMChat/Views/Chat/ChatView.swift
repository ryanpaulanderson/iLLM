// LLMChat/Views/Chat/ChatView.swift
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var vm: ChatViewModel
    @State private var input: String = ""
    @State private var isScrollScheduled: Bool = false
    @State private var shouldAutoScroll: Bool = true

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                List {
                    ForEach(Array(vm.messages.enumerated()), id: \.element.id) { index, message in
                        let isLastMessage = index == vm.messages.count - 1
                        let canRegenerate = vm.canRegenerateLastMessage && isLastMessage && message.role == .assistant
                        
                        MessageBubbleView(
                            message: message,
                            isLastMessage: isLastMessage,
                            canRegenerate: canRegenerate,
                            onRegenerate: {
                                Task {
                                    await vm.regenerateLastResponse()
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    if vm.isSending {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
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
                        .onAppear { shouldAutoScroll = true }
                        .onDisappear { shouldAutoScroll = false }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .onChange(of: vm.messages.count, initial: false) { _, _ in
                    if shouldAutoScroll { scrollToBottom(proxy) }
                }
                .onChange(of: vm.isSending, initial: false) { _, _ in
                    if shouldAutoScroll { scrollToBottom(proxy) }
                }
                // Auto-scroll while streaming as the last assistant message grows
                .onChange(of: vm.messages.last?.content, initial: false) { _, _ in
                    guard vm.isSending, shouldAutoScroll else { return }
                    // Debounce and disable animation during streaming to prevent jitter
                    if isScrollScheduled { return }
                    isScrollScheduled = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        scrollToBottom(proxy, animated: false)
                        isScrollScheduled = false
                    }
                }
                .onAppear {
                    scrollToBottom(proxy)
                }
                // Detect user interaction to temporarily disable auto-scroll
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in shouldAutoScroll = false }
                )

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

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        // Defer to next runloop so List lays out before scrolling
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }
            } else {
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