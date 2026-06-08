//
//  SearchView.swift
//  test1
//

import SwiftUI

struct SearchView: View {
    var showsHeader: Bool = true

    @Environment(\.openConversation) private var openConversation
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @State private var query = ""
    @State private var appeared = false

    private var results: [JournalSearchResult] {
        JournalSearchService.search(query: query, tagFilter: selectedTagFilter)
    }

    private var selectedTagFilter: String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = ["Scripture", "Reflection", "Prayer", "Voice", "Chaplain"]
        if tags.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            return trimmed
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader {
                ABYScreenHeader(title: "Search", subtitle: "Find moments across your devotions")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
            } else {
                ABYDetailHeader(
                    title: "Search",
                    subtitle: "Find moments across your devotions"
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            VStack(spacing: 12) {
                ABYSearchBar(text: $query, placeholder: "Search devotions")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["All", "Scripture", "Reflection", "Prayer", "Voice", "Chaplain"], id: \.self) { tag in
                            ABYTagChip(label: tag, isSelected: tagMatches(tag))
                                .onTapGesture {
                                    PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                        withAnimation(AppTheme.springSnappy) {
                                            query = tag == "All" ? "" : tag
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 16)

            if query.isEmpty {
                emptyState
            } else if results.isEmpty {
                noResultsState
            } else {
                resultsList
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(!showsHeader)
        .toolbar {
            if !showsHeader { ABYBackToolbar() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
        .onChange(of: query) { previous, newValue in
            guard !newValue.isEmpty, !PaywallAccess.hasPremium else { return }
            query = previous
            presentPaywall()
        }
    }

    private func tagMatches(_ tag: String) -> Bool {
        query == tag || (query.isEmpty && tag == "All")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            VoiceOrb(state: .idle, size: 64)
            Text("Search your devotions")
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textPrimary)
            Text("Find journal entries, reflections, voice notes,\nand Chaplain conversations")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No results")
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textSecondary)
            Text("Try a different search term")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textTertiary)
            Spacer()
        }
    }

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    if let conversation = result.conversation {
                        JournalTimelineEntry(
                            conversation: conversation,
                            isLastInSection: index == results.count - 1
                        ) {
                            openConversation(conversation)
                        }
                    } else {
                        JourneySearchResultRow(result: result)
                    }
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 40)
        }
    }
}

private struct JourneySearchResultRow: View {
    let result: JournalSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.tag)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                Spacer()
                if let date = result.recordedAt {
                    Text(date, style: .time)
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textTertiary)
                }
            }
            Text(result.title)
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textPrimary)
            Text(result.preview)
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)
                .lineLimit(3)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ABY.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
    }
}

#Preview {
    ZStack {
        ABYBackground()
        SearchView()
    }
}
