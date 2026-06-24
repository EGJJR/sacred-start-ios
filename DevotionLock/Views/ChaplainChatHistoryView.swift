//
//  ChaplainChatHistoryView.swift
//  DevotionLock
//
//  Mobbin refs:
//  - Copilot recents: https://mobbin.com/screens/40046f7b-1621-4099-a9e9-76910e645eb3
//  - Gemini chats: https://mobbin.com/screens/24e61d69-e92e-428f-a800-265e22419ae5
//  - Granola history: https://mobbin.com/screens/b4e1bb32-ec54-405a-a221-ad89d59b08a9
//

import SwiftUI

struct ChaplainChatHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.resumeChaplainChat) private var resumeChaplainChat

    @State private var repository = ConversationRepository.shared
    @State private var searchText = ""
    @State private var appeared = false
    @FocusState private var searchFocused: Bool

    private var chats: [Conversation] {
        let all = ConversationMerger.chaplainChats()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.preview.lowercased().contains(query)
                || $0.title.lowercased().contains(query)
        }
    }

    private var grouped: [(String, [Conversation])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let groups = Dictionary(grouping: chats) { conversation -> String in
            guard let date = conversation.recordedAt else { return "Earlier" }
            if Calendar.current.isDateInToday(date) { return "Today" }
            if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
            return formatter.string(from: date)
        }
        let order = ["Today", "Yesterday"]
        return groups.sorted { lhs, rhs in
            let li = order.firstIndex(of: lhs.key) ?? 99
            let ri = order.firstIndex(of: rhs.key) ?? 99
            if li != ri { return li < ri }
            return lhs.key > rhs.key
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ABYCleanGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        if chats.isEmpty {
                            emptyState
                        } else {
                            ChaplainChatHistoryGroupedList(groups: grouped, onSelect: openConversation)
                        }
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
                .abyScrollEdgeFades(top: false)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                historySearchBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Chats")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(ABY.Font.footnoteSemibold)
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: startNewChat) {
                        Image(systemName: "square.and.pencil")
                            .font(ABY.Font.calloutMedium)
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("New chat")
                }
            }
        }
        .abyScreen()
        .onAppear {
            Task { await repository.refresh() }
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var historySearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(ABY.Font.calloutMedium)
                .foregroundStyle(palette.textTertiary)

            TextField("Search chats", text: $searchText)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.divider.opacity(0.5), lineWidth: 1)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background {
            ABYCleanGradientBackground()
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(searchText.isEmpty ? "No saved chats yet" : "No matching chats")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text(
                searchText.isEmpty
                    ? "Conversations with your Chaplain will appear here after you save or continue a thread."
                    : "Try a different search term or start a new conversation."
            )
            .font(ABY.Font.callout)
            .foregroundStyle(palette.textSecondary)
            .lineSpacing(4)

            if !searchText.isEmpty {
                Button(action: startNewChat) {
                    Text("Start new chat")
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(ABY.Color.pillTeal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .padding(.top, 4)
            }
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
    }

    private func startNewChat() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            openChaplainChat(nil, [])
        }
    }

    private func openConversation(_ conversation: Conversation) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            resumeChaplainChat(conversation)
        }
    }
}

#Preview {
    ChaplainChatHistoryView()
        .environment(\.openChaplainChat) { _, _ in }
        .environment(\.resumeChaplainChat) { _ in }
}
