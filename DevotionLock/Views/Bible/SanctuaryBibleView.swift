//
//  SanctuaryBibleView.swift
//  DevotionLock
//

import SwiftUI

struct SanctuaryBibleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.presentDevotionPaywall) private var presentPaywall

    var initialTopics: Set<PassageTopic> = []
    var initialTab: ScriptureTab = .discover
    var onSelect: ((SpiritualPassage) -> Void)? = nil

    @State private var query = ""
    @State private var selectedTopic: PassageTopic?
    @State private var tab: ScriptureTab
    @State private var meshOpacity: CGFloat = 0.12

    @State private var isLoadingChapter = false
    @State private var loadError: String?
    @State private var readerPresentation: BibleReaderPresentation?

    @FocusState private var searchFocused: Bool

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedTopic != nil
    }

    private var catalogResults: [SpiritualPassage] {
        var base = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? SpiritualPassageCatalog.all
            : SpiritualPassageCatalog.search(query)
        if let topic = selectedTopic {
            base = base.filter { $0.topics.contains(topic) }
        }
        return base
    }

    private var parsedReference: ParsedBibleReference? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return BibleReferenceParser.parse(trimmed)
    }

    private var libraryCount: Int {
        ScriptureLibraryStore.shared.count
    }

    init(
        initialTopics: Set<PassageTopic> = [],
        initialTab: ScriptureTab = .discover,
        onSelect: ((SpiritualPassage) -> Void)? = nil
    ) {
        self.initialTopics = initialTopics
        self.initialTab = initialTab
        self.onSelect = onSelect
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ABYBackground(meshOpacity: meshOpacity).ignoresSafeArea()

                VStack(spacing: 0) {
                    tabContent
                        .padding(.bottom, 88)
                }
                .animation(.easeOut(duration: 0.25), value: meshOpacity)

                ScriptureTabBar(selection: $tab, libraryCount: libraryCount)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 12)

                if isLoadingChapter {
                    MeshLoadingOverlay()
                        .transition(.opacity)
                }
            }
            .navigationTitle("Scripture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(onSelect == nil ? "Done" : "Cancel") { dismiss() }
                }
            }
            .onAppear {
                if selectedTopic == nil {
                    selectedTopic = SpiritualPassageCatalog.browsableTopics.first { initialTopics.contains($0) }
                }
            }
            .onChange(of: searchFocused) { _, focused in
                withAnimation(.easeOut(duration: 0.25)) {
                    meshOpacity = focused ? 0.2 : 0.12
                }
            }
            .fullScreenCover(item: $readerPresentation) { presentation in
                BibleChapterReaderView(
                    content: presentation.content,
                    highlightReference: presentation.highlightReference
                )
            }
            .alert("Could not open Scripture", isPresented: .init(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            )) {
                Button("OK", role: .cancel) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .discover:
            discoverTab
        case .books:
            BibleBookBrowserView { book, chapter in
                Task {
                    await openChapter(bookSlug: book.slug, bookName: book.name, chapter: chapter)
                }
            }
        case .library:
            ScriptureLibraryView()
        }
    }

    // MARK: - Discover (Blinkist search + Medium topics)

    private var discoverTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ScriptureSearchField(text: $query, focus: $searchFocused)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .onSubmit { tryOpenReference() }

                if let reference = parsedReference {
                    ScriptureReferenceBanner(reference: reference.displayReference) {
                        tryOpenReference()
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                }

                if !isSearching {
                    discoverHero
                }

                ScriptureSectionHeader(
                    title: isSearching ? "Topics" : "Browse by topic",
                    count: selectedTopic == nil ? nil : 1
                )
                .padding(.horizontal, ABY.Spacing.screen)

                ScriptureTopicGrid(
                    topics: SpiritualPassageCatalog.browsableTopics,
                    selected: selectedTopic
                ) { topic in
                    withAnimation(AppTheme.springSnappy) { selectedTopic = topic }
                    DevotionHaptics.light()
                }
                .padding(.horizontal, ABY.Spacing.screen)

                if isSearching {
                    resultsSection
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var discoverHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find a verse or a moment")
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
            Text("Search by reference, feeling, or theme — then save what speaks to you.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(3)
        }
        .padding(.horizontal, ABY.Spacing.screen)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScriptureSectionHeader(title: "Passages", count: catalogResults.count)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 4)

            if catalogResults.isEmpty {
                emptyResults
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(catalogResults.prefix(24).enumerated()), id: \.element.id) { index, passage in
                        ScripturePassageCard(
                            passage: passage,
                            isPickable: onSelect != nil,
                            isSaved: ScriptureLibraryStore.shared.isSaved(passage: passage),
                            onSave: {
                                DevotionHaptics.light()
                                ScriptureLibraryStore.shared.toggleCurated(passage)
                            },
                            action: {
                                if let onSelect {
                                    DevotionHaptics.light()
                                    onSelect(passage)
                                }
                            }
                        )
                        .blurRevealOnAppear(index: min(index, 8), stagger: 0.05)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.magnifyingglass")
                .font(ABY.Font.title)
                .foregroundStyle(palette.textTertiary)
            Text("No passages found")
                .font(ABY.Font.headline)
            Text(parsedReference != nil
                 ? "Tap the reference card above to open Scripture."
                 : "Try peace, hope, or a reference like Psalm 23.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, ABY.Spacing.screen)
    }

    private func tryOpenReference() {
        guard let reference = parsedReference else { return }
        searchFocused = false
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            DevotionHaptics.light()
            Task { await loadReference(reference) }
        }
    }

    @MainActor
    private func loadReference(_ reference: ParsedBibleReference) async {
        isLoadingChapter = true
        defer { isLoadingChapter = false }

        do {
            let content = try await BibleAPIService.shared.fetchReference(reference)
            readerPresentation = BibleReaderPresentation(
                content: content,
                highlightReference: reference.displayReference
            )
        } catch {
            loadError = error.localizedDescription
        }
    }

    @MainActor
    private func openChapter(bookSlug: String, bookName: String, chapter: Int) async {
        isLoadingChapter = true
        defer { isLoadingChapter = false }

        do {
            let content = try await BibleAPIService.shared.fetchChapter(bookSlug: bookSlug, chapter: chapter)
            readerPresentation = BibleReaderPresentation(
                content: content,
                highlightReference: "\(bookName) \(chapter)"
            )
        } catch {
            loadError = error.localizedDescription
        }
    }
}
