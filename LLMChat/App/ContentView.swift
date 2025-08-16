// LLMChat/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var showSettings = false
    @State private var showModelSelection = false

    var body: some View {
        NavigationStack {
            ChatView()
                .navigationTitle("LLM Chat")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showModelSelection = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(chatVM)
                }
                .sheet(isPresented: $showModelSelection) {
                    ModelSelectionView()
                        .environmentObject(chatVM)
                }
        }
        .onAppear {
            chatVM.bootstrap()
        }
    }
}