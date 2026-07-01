//
//  ChaplainChatHistoryView.swift
//  DevotionLock
//
//  Mobbin refs:
//  - Granola chat history: https://mobbin.com/screens/b4e1bb32-ec54-405a-a221-ad89d59b08a9
//  - Gemini chats: https://mobbin.com/screens/9e114d8f-6ebd-4c4a-859d-0617a100cbf7
//  - ChatGPT history: https://mobbin.com/screens/5e55dde4-61e8-4f5d-95c0-7a9da129ec91
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
    @State private var pendingDelete: Conversation?
    @State private var deletedBanner: String?
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
            let lhsDate = lhs.value.compactMap(\.recordedAt).max() ?? .distantPast
            let rhsDate = rhs.value.compactMap(\.recordedAt).max() ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ABYFlatTabWashBackground()

                VStack(spacing: 0) {
                    historySearchBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if chats.isEmpty {
                                emptyState
                                    .padding(.top, 8)
                                    .blurReveal(appeared, blurRadius: 6, scale: 1.004)
                            } else {
                                ChaplainChatHistoryGroupedList(
                                    groups: grouped,
                                    onSelect: openConversation,
                                    onDelete: requestDelete
                                )
                                .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                            }
                        }
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                    }
                    .abyTransparentScroll()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Chats")
                        .font(ABY.Font.navTitle)
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
                            .foregroundStyle(ABY.Color.pillTeal)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("New chat")
                }
            }
        }
        .abyScreen()
        .sheet(item: $pendingDelete) { conversation in
            ChaplainDeleteChatSheet(
                conversation: conversation,
                onCancel: { pendingDelete = nil },
                onConfirm: {
                    let title = conversation.chaplainHistoryTitle
                    pendingDelete = nil
                    confirmDelete(conversation, bannerTitle: title)
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .overlay(alignment: .bottom) {
            if let deletedBanner {
                Text(deletedBanner)
                    .font(ABY.Font.footnoteMedium)
                    .foregroundStyle(palette.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(palette.cardFill)
                            .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 14, y: 6)
                    }
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(AppTheme.springGentle, value: deletedBanner)
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
                .tint(palette.textPrimary)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(palette.composerFill)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.isNight ? 0 : palette.cardShadowOpacity * 0.35), radius: 8, y: 2)
        .colorScheme(palette.isNight ? .dark : .light)
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ABY.Color.pillTeal)
                .frame(width: 44, height: 44)
                .background(ABY.Color.pillTeal.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                .padding(.top, 2)
            }
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 12, y: 4)
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

    private func requestDelete(_ conversation: Conversation) {
        DevotionHaptics.light()
        pendingDelete = conversation
    }

    private func confirmDelete(_ conversation: Conversation, bannerTitle: String) {
        DevotionHaptics.medium()
        Task {
            await repository.deleteConversation(id: conversation.remoteID ?? conversation.id)
        }
        deletedBanner = "“\(bannerTitle)” deleted"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(AppTheme.springGentle) {
                deletedBanner = nil
            }
        }
    }
}

private struct ChaplainDeleteChatSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(palette.divider.opacity(0.55))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 10) {
                Text("Delete this chat?")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(conversation.chaplainHistoryTitle)
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.surfaceMuted.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("This removes the conversation from your history. It can't be undone.")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, ABY.Spacing.screen)

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                Button(action: onConfirm) {
                    Text("Delete chat")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text("Keep chat")
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ABYFlatTabWashBackground())
    }
}

#Preview {
    ChaplainChatHistoryView()
        .environment(\.openChaplainChat) { _, _ in }
        .environment(\.resumeChaplainChat) { _ in }
}
