//
//  ConversationListView.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Conversation list sidebar for multi-chat support
//

import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var conversations = Conversation.mockConversations
    @State private var selectedConversation: Conversation?
    @State private var isCreatingNew = false
    
    var body: some View {
        List(selection: $selectedConversation) {
            Section {
                Button {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Clear messages to start a new conversation
                    chatVM.clearConversation()
                    selectedConversation = nil
                    
                    // Visual feedback
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCreatingNew = true
                    }
                    
                    // Reset visual feedback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            isCreatingNew = false
                        }
                    }
                } label: {
                    Label {
                        Text("New Conversation")
                            .font(.body.weight(.medium))
                    } icon: {
                        Image(systemName: isCreatingNew ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundColor(isCreatingNew ? .green : .accentColor)
                            .scaleEffect(isCreatingNew ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCreatingNew)
                    }
                }
                .buttonStyle(.plain)  // Use plain style to ensure it's tappable
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            
            Section(header: Text("Recent")) {
                ForEach(conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .tag(conversation)
                        .contentShape(Rectangle())  // Make entire row tappable
                        .onTapGesture {
                            // Haptic feedback for selection
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                            
                            selectedConversation = conversation
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Conversations")
        .onAppear {
            // Select the first active conversation by default
            selectedConversation = conversations.first { $0.isActive }
        }
    }
}

// MARK: - ConversationRow
private struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            
            if let lastMessage = conversation.lastMessage {
                Text(lastMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Text(conversation.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(conversation.title), \(conversation.lastMessage ?? ""), \(conversation.timestamp, style: .relative)")
        )
    }
}

// MARK: - Previews
#if DEBUG
struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConversationListView()
        }
    }
}
#endif