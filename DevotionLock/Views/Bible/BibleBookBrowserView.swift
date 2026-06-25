//
//  BibleBookBrowserView.swift
//  DevotionLock
//

import SwiftUI

struct BibleBookBrowserView: View {
    @Environment(\.sanctuaryPalette) private var palette

    var requirePremium: (@escaping () -> Void) -> Void = { $0() }
    var onOpenChapter: (BibleBook, Int) -> Void

    @State private var browseTestament: BibleTestament?
    @State private var bookFilter = ""
    @State private var landingAppeared = false

    private var filteredBooks: [BibleBook] {
        guard let testament = browseTestament else { return [] }
        let books = BibleBookCatalog.books(for: testament)
        let query = bookFilter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return books }
        return books.filter { $0.name.lowercased().contains(query) }
    }

    var body: some View {
        Group {
            if let testament = browseTestament {
                bookList(for: testament)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
            } else {
                browseLanding
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(AppTheme.springSnappy, value: browseTestament)
    }

    // MARK: - Landing (Goodreads genres + Headway shortcuts)

    private var browseLanding: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose a testament")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .staggeredAppear(landingAppeared, delay: 0)

                VStack(spacing: 10) {
                    ScriptureTestamentTile(
                        testament: .old,
                        bookCount: BibleBookCatalog.books(for: .old).count
                    ) {
                        withAnimation(AppTheme.springSnappy) { browseTestament = .old }
                        DevotionHaptics.light()
                    }
                    ScriptureTestamentTile(
                        testament: .new,
                        bookCount: BibleBookCatalog.books(for: .new).count
                    ) {
                        withAnimation(AppTheme.springSnappy) { browseTestament = .new }
                        DevotionHaptics.light()
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .staggeredAppear(landingAppeared, delay: 0.04)

                ScriptureSectionHeader(title: "Quick open")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 4)
                    .staggeredAppear(landingAppeared, delay: 0.08)

                ScriptureGroupedList {
                    ForEach(Array(ScriptureQuickBook.shortcuts.enumerated()), id: \.element.slug) { index, shortcut in
                        if let book = ScriptureQuickBook.book(for: shortcut.slug) {
                            NavigationLink {
                                BibleChapterListView(
                                    book: book,
                                    requirePremium: requirePremium,
                                    onOpenChapter: onOpenChapter
                                )
                            } label: {
                                ScriptureListRow(
                                    badge: book.abbreviation,
                                    title: book.name,
                                    subtitle: "\(book.chapterCount) chapters",
                                    badgeTint: book.testament == .old ? ABY.Color.pillPurple : ABY.Color.pillTeal
                                )
                            }
                            .buttonStyle(ScriptureNavigationRowStyle())
                            if index < ScriptureQuickBook.shortcuts.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .staggeredAppear(landingAppeared, delay: 0.10)
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            landingAppeared = false
            withAnimation(AppTheme.springGentle) {
                landingAppeared = true
            }
        }
    }

    // MARK: - Book list (Fable rows)

    private func bookList(for testament: BibleTestament) -> some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation(AppTheme.springSnappy) {
                        browseTestament = nil
                        bookFilter = ""
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(testament.label)
                    }
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textPrimary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, ABY.Spacing.screen)

            bookFilterField
                .padding(.horizontal, ABY.Spacing.screen)
                .transition(.move(edge: .top).combined(with: .opacity))

            if filteredBooks.isEmpty {
                browseEmptyState
            } else {
                ScrollView(showsIndicators: false) {
                    ScriptureGroupedList {
                        ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                            NavigationLink {
                                BibleChapterListView(
                                    book: book,
                                    requirePremium: requirePremium,
                                    onOpenChapter: onOpenChapter
                                )
                            } label: {
                                ScriptureListRow(
                                    badge: book.abbreviation,
                                    title: book.name,
                                    subtitle: "\(book.chapterCount) chapters",
                                    badgeTint: testament == .old ? ABY.Color.pillPurple : ABY.Color.pillTeal
                                )
                            }
                            .buttonStyle(ScriptureNavigationRowStyle())

                            if index < filteredBooks.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private var bookFilterField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.textSecondary)
            TextField("Search books", text: $bookFilter)
                .font(ABY.Font.body)
            if !bookFilter.isEmpty {
                Button { bookFilter = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }

    private var browseEmptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "book.closed")
                .font(ABY.Font.largeTitle)
                .foregroundStyle(palette.textTertiary)
            Text("No books match")
                .font(ABY.Font.headline)
            Text("Try another name.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
            Spacer()
        }
    }

}

// MARK: - Chapter list (Apple Books list style)

struct BibleChapterListView: View {
    @Environment(\.sanctuaryPalette) private var palette

    let book: BibleBook
    var requirePremium: (@escaping () -> Void) -> Void = { $0() }
    let onOpenChapter: (BibleBook, Int) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(book.chapterCount) chapters · KJV")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.horizontal, ABY.Spacing.screen)

                ScriptureGroupedList {
                    ForEach(1...book.chapterCount, id: \.self) { chapter in
                        ScriptureListRow(
                            badge: "\(chapter)",
                            title: "Chapter \(chapter)",
                            subtitle: book.name,
                            badgeTint: book.testament == .old ? ABY.Color.pillPurple : ABY.Color.pillTeal,
                            trailingIcon: "book.pages",
                            action: { openChapter(chapter) }
                        )
                        if chapter < book.chapterCount {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openChapter(_ chapter: Int) {
        requirePremium {
            DevotionHaptics.light()
            onOpenChapter(book, chapter)
        }
    }
}
