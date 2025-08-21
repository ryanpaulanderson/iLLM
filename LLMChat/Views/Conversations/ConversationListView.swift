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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let onSelect: ((Conversation) -> Void)?
    @State private var isCreatingNew = false
    @State private var conversationToDelete: Conversation?
    @State private var showDeleteConfirmation = false
    
    init(onSelect: ((Conversation) -> Void)? = nil) {
        self.onSelect = onSelect
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Create a new conversation
                    let newConv = chatVM.startNewConversation()
                    onSelect?(newConv)
                    
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
                    
                    // Dismiss on iPhone to go back to chat
                    if horizontalSizeClass == .compact {
                        dismiss()
                    }
                } label: {
                    Label {
                        Text(String(localized: "conversations.new", table: "Strings"))
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
            
            Section(header: Text(String(localized: "conversations.section.title", table: "Strings"))) {
                ForEach(chatVM.conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .contentShape(Rectangle())  // Make entire row tappable
                        .onTapGesture {
                            // Haptic feedback for selection
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                            
                            onSelect?(conversation)
                            
                            // Dismiss on iPhone to go back to chat
                            if horizontalSizeClass == .compact {
                                dismiss()
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                conversationToDelete = conversation
                                showDeleteConfirmation = true
                            } label: {
                                Label(String(localized: "conversations.delete", table: "Strings"), systemImage: "trash")
                            }
                            .tint(.red)
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .alert(String(localized: "conversations.delete.confirmation.title", table: "Strings"), 
               isPresented: $showDeleteConfirmation) {
            Button(String(localized: "conversations.delete", table: "Strings"), role: .destructive) {
                if let conversation = conversationToDelete {
                    chatVM.deleteConversation(conversation)
                    conversationToDelete = nil
                }
            }
            Button(String(localized: "common.cancel", table: "Strings"), role: .cancel) {
                conversationToDelete = nil
            }
        } message: {
            Text(String(localized: "conversations.delete.confirmation.message", table: "Strings"))
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
                .environmentObject(ChatViewModel.preview())
        }
    }
}
#endif