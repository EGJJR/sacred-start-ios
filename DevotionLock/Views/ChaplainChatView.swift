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

    init(id: UUID = UUID(), role: Role, text: String, sentAt: Date? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.sentAt = sentAt
    }
}

struct ChaplainChatView: View {
    @Environment(\.dismiss) private var dismiss
    var voice: ChaplainVoice
    var seedMessages: [ChaplainMessage]
    var starterText: String
    var contextIntent: String? = nil
    var resumeConversationID: UUID? = nil
    var onVoice: (() -> Void)? = nil

    @State private var messages: [ChaplainMessage] = []
    @State private var draft = ""
    @State private var isReplying = false
    @State private var conversationID: UUID?
    @State private var errorMessage: String?
    @State private var savedBanner: String?
    @State private var revealedMessageIDs: Set<UUID> = []
    @State private var showChatHistory = false
    @FocusState private var inputFocused: Bool

    private var showSuggestions: Bool {
        messages.isEmpty && !isReplying
    }

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()

            VStack(spacing: 0) {
                ABYChatScreenHeader(
                    voiceName: voice.name,
                    onClose: { dismiss() },
                    onHistory: { showChatHistory = true },
                    geminiStyle: true
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if showSuggestions {
                                GeminiChatGreeting()
                            }

                            ForEach(messages) { message in
                                ChaplainChatBubble(
                                    message: message,
                                    timestamp: message.role == .chaplain ? formattedTime(message.sentAt) : nil,
                                    isRevealed: revealedMessageIDs.contains(message.id)
                                )
                                .id(message.id)
                            }

                            if isReplying {
                                ChaplainTypingIndicator()
                                    .id("typing")
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
                        .padding(.top, 8)
                        .padding(.bottom, messages.isEmpty ? 12 : 24)
                        .frame(maxWidth: .infinity)
                    }
                    .defaultScrollAnchor(messages.isEmpty ? .top : .bottom)
                    .scrollDismissesKeyboard(.interactively)
                    .abyScrollEdgeFades(bottom: false)
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: messages.last?.text) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isReplying) { _, replying in
                        if replying {
                            scrollToBottom(proxy: proxy, anchor: "typing")
                        } else {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                chatComposer
            }
        }
        .abyScreen()
        .sheet(isPresented: $showChatHistory) {
            ChaplainChatHistoryView()
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .onAppear(perform: beginSession)
        .task(id: resumeConversationID) {
            await hydrateResumeConversationIfNeeded()
        }
    }

    private var chatComposer: some View {
        VStack(spacing: 8) {
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
                focused: $inputFocused
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .disabled(isReplying)

            if showSuggestions, !inputFocused {
                ABYChatDisclaimer()
                    .padding(.horizontal, ABY.Spacing.screen)
                    .transition(.opacity)
            }
        }
        .padding(.top, inputFocused ? 10 : (messages.isEmpty ? 10 : 6))
        .padding(.bottom, inputFocused ? 6 : 10)
        .background {
            if messages.isEmpty {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            } else if inputFocused {
                VStack(spacing: 0) {
                    Divider().opacity(0.35)
                    Rectangle()
                        .fill(Color.white.opacity(0.94))
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            }
        }
        .animation(AppTheme.springSnappy, value: showSuggestions)
        .animation(.easeOut(duration: 0.2), value: inputFocused)
        .animation(.easeOut(duration: 0.2), value: messages.isEmpty)
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

    private func beginSession() {
        errorMessage = nil
        isReplying = false
        draft = ""
        revealedMessageIDs = []

        if resumeConversationID == nil {
            conversationID = nil
            messages = Self.initialMessages(from: seedMessages)
        } else if messages.isEmpty {
            messages = Self.initialMessages(from: seedMessages)
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
        guard let resumeConversationID else { return }

        let conversation = await ConversationRepository.shared.loadTranscript(for: resumeConversationID)
            ?? ConversationRepository.shared.conversation(for: resumeConversationID)
            ?? ConversationMerger.mergedTimeline().first {
                $0.id == resumeConversationID || $0.remoteID == resumeConversationID
            }

        guard let conversation else {
            messages = Self.initialMessages(from: seedMessages)
            return
        }

        conversationID = conversation.remoteID ?? conversation.id
        messages = conversation.transcript.map {
            ChaplainMessage(
                role: $0.speaker == "You" ? .user : .chaplain,
                text: $0.text
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
        messages.append(userMessage)
        revealMessage(userMessage.id)
        isReplying = true

        Task {
            await streamChaplainReply()
        }
    }

    @MainActor
    private func streamChaplainReply() async {
        let apiMessages = messages
        let chaplainIndex = messages.count
        let chaplainMessage = ChaplainMessage(role: .chaplain, text: "", sentAt: Date())
        messages.append(chaplainMessage)
        revealMessage(chaplainMessage.id, delay: 0.2)

        do {
            let intent = resolvedIntent(for: apiMessages.last(where: { $0.role == .user })?.text)
            let context = ChaplainContextBuilder.build(intent: intent)
            let stream = try await ChaplainService.shared.streamReply(
                conversationID: conversationID,
                messages: apiMessages,
                context: context
            )

            for try await event in stream {
                switch event {
                case .conversationID(let id):
                    conversationID = id
                case .token(let text):
                    messages[chaplainIndex].text += text
                case .done:
                    break
                }
            }

            if messages[chaplainIndex].text.isEmpty {
                messages[chaplainIndex].text = "I'm here with you. Could you share a little more?"
            }

            if let conversationID {
                let title = messages.first(where: { $0.role == .user })?.text
                ChaplainSessionStore.shared.recordActiveConversation(
                    id: conversationID,
                    title: title,
                    preview: messages[chaplainIndex].text
                )
            }

            await ConversationRepository.shared.refresh()
        } catch {
            errorMessage = error.localizedDescription
            if messages[chaplainIndex].text.isEmpty {
                messages.remove(at: chaplainIndex)
                revealedMessageIDs.remove(chaplainMessage.id)
            }
        }

        isReplying = false
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
}

#Preview {
    ChaplainChatView(
        voice: ChaplainVoice.options[0],
        seedMessages: [],
        starterText: ""
    )
    .environment(\.authManager, AuthManager.shared)
}
