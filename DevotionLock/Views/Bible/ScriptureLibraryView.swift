//
//  ScriptureLibraryView.swift
//  DevotionLock
//

import SwiftUI

struct ScriptureLibraryView: View {
    @Environment(\.sanctuaryPalette) private var palette

    private var store = ScriptureLibraryStore.shared

    @State private var readerPresentation: BibleReaderPresentation?
    @State private var isLoadingChapter = false
    @State private var loadError: String?
    @State private var selectedCurated: SpiritualPassage?

    var body: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        ScriptureSectionHeader(title: "Saved passages", count: store.count)
                            .padding(.horizontal, ABY.Spacing.screen)

                        ScriptureGroupedList {
                            ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                                ScriptureListRow(
                                    badge: item.reference.prefix(2).uppercased(),
                                    title: item.reference,
                                    subtitle: String(item.text.prefix(72)) + (item.text.count > 72 ? "…" : ""),
                                    badgeTint: ABY.Color.pillTeal,
                                    trailingIcon: "bookmark.fill",
                                    action: { openSaved(item) }
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation(AppTheme.springSnappy) {
                                            store.remove(id: item.id)
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }

                                if index < store.items.count - 1 {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                        .padding(.horizontal, ABY.Spacing.screen)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .overlay {
            if isLoadingChapter {
                MeshLoadingOverlay(message: "Opening saved passage…")
            }
        }
        .fullScreenCover(item: $readerPresentation) { presentation in
            BibleChapterReaderView(
                content: presentation.content,
                highlightReference: presentation.highlightReference
            )
        }
        .sheet(item: $selectedCurated) { passage in
            CuratedPassageDetailSheet(passage: passage)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .alert("Could not open passage", isPresented: .init(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("OK", role: .cancel) { loadError = nil }
        } message: {
            Text(loadError ?? "")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bookmark")
                .font(ABY.Font.heroIcon)
                .foregroundStyle(palette.textTertiary)
            Text("Nothing saved yet")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Tap verses in the reader or bookmark a passage while you discover.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private func openSaved(_ item: SavedScripture) {
        if let catalogID = item.catalogPassageID,
           let passage = SpiritualPassageCatalog.all.first(where: { $0.id == catalogID }) {
            selectedCurated = passage
            return
        }

        guard let slug = item.bookSlug, let chapter = item.chapter else { return }
        Task { await reopenBible(item: item, slug: slug, chapter: chapter) }
    }

    @MainActor
    private func reopenBible(item: SavedScripture, slug: String, chapter: Int) async {
        isLoadingChapter = true
        defer { isLoadingChapter = false }

        do {
            var content = try await BibleAPIService.shared.fetchChapter(bookSlug: slug, chapter: chapter)
            if let start = item.startVerse {
                let end = item.endVerse ?? start
                let filtered = content.verses(in: start...end)
                if !filtered.isEmpty {
                    content = BibleChapterContent(
                        bookName: content.bookName,
                        bookSlug: content.bookSlug,
                        chapter: content.chapter,
                        version: content.version,
                        verses: filtered
                    )
                }
            }
            readerPresentation = BibleReaderPresentation(
                content: content,
                highlightReference: item.reference
            )
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct CuratedPassageDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let passage: SpiritualPassage

    var body: some View {
        NavigationStack {
            ZStack {
                ABYBackground().ignoresSafeArea()
                ScrollView {
                    ScripturePassageCard(
                        passage: passage,
                        isPickable: false,
                        isSaved: ScriptureLibraryStore.shared.isSaved(passage: passage),
                        onSave: { ScriptureLibraryStore.shared.toggleCurated(passage) },
                        action: {}
                    )
                    .padding(ABY.Spacing.screen)
                }
            }
            .navigationTitle("Saved passage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
