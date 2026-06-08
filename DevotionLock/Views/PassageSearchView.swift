//
//  PassageSearchView.swift
//  DevotionLock
//
//  A calm, topical way to search Scripture, promises, and wisdom by theme
//  or keyword. Reusable as a sheet (pick a passage) or a standalone browser.
//

import SwiftUI

struct PassageSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    var initialTopics: Set<PassageTopic> = []
    /// When provided, the view acts as a picker and calls back on selection.
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
                                    PassageResultCard(passage: passage, isPickable: onSelect != nil) {
                                        if let onSelect {
                                            DevotionHaptics.light()
                                            onSelect(passage)
                                        }
                                    }
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
                TopicPill(label: "All", icon: "square.grid.2x2", tint: palette.textSecondary, isSelected: selectedTopic == nil) {
                    withAnimation(AppTheme.springSnappy) { selectedTopic = nil }
                }
                ForEach(SpiritualPassageCatalog.browsableTopics) { topic in
                    TopicPill(label: topic.label, icon: topic.icon, tint: topic.tint, isSelected: selectedTopic == topic) {
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
                .font(.system(size: 40, weight: .light))
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

private struct TopicPill: View {
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
                    .font(.system(size: 12, weight: .semibold))
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

private struct PassageResultCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let passage: SpiritualPassage
    let isPickable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(passage.source.label.uppercased())
                        .font(ABY.Font.section)
                        .tracking(0.6)
                        .foregroundStyle(passage.topics.first?.tint ?? palette.textSecondary)
                    Spacer()
                    if let topic = passage.topics.first {
                        HStack(spacing: 4) {
                            Image(systemName: topic.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(topic.label)
                                .font(ABY.Font.caption)
                        }
                        .foregroundStyle(palette.textSecondary)
                    }
                }

                Text(passage.text)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(passage.attribution)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    if isPickable {
                        HStack(spacing: 4) {
                            Text("Use this")
                            Image(systemName: "arrow.right")
                        }
                        .font(ABY.Font.caption.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .allowsHitTesting(isPickable)
    }
}

#Preview {
    PassageSearchView(initialTopics: [.peace]) { _ in }
}
