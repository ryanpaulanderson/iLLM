//  ConversationPromptEditorView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Editor for per-conversation system prompt overrides.
//

import SwiftUI

struct ConversationPromptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatVM: ChatViewModel

    let conversationID: UUID
    @State private var text: String = ""
    @State private var didLoad = false

    private let maxLength = 4000

    var body: some View {
        Form {
            Section {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2))
                        )
                        .accessibilityLabel(String(localized: "accessibility.conversationPromptEditor", table: "Strings"))

                    if text.isEmpty {
                        Text(String(localized: "conversationPrompt.editor.placeholder", table: "Strings"))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(format: String(localized: "systemPrompt.editor.charCount_format", table: "Strings"), Int64(text.count), Int64(maxLength)))
                            .font(.caption)
                            .foregroundStyle(text.count > maxLength ? .red : .secondary)
                        Spacer()
                        Text(String(localized: "systemPrompt.editor.appliesToNew", table: "Strings"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(String(localized: "conversationPrompt.editor.usesGlobal", table: "Strings"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                HStack {
                    Button(String(localized: "conversationPrompt.editor.cancel", table: "Strings")) {
                        dismiss()
                    }
                    Spacer()
                    Button(String(localized: "conversationPrompt.editor.reset", table: "Strings")) {
                        // Clear override and reflect UI as empty (uses global)
                        chatVM.resetConversationPrompt(conversationID)
                        text = ""
                    }
                    Button(String(localized: "conversationPrompt.editor.save", table: "Strings")) {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            // Empty clears override to use global
                            chatVM.resetConversationPrompt(conversationID)
                        } else {
                            let clamped = String(trimmed.prefix(maxLength))
                            chatVM.updateConversationPrompt(conversationID, to: clamped)
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(String(localized: "conversationPrompt.editor.title", table: "Strings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !didLoad {
                text = chatVM.conversationPromptOverride(for: conversationID) ?? ""
                didLoad = true
            }
        }
    }
}

#if DEBUG
struct ConversationPromptEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConversationPromptEditorView(conversationID: UUID())
                .environmentObject(ChatViewModel.preview())
        }
    }
}
#endif