// LLMChat/Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
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
            .onAppear {
                apiKey = chatVM.currentAPIKey()
            }
        }
    }
}