// LLMChat/Views/Chat/MessageBubbleView.swift
import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            Text(message.content)
                .padding(12)
                .background(message.isFromUser ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.72,
                       alignment: message.isFromUser ? .trailing : .leading)
            if !message.isFromUser { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}