//
//  PassageSearchView.swift
//  DevotionLock
//
//  Entry point for Scripture browse. Routes to SanctuaryBibleView when the
//  bible reader feature flag is on; otherwise shows curated passages only.
//

import SwiftUI

struct PassageSearchView: View {
    var initialTopics: Set<PassageTopic> = []
    var initialTab: ScriptureTab = .discover
    var onSelect: ((SpiritualPassage) -> Void)? = nil

    var body: some View {
        if FeatureFlags.bibleReaderEnabled {
            SanctuaryBibleView(initialTopics: initialTopics, initialTab: initialTab, onSelect: onSelect)
        } else {
            LegacyPassageSearchView(initialTopics: initialTopics, onSelect: onSelect)
        }
    }
}

// MARK: - Legacy curated-only browser (feature flag off)

private struct LegacyPassageSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    var initialTopics: Set<PassageTopic> = []
    var onSelect: ((SpiritualPassage) -> Void)? = nil

    @State private var query = ""
    @State private var selectedTopic: PassageTopic?
    @FocusState private var searchFocused: Bool

    private var results: [SpiritualPassage] {
        var base = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? SpiritualPassageCatalog.all
            : SpiritualPassageCatalog.search(query)
        if let topic = selectedTopic {
            base = base.filter { $0.topics.contains(topic) }
        }
        return base
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ABYBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    topicRail
                        .padding(.bottom, 8)

                    if results.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(results) { passage in
                                    ScripturePassageCard(
                                        passage: passage,
                                        isPickable: onSelect != nil,
                                        isSaved: ScriptureLibraryStore.shared.isSaved(passage: passage),
                                        onSave: { ScriptureLibraryStore.shared.toggleCurated(passage) },
                                        action: {
                                            if let onSelect {
                                                DevotionHaptics.light()
                                                onSelect(passage)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 32)
                        }
                        .scrollDismissesKeyboard(.immediately)
                    }
                }
            }
            .navigationTitle("Passages & Promises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(onSelect == nil ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if selectedTopic == nil {
                selectedTopic = SpiritualPassageCatalog.browsableTopics.first { initialTopics.contains($0) }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.textSecondary)
            TextField("Search by word, theme, or author", text: $query)
                .focused($searchFocused)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(palette.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
    }

    private var topicRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                LegacyTopicPill(label: "All", icon: "square.grid.2x2", tint: palette.textSecondary, isSelected: selectedTopic == nil) {
                    withAnimation(AppTheme.springSnappy) { selectedTopic = nil }
                }
                ForEach(SpiritualPassageCatalog.browsableTopics) { topic in
                    LegacyTopicPill(label: topic.label, icon: topic.icon, tint: topic.tint, isSelected: selectedTopic == topic) {
                        withAnimation(AppTheme.springSnappy) {
                            selectedTopic = (selectedTopic == topic) ? nil : topic
                        }
                        DevotionHaptics.light()
                    }
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "sparkle.magnifyingglass")
                .font(ABY.Font.heroIcon)
                .foregroundStyle(palette.textTertiary)
            Text("No passages found")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Try another word or pick a theme above.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

private struct LegacyTopicPill: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(ABY.Font.captionSemibold)
                Text(label)
                    .font(ABY.Font.captionMedium)
            }
            .foregroundStyle(isSelected ? .white : palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? tint : palette.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : palette.divider, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PassageSearchView(initialTopics: [.peace]) { _ in }
}
