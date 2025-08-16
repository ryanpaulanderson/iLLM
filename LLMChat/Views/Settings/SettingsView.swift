// LLMChat/Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI") {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                    Button("Save") {
                        chatVM.updateAPIKey(apiKey)
                    }
                }
                Section {
                    Button(role: .destructive) {
                        chatVM.updateAPIKey("")
                    } label: {
                        Text("Clear API Key")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                apiKey = (try? KeychainService().getAPIKey(account: "openai")) ?? ""
            }
        }
    }
}