// LLMChat/Views/Chat/MessageBubbleView.swift
import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
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
                        ? String(format: String(localized: "accessibility.message.user_format"), message.content)
                        : String(format: String(localized: "accessibility.message.assistant_format"), message.content)
                    )
                )
            if !message.isFromUser { Spacer() }
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
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif