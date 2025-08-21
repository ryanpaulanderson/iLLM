//
//  ModelParametersEditorView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Editor for model parameters like temperature and top-p
//

import SwiftUI

struct ModelParametersEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatVM: ChatViewModel
    
    @State private var useCustomParameters = false
    @State private var temperature: Double = 0.7
    @State private var topP: Double = 0.9
    @State private var didLoad = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $useCustomParameters) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "modelParams.useCustom", table: "Strings"))
                        Text(String(localized: "modelParams.useCustom.description", table: "Strings"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if useCustomParameters {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "modelParams.temperature", table: "Strings"))
                            Spacer()
                            Text(String(format: "%.2f", temperature))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        
                        Slider(value: $temperature, in: 0.0...2.0, step: 0.01) {
                            Text(String(localized: "modelParams.temperature", table: "Strings"))
                        }
                        .accentColor(.accentColor)
                        
                        Text(String(localized: "modelParams.temperature.description", table: "Strings"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "modelParams.topP", table: "Strings"))
                            Spacer()
                            Text(String(format: "%.2f", topP))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        
                        Slider(value: $topP, in: 0.0...1.0, step: 0.01) {
                            Text(String(localized: "modelParams.topP", table: "Strings"))
                        }
                        .accentColor(.accentColor)
                        
                        Text(String(localized: "modelParams.topP.description", table: "Strings"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                HStack {
                    Button(String(localized: "modelParams.cancel", table: "Strings")) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Button(String(localized: "modelParams.reset", table: "Strings")) {
                        useCustomParameters = false
                        temperature = 0.7
                        topP = 0.9
                    }
                    
                    Button(String(localized: "modelParams.save", table: "Strings")) {
                        let parameters = useCustomParameters 
                            ? ModelParameters(temperature: temperature, topP: topP)
                            : .empty
                        chatVM.updateModelParameters(parameters)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(String(localized: "modelParams.title", table: "Strings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !didLoad {
                let current = chatVM.currentModelParameters()
                useCustomParameters = current.temperature != nil || current.topP != nil
                temperature = current.temperature ?? 0.7
                topP = current.topP ?? 0.9
                didLoad = true
            }
        }
    }
}

#if DEBUG
struct ModelParametersEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ModelParametersEditorView()
                .environmentObject(ChatViewModel.preview())
        }
    }
}
#endif
