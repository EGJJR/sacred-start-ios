//
//  ChaplainChatView.swift
//  DevotionLock
//
//  Mobbin Gemini chat: https://mobbin.com/screens/8cb0be56-3634-46eb-bc04-7fd121164726
//

import SwiftUI

struct ChaplainMessage: Identifiable, Equatable, Hashable {
    enum Role { case user, chaplain }

    let id: UUID
    var role: Role
    var text: String
    var sentAt: Date?
    var scriptures: [ChaplainScriptureCitation]

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        sentAt: Date? = nil,
        scriptures: [ChaplainScriptureCitation] = []
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.sentAt = sentAt
        self.scriptures = scriptures
    }

    var displayText: String {
        ScriptureReplyFormatter.displayText(for: self)
    }
}

struct ChaplainChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    var voice: ChaplainVoice
    var seedMessages: [ChaplainMessage]
    var starterText: String
    var contextIntent: String? = nil
    var resumeConversationID: UUID? = nil
    var resumedContext: Conversation? = nil
    var onVoice: (() -> Void)? = nil
    var playsPortalEntrance: Bool = false

    @State private var messages: [ChaplainMessage] = []
    @State private var draft = ""
    @State private var isReplying = false
    @State private var conversationID: UUID?
    @State private var errorMessage: String?
    @State private var savedBanner: String?
    @State private var revealedMessageIDs: Set<UUID> = []
    @State private var showChatHistory = false
    @State private var scriptureSearchLabel: String?
    @State private var readerPresentation: BibleReaderPresentation?
    @State private var threadContext: Conversation?
    @State private var isHydratingResume = false
    @State private var dismissedResume = false
    @State private var showDiscardDraftAlert = false
    @State private var showStillReplyingAlert = false
    @State private var showDeleteConversationAlert = false
    @FocusState private var inputFocused: Bool
    @State private var sessionRevealed = false

    private var contentRevealed: Bool {
        playsPortalEntrance ? sessionRevealed : true
    }

    private var isResumedThread: Bool {
        !dismissedResume && (resumeConversationID != nil || threadContext != nil)
    }

    private var showSuggestions: Bool {
        messages.isEmpty && !isReplying && !isResumedThread && !isHydratingResume
    }

    private var headerTitle: String {
        if let firstUser = messages.first(where: { $0.role == .user })?.text {
            let trimmed = firstUser.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return Conversation.truncatedChaplainTitle(trimmed, limit: 48)
            }
        }
        return "Chaplain"
    }

    private var canDeleteConversation: Bool {
        conversationID != nil
    }

    private var resumedThreadDateLabel: String? {
        guard isResumedThread, let threadContext else { return nil }
        return threadContext.chaplainThreadDateLabel
    }

    private var hasActiveChaplainDraft: Bool {
        guard let last = messages.last, last.role == .chaplain else { return false }
        return !last.text.isEmpty || !last.scriptures.isEmpty
    }

    private var presenceMode: ChaplainPresenceMode? {
        if isHydratingResume { return .loadingThread }
        if let scriptureSearchLabel { return .searchingScripture(scriptureSearchLabel) }
        if isReplying, !hasActiveChaplainDraft { return .thinking }
        return nil
    }

    private func isStreamingMessage(_ message: ChaplainMessage) -> Bool {
        guard isReplying, message.role == .chaplain, message.id == messages.last?.id else { return false }
        return !message.text.isEmpty
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if showSuggestions {
                        GeminiChatGreeting()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if isHydratingResume {
                        EmptyView()
                    } else if let resumedThreadDateLabel, isResumedThread, !messages.isEmpty {
                        ChaplainThreadDateDivider(label: resumedThreadDateLabel)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    ForEach(messages) { message in
                        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                            if message.role == .chaplain, !message.scriptures.isEmpty {
                                ChaplainScriptureCitationStack(
                                    citations: message.scriptures,
                                    onReadChapter: openReader(for:),
                                    onSave: saveCitation(_:)
                                )
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }

                            ChaplainChatBubble(
                                message: message,
                                timestamp: message.role == .chaplain ? formattedTime(message.sentAt) : nil,
                                isRevealed: revealedMessageIDs.contains(message.id),
                                isStreaming: isStreamingMessage(message)
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                        .id(message.id)
                        .transition(messageTransition(for: message))
                    }

                    if let presenceMode {
                        ChaplainPresenceIndicator(mode: presenceMode)
                            .padding(.top, messages.isEmpty && presenceMode == .loadingThread ? 28 : 0)
                            .id("presence")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    if let savedBanner {
                        Text(savedBanner)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(ABY.Color.pillPurple)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(ABY.Color.pillPurple.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, messages.isEmpty ? 8 : 20)
                .frame(maxWidth: .infinity)
                .blurReveal(contentRevealed, blurRadius: playsPortalEntrance ? 10 : 0, scale: 1.008)
                .animation(AppTheme.springGentle, value: messages.count)
                .animation(AppTheme.springGentle, value: presenceMode)
            }
            .defaultScrollAnchor(messages.isEmpty ? .top : .bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: messages.last?.text) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: presenceMode) { _, mode in
                if mode != nil {
                    scrollToBottom(proxy: proxy, anchor: "presence")
                }
            }
            .onChange(of: isReplying) { _, replying in
                if replying {
                    scrollToBottom(proxy: proxy, anchor: "presence")
                } else {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            chatHeader
                .blurReveal(contentRevealed, blurRadius: playsPortalEntrance ? 6 : 0, scale: 1.004)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            chatComposer
        }
        .background {
            ABYChatWashBackground()
        }
        .abyScreen()
        .sheet(isPresented: $showChatHistory) {
            ChaplainChatHistoryView()
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .sheet(item: $readerPresentation) { presentation in
            NavigationStack {
                BibleChapterReaderView(
                    content: presentation.content,
                    highlightReference: presentation.highlightReference
                )
            }
        }
        .onAppear(perform: beginSessionAppearance)
        .task(id: resumeConversationID) {
            guard !dismissedResume else { return }
            await hydrateResumeConversationIfNeeded()
        }
        .alert("Still replying", isPresented: $showStillReplyingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Wait for Chaplain to finish before starting a new conversation.")
        }
        .alert("Discard unsent message?", isPresented: $showDiscardDraftAlert) {
            Button("Discard", role: .destructive) {
                draft = ""
                startNewChat()
            }
            Button("Keep writing", role: .cancel) {}
        } message: {
            Text("You have text in the composer that hasn't been sent yet.")
        }
        .alert("Delete conversation?", isPresented: $showDeleteConversationAlert) {
            Button("Delete", role: .destructive) {
                Task { await deleteCurrentConversation() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the conversation from your Chaplain history.")
        }
    }

    private var chatHeader: some View {
        ChaplainChatScreenHeader(
            voice: voice,
            threadTitle: headerTitle,
            onBack: { dismiss() },
            onNewChat: requestNewChat,
            onShowHistory: { showChatHistory = true },
            onDeleteConversation: canDeleteConversation ? { showDeleteConversationAlert = true } : nil
        )
    }

    private var chatComposer: some View {
        VStack(spacing: 10) {
            if showSuggestions {
                GeminiChatSuggestionRail { prompt in
                    inputFocused = false
                    draft = prompt
                    sendDraft()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            GeminiChatInputBar(
                text: $draft,
                placeholder: "Ask Chaplain",
                onSend: sendDraft,
                onVoice: onVoice,
                floatingStyle: true,
                isBusy: isReplying,
                focused: $inputFocused
            )
            .padding(.horizontal, ABY.Spacing.screen)

            if showSuggestions, !inputFocused {
                ABYChatDisclaimer()
                    .padding(.horizontal, ABY.Spacing.screen)
                    .transition(.opacity)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background {
            if palette.isNight {
                LinearGradient(
                    colors: [.clear, ABY.Color.eveningReflectionBottom.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .blurReveal(contentRevealed, blurRadius: playsPortalEntrance ? 8 : 0, scale: 1.01)
        .animation(AppTheme.springSnappy, value: showSuggestions)
        .animation(.easeOut(duration: 0.2), value: inputFocused)
    }

    private func messageTransition(for message: ChaplainMessage) -> AnyTransition {
        switch message.role {
        case .user:
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            )
        case .chaplain:
            .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .opacity
            )
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String? = nil) {
        withAnimation(AppTheme.springGentle) {
            if let anchor {
                proxy.scrollTo(anchor, anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func formattedTime(_ date: Date?) -> String? {
        guard let date else { return nil }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private static func initialMessages(from seeds: [ChaplainMessage]) -> [ChaplainMessage] {
        seeds
    }

    private static func role(forTranscriptSpeaker speaker: String) -> ChaplainMessage.Role {
        switch speaker.lowercased() {
        case "you", "user": .user
        default: .chaplain
        }
    }

    private func beginSessionAppearance() {
        beginSession()
        guard playsPortalEntrance else { return }
        withAnimation(AppTheme.springGentle.delay(0.05)) {
            sessionRevealed = true
        }
        DevotionHaptics.success()
    }

    private func beginSession() {
        errorMessage = nil
        isReplying = false
        draft = ""
        revealedMessageIDs = []
        dismissedResume = false
        threadContext = resumedContext

        if resumeConversationID == nil {
            conversationID = nil
            messages = Self.initialMessages(from: seedMessages)
            isHydratingResume = false
        } else if messages.isEmpty {
            messages = Self.initialMessages(from: seedMessages)
            isHydratingResume = true
        }

        for message in messages {
            revealMessage(message.id, delay: 0.12)
        }

        if !starterText.isEmpty {
            draft = starterText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                sendDraft()
            }
        }
    }

    private func revealMessage(_ id: UUID, delay: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.32)) {
                _ = revealedMessageIDs.insert(id)
            }
        }
    }

    @MainActor
    private func hydrateResumeConversationIfNeeded() async {
        guard !dismissedResume else { return }
        guard let resumeConversationID else { return }

        isHydratingResume = true
        defer { isHydratingResume = false }

        let conversation = await ConversationRepository.shared.loadTranscript(for: resumeConversationID)
            ?? ConversationRepository.shared.conversation(for: resumeConversationID)
            ?? ConversationMerger.mergedTimeline().first {
                $0.id == resumeConversationID || $0.remoteID == resumeConversationID
            }
            ?? resumedContext

        guard let conversation else {
            messages = Self.initialMessages(from: seedMessages)
            threadContext = resumedContext
            return
        }

        threadContext = conversation
        conversationID = conversation.remoteID ?? conversation.id
        messages = conversation.transcript.map { segment in
            ChaplainMessage(
                role: Self.role(forTranscriptSpeaker: segment.speaker),
                text: segment.text,
                sentAt: conversation.recordedAt
            )
        }
        if messages.isEmpty {
            messages = Self.initialMessages(from: seedMessages)
        }
        revealedMessageIDs = []
        for (index, message) in messages.enumerated() {
            revealMessage(message.id, delay: 0.06 + Double(index) * 0.04)
        }
    }

    private func sendDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isReplying else { return }

        draft = ""
        inputFocused = false
        errorMessage = nil
        let userMessage = ChaplainMessage(role: .user, text: trimmed, sentAt: Date())
        withAnimation(AppTheme.springSnappy) {
            messages.append(userMessage)
        }
        revealMessage(userMessage.id)
        isReplying = true
        DevotionHaptics.light()

        Task {
            await streamChaplainReply()
        }
    }

    @MainActor
    private func streamChaplainReply() async {
        let apiMessages = messages
        var chaplainIndex: Int?
        var draftMessageID: UUID?

        func ensureChaplainDraft() -> Int {
            if let chaplainIndex { return chaplainIndex }
            let chaplainMessage = ChaplainMessage(role: .chaplain, text: "", sentAt: Date())
            draftMessageID = chaplainMessage.id
            withAnimation(AppTheme.springGentle) {
                messages.append(chaplainMessage)
            }
            let index = messages.count - 1
            chaplainIndex = index
            revealMessage(chaplainMessage.id, delay: 0.08)
            return index
        }

        do {
            let intent = resolvedIntent(for: apiMessages.last(where: { $0.role == .user })?.text)
            let userText = apiMessages.last(where: { $0.role == .user })?.text ?? ""
            let mood = UserDefaults.standard.string(forKey: "intentionMood") ?? "Peaceful"
            let prefetched = await ScriptureCorpus.prefetch(for: userText, mood: mood)
            let context = ChaplainContextBuilder.build(
                intent: intent,
                prefetchedScripture: prefetched
            )
            let stream = try await ChaplainService.shared.streamReply(
                conversationID: conversationID,
                messages: apiMessages,
                context: context
            )

            for try await event in stream {
                switch event {
                case .conversationID(let id):
                    conversationID = id
                case .scriptureSearch(let label):
                    scriptureSearchLabel = label
                case .scriptureResult(let citations):
                    scriptureSearchLabel = nil
                    let index = ensureChaplainDraft()
                    var merged = messages[index].scriptures
                    for citation in citations {
                        let normalized = ChaplainScriptureCitation(
                            id: citation.id,
                            reference: citation.reference,
                            text: citation.displayText,
                            source: citation.source,
                            bookSlug: citation.bookSlug,
                            chapter: citation.chapter,
                            startVerse: citation.startVerse,
                            endVerse: citation.endVerse,
                            catalogPassageID: citation.catalogPassageID,
                            version: citation.version
                        )
                        guard !merged.contains(normalized) else { continue }
                        merged.append(normalized)
                    }
                    messages[index].scriptures = merged
                case .token(let text):
                    scriptureSearchLabel = nil
                    let index = ensureChaplainDraft()
                    messages[index].text += text
                case .done:
                    scriptureSearchLabel = nil
                    if let index = chaplainIndex {
                        messages[index].text = ScriptureReplyFormatter.displayText(
                            for: messages[index]
                        )
                    }
                    break
                }
            }

            if let index = chaplainIndex {
                if messages[index].text.isEmpty {
                    messages[index].text = "I'm here with you. Could you share a little more?"
                }
            } else {
                let fallback = ChaplainMessage(
                    role: .chaplain,
                    text: "I'm here with you. Could you share a little more?",
                    sentAt: Date()
                )
                withAnimation(AppTheme.springGentle) {
                    messages.append(fallback)
                }
                revealMessage(fallback.id, delay: 0.08)
                chaplainIndex = messages.count - 1
            }

            if let conversationID, let index = chaplainIndex {
                let title = messages.first(where: { $0.role == .user })?.text
                ChaplainSessionStore.shared.recordActiveConversation(
                    id: conversationID,
                    title: title,
                    preview: messages[index].text
                )
            }

            await ConversationRepository.shared.refresh()
        } catch {
            errorMessage = error.localizedDescription
            if let index = chaplainIndex,
               messages[index].text.isEmpty,
               messages[index].scriptures.isEmpty {
                withAnimation(AppTheme.springGentle) {
                    messages.remove(at: index)
                    ()
                }
                if let draftMessageID {
                    revealedMessageIDs.remove(draftMessageID)
                }
            }
        }

        isReplying = false
        scriptureSearchLabel = nil
    }

    @MainActor
    private func openReader(for citation: ChaplainScriptureCitation) {
        guard let slug = citation.bookSlug, let chapter = citation.chapter else { return }
        Task {
            do {
                let content = try await BibleAPIService.shared.fetchChapter(bookSlug: slug, chapter: chapter)
                readerPresentation = BibleReaderPresentation(
                    content: content,
                    highlightReference: citation.reference
                )
            } catch {
                errorMessage = "Couldn't open that chapter right now."
            }
        }
    }

    @MainActor
    private func saveCitation(_ citation: ChaplainScriptureCitation) {
        if let catalogID = citation.catalogPassageID,
           let passage = SpiritualPassageCatalog.all.first(where: { $0.id == catalogID }) {
            ScriptureLibraryStore.shared.toggleCurated(passage)
            savedBanner = ScriptureLibraryStore.shared.isSaved(passage: passage)
                ? "Saved to your sanctuary library"
                : "Removed from library"
            return
        }

        if let slug = citation.bookSlug, let chapter = citation.chapter {
            Task {
                do {
                    let content = try await BibleAPIService.shared.fetchChapter(bookSlug: slug, chapter: chapter)
                    let verses = content.verses
                    let filtered: [BibleVerse]
                    if let start = citation.startVerse {
                        let end = citation.endVerse ?? start
                        filtered = verses.filter { $0.verseNumber >= start && $0.verseNumber <= end }
                    } else {
                        filtered = verses
                    }
                    let saved = ScriptureLibraryStore.shared.toggleBible(
                        verses: filtered.isEmpty ? verses : filtered,
                        content: content,
                        reference: citation.reference
                    )
                    savedBanner = saved ? "Saved to your sanctuary library" : "Removed from library"
                } catch {
                    errorMessage = "Couldn't save that passage right now."
                }
            }
        }
    }

    private func resolvedIntent(for userText: String?) -> String? {
        if let contextIntent { return contextIntent }
        guard let userText else { return nil }
        let lower = userText.lowercased()
        if lower.contains("bible") || lower.contains("scripture") || lower.contains("verse") {
            return "bible_question"
        }
        return nil
    }

    private func requestNewChat() {
        if isReplying {
            showStillReplyingAlert = true
            return
        }
        let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDraft.isEmpty {
            showDiscardDraftAlert = true
            return
        }
        startNewChat()
    }

    @MainActor
    private func startNewChat() {
        dismissedResume = true
        conversationID = nil
        threadContext = nil
        messages = Self.initialMessages(from: [])
        draft = ""
        errorMessage = nil
        savedBanner = nil
        revealedMessageIDs = []
        isHydratingResume = false
        isReplying = false
        scriptureSearchLabel = nil
        inputFocused = false
        DevotionHaptics.light()
    }

    @MainActor
    private func deleteCurrentConversation() async {
        guard let conversationID else { return }
        await ConversationRepository.shared.deleteConversation(id: conversationID)
        startNewChat()
        DevotionHaptics.success()
    }
}

#Preview {
    ChaplainChatView(
        voice: ChaplainVoice.options[0],
        seedMessages: [],
        starterText: ""
    )
    .environment(\.authManager, AuthManager.shared)
}
