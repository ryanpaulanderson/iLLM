//  SystemPromptEditorView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Editor for the global system prompt.
//

import SwiftUI

struct SystemPromptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatVM: ChatViewModel

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
                        .accessibilityLabel(String(localized: "accessibility.systemPromptEditor", table: "Strings"))

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(String(localized: "systemPrompt.editor.placeholder", table: "Strings"))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                HStack {
                    Text(String(format: String(localized: "systemPrompt.editor.charCount_format", table: "Strings"), Int64(text.count), Int64(maxLength)))
                        .font(.caption)
                        .foregroundStyle(text.count > maxLength ? .red : .secondary)
                    Spacer()
                    Text(String(localized: "systemPrompt.editor.appliesToNew", table: "Strings"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Button(String(localized: "systemPrompt.editor.cancel", table: "Strings")) {
                        dismiss()
                    }
                    Spacer()
                    Button(String(localized: "systemPrompt.editor.reset", table: "Strings")) {
                        text = Constants.defaultSystemPrompt
                    }
                    Button(String(localized: "systemPrompt.editor.save", table: "Strings")) {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let clamped = String(trimmed.prefix(maxLength))
                        chatVM.updateGlobalSystemPrompt(clamped)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(String(localized: "systemPrompt.editor.title", table: "Strings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !didLoad {
                text = chatVM.currentGlobalSystemPrompt()
                didLoad = true
            }
        }
    }
}

#if DEBUG
struct SystemPromptEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SystemPromptEditorView()
                .environmentObject(ChatViewModel.preview())
        }
    }
}
#endif