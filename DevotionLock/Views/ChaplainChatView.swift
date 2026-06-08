//
//  ChaplainChatView.swift
//  DevotionLock
//

import SwiftUI

struct ChaplainMessage: Identifiable, Equatable {
    enum Role { case user, chaplain }

    let id: UUID
    var role: Role
    var text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

struct ChaplainChatView: View {
    static let defaultGreeting = "What's on your heart right now? You can write freely — no perfect words needed."

    @Environment(\.sanctuaryPalette) private var palette
    @Binding var isPresented: Bool
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
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            ABYBackground()

            VStack(spacing: 0) {
                chatHeader
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(messages) { message in
                                ChaplainChatBubble(message: message)
                                    .id(message.id)
                            }
                            if isReplying {
                                ChaplainTypingIndicator()
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
                        .padding(.bottom, 16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation(AppTheme.springGentle) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: messages.last?.text) { _, _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                ChaplainMessageBar(
                    text: $draft,
                    onSend: sendDraft,
                    onVoice: onVoice
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)
                .disabled(isReplying)
            }
        }
        .abyScreen()
        .onAppear(perform: beginSession)
        .task(id: resumeConversationID) {
            await hydrateResumeConversationIfNeeded()
        }
    }

    private static func initialMessages(from seeds: [ChaplainMessage]) -> [ChaplainMessage] {
        if seeds.isEmpty {
            return [ChaplainMessage(role: .chaplain, text: defaultGreeting)]
        }
        return seeds
    }

    private func beginSession() {
        errorMessage = nil
        isReplying = false
        draft = ""

        if resumeConversationID == nil {
            conversationID = nil
            messages = Self.initialMessages(from: seedMessages)
        } else if messages.isEmpty {
            messages = Self.initialMessages(from: seedMessages)
        }

        if !starterText.isEmpty {
            draft = starterText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                sendDraft()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                inputFocused = true
            }
        }
    }

    @MainActor
    private func hydrateResumeConversationIfNeeded() async {
        guard let resumeConversationID else { return }

        let conversation = await ConversationRepository.shared.loadTranscript(for: resumeConversationID)
            ?? ConversationRepository.shared.conversation(for: resumeConversationID)

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
    }

    private func clearChat() {
        guard !isReplying else { return }
        messages = [ChaplainMessage(role: .chaplain, text: Self.defaultGreeting)]
        conversationID = nil
        draft = ""
        errorMessage = nil
        inputFocused = true
    }

    private var chatHeader: some View {
        HStack {
            ABYIconButton(icon: "xmark") {
                isPresented = false
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Chaplain \(voice.name)")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text("AI spiritual companion · not a licensed counselor")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ABYIconButton(icon: "square.and.arrow.down") { saveChat() }
                    .disabled(messages.count < 2 || isReplying)
                    .opacity(messages.count < 2 || isReplying ? 0.4 : 1)
                ABYIconButton(icon: "trash") { clearChat() }
                    .disabled(isReplying)
                    .opacity(isReplying ? 0.4 : 1)
                if let onVoice {
                    ABYIconButton(icon: "waveform", action: onVoice)
                }
            }
        }
    }

    private func sendDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isReplying else { return }

        draft = ""
        inputFocused = false
        errorMessage = nil
        messages.append(ChaplainMessage(role: .user, text: trimmed))
        isReplying = true

        Task {
            await streamChaplainReply()
        }
    }

    @MainActor
    private func streamChaplainReply() async {
        let apiMessages = messages
        let chaplainIndex = messages.count
        messages.append(ChaplainMessage(role: .chaplain, text: ""))

        do {
            let context = ChaplainContextBuilder.build(intent: contextIntent)
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
            }
        }

        isReplying = false
    }

    private func saveChat() {
        guard let entry = JournalLocalStore.shared.saveChaplainChat(
            messages: messages,
            conversationID: conversationID
        ) else { return }
        savedBanner = "Saved to Journal · \(entry.title)"
        DevotionHaptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            savedBanner = nil
        }
    }
}

#Preview {
    ChaplainChatView(
        isPresented: .constant(true),
        voice: ChaplainVoice.options[0],
        seedMessages: [
            ChaplainMessage(role: .chaplain, text: "What's on your heart this morning?")
        ],
        starterText: ""
    )
}
