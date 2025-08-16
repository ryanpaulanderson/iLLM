// LLMChat/Views/Chat/MessageInputView.swift
import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextField(String(localized: "message.input.placeholder"), text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(String(localized: "accessibility.messageInput"))
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .accessibilityLabel(String(localized: "accessibility.sendMessage"))
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

#if DEBUG
struct MessageInputView_Previews: PreviewProvider {
    @State static var text1 = ""
    @State static var text2 = "Draft message"

    static var previews: some View {
        Group {
            MessageInputView(text: $text1, onSend: {})
                .previewDisplayName("Empty")

            MessageInputView(text: $text2, onSend: {})
                .previewDisplayName("With Text")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif