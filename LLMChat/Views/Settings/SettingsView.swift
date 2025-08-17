// LLMChat/Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "settings.section.openai")) {
                    SecureField(String(localized: "settings.apiKey.placeholder"), text: $apiKey)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Button(String(localized: "settings.save")) {
                        chatVM.updateAPIKey(apiKey)
                        dismiss() // Auto-dismiss after saving
                    }
                }
                Section {
                    Button(role: .destructive) {
                        chatVM.updateAPIKey("")
                    } label: {
                        Text(String(localized: "settings.clearApiKey"))
                    }
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Dismiss the settings screen")
                }
            }
            .onAppear {
                apiKey = chatVM.currentAPIKey()
            }
        }
    }
}