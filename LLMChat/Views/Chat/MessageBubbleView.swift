// LLMChat/Views/Chat/MessageBubbleView.swift
import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isLastMessage: Bool
    let canRegenerate: Bool
    let onRegenerate: (() -> Void)?

    init(message: Message, isLastMessage: Bool = false, canRegenerate: Bool = false, onRegenerate: (() -> Void)? = nil) {
        self.message = message
        self.isLastMessage = isLastMessage
        self.canRegenerate = canRegenerate
        self.onRegenerate = onRegenerate
    }

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.isFromUser { Spacer() }
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(message.isFromUser ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.72,
                           alignment: message.isFromUser ? .trailing : .leading)
                    .accessibilityLabel(
                        Text(
                            message.isFromUser
                            ? String(format: String(localized: "accessibility.message.user_format", table: "Strings"), message.content)
                            : String(format: String(localized: "accessibility.message.assistant_format", table: "Strings"), message.content)
                        )
                    )
                if !message.isFromUser { Spacer() }
            }
            
            // Show regenerate button for the last assistant message
            if !message.isFromUser && isLastMessage && canRegenerate {
                HStack {
                    Button {
                        onRegenerate?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text(String(localized: "message.regenerate", table: "Strings"))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "accessibility.regenerateMessage", table: "Strings"))
                    
                    Spacer()
                }
                .padding(.leading, 12)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageBubbleView(message: Message(content: "Hello from user", role: .user))
                .previewDisplayName("User")

            MessageBubbleView(message: Message(content: "Hello from assistant", role: .assistant))
                .previewDisplayName("Assistant")
            
            MessageBubbleView(
                message: Message(content: "This is the last assistant message that can be regenerated", role: .assistant),
                isLastMessage: true,
                canRegenerate: true,
                onRegenerate: { print("Regenerate tapped") }
            )
            .previewDisplayName("Assistant with Regenerate")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif