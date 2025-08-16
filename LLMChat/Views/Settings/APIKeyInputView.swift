// LLMChat/Views/Settings/APIKeyInputView.swift
import SwiftUI

struct APIKeyInputView: View {
    @State private var apiKey: String = ""
    let onSave: (String) -> Void
    let onCancel: (() -> Void)?

    init(onSave: @escaping (String) -> Void, onCancel: (() -> Void)? = nil) {
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            SecureField("Enter API Key", text: $apiKey)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            HStack {
                if let onCancel {
                    Button("Cancel") { onCancel() }
                }
                Spacer()
                Button("Save") { onSave(apiKey) }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}