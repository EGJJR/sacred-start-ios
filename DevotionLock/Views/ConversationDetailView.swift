//
//  ConversationDetailView.swift
//  DevotionLock
//
//  Mobbin refs: Pi chat read (aa1c3adb), pillowtalk transcript (67acccfc), ChatGPT history (679d2bbe)
//

import SwiftUI

struct ConversationDetailView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.resumeChaplainChat) private var resumeChaplainChat
    @Environment(\.openChaplainChat) private var openChaplainChat
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var loadedConversation: Conversation?
    @State private var showEditSheet = false
    @State private var updatedBanner: String?

    private var displayConversation: Conversation {
        loadedConversation ?? conversation
    }

    private var isEditable: Bool {
        displayConversation.isEditableJournalEntry
    }

    private var prefersChatStyle: Bool {
        displayConversation.prefersChatStyleDetail
    }

    private var isChaplainThread: Bool {
        ConversationMerger.isChaplainChat(displayConversation)
    }

    var body: some View {
        ZStack {
            if prefersChatStyle {
                ABYFlatTabWashBackground()
            } else {
                ABYCleanGradientBackground()
            }

            VStack(spacing: 0) {
                detailHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: prefersChatStyle ? 14 : 20) {
                        if let updatedBanner {
                        Text(updatedBanner)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(ABY.Color.pillTeal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                    }

                    if prefersChatStyle {
                            compactChatHeader
                                .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                            chatThread
                        } else if isSimpleJournalReflection {
                            JournalEntryReadCard(
                                conversation: displayConversation,
                                onEdit: isEditable ? { openEditSheet() } : nil
                            )
                                .blurReveal(appeared, blurRadius: 6, scale: 1.004)
                        } else {
                            journalHeader
                                .blurReveal(appeared, blurRadius: 6, scale: 1.004)
                            journalBody
                                .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                        }
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, prefersChatStyle ? 100 : 56)
                }
                .abyScrollEdgeFades(top: false)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isChaplainThread {
                continueChaplainCTA
            } else if displayConversation.isThinCapture {
                exploreWithChaplainCTA
            }
        }
        .abyScreen()
        .task(id: conversation.id) {
            if displayConversation.transcript.isEmpty,
               displayConversation.remoteID != nil || isChaplainThread {
                loadedConversation = await ConversationRepository.shared.loadTranscript(for: conversation.id)
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.04)) { appeared = true }
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            EditJournalEntryView(conversation: displayConversation) { updated in
                loadedConversation = updated
                withAnimation(AppTheme.springGentle) {
                    updatedBanner = "Entry updated"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(AppTheme.springGentle) {
                        updatedBanner = nil
                    }
                }
            }
        }
    }

    // MARK: - Chrome

    private var detailHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if isChaplainThread {
                Text("Chaplain")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textTertiary)
            }

            if isEditable {
                Button(action: openEditSheet) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil.line")
                            .font(ABY.Font.captionMedium)
                        Text("Edit")
                            .font(ABY.Font.captionSemibold)
                    }
                    .foregroundStyle(ABY.Color.pillPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(ABY.Color.pillPurple.opacity(palette.isNight ? 0.16 : 0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit entry")
            }
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var isSimpleJournalReflection: Bool {
        let segments = displayConversation.transcript
        return segments.isEmpty
            || (segments.count <= 1 && segments.allSatisfy { $0.speaker == "You" })
    }

    // MARK: - Chat presentation (Pi / Wysa / ChatGPT)

    private var compactChatHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayConversation.detailDisplayTitle)
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(entryDateLabel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)

                if let mood = displayConversation.timelineMoodLabel.nilIfEmpty {
                    Text("·")
                        .foregroundStyle(palette.textTertiary)
                    Text("\(displayConversation.moodEmoji) \(mood)")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chatThread: some View {
        VStack(alignment: .leading, spacing: 12) {
            if displayConversation.transcript.isEmpty {
                ABYEntryMessageView(
                    segment: TranscriptSegment(
                        speaker: "You",
                        text: displayConversation.primaryUserText,
                        timestamp: "0:00"
                    )
                )
            } else {
                ForEach(Array(displayConversation.transcript.enumerated()), id: \.element.id) { index, segment in
                    ABYEntryMessageView(segment: segment)
                        .blurRevealOnAppear(index: index, stagger: 0.04, delay: 0.03)
                }
            }
        }
    }

    // MARK: - Journal presentation (ABY read-only)

    private var journalHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayConversation.title)
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(entryDateLabel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)

                if let mood = displayConversation.timelineMoodLabel.nilIfEmpty {
                    Text("·")
                        .foregroundStyle(palette.textTertiary)
                    Text("\(displayConversation.moodEmoji) \(mood)")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var journalBody: some View {
        let segments = displayConversation.transcript
        if segments.count <= 1, segments.allSatisfy({ $0.speaker == "You" }) {
            Text(segments.first?.text ?? displayConversation.preview)
                .font(ABY.Font.editorialBody)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    ABYEntryMessageView(segment: segment)
                        .blurRevealOnAppear(index: index, stagger: 0.04, delay: 0.03)
                }
            }
        }
    }

    // MARK: - CTAs

    private var continueChaplainCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.clear, ABY.Color.sanctuaryGradientBottom.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .allowsHitTesting(false)

            Button(action: continueChaplainConversation) {
                HStack(spacing: 8) {
                    Image(systemName: "ellipsis.bubble.fill")
                        .font(ABY.Font.calloutMedium)
                    Text("Continue with Chaplain")
                        .font(ABY.Font.calloutSemibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ABY.Color.pillPurple)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 12)
            .background(Color.white.opacity(0.92))
        }
    }

    private var exploreWithChaplainCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.clear, ABY.Color.sanctuaryGradientBottom.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)
            .allowsHitTesting(false)

            Button(action: exploreWithChaplain) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(ABY.Font.calloutMedium)
                    Text("Explore with Chaplain")
                        .font(ABY.Font.calloutSemibold)
                }
                .foregroundStyle(ABY.Color.pillPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ABY.Color.pillPurple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ABY.Color.pillPurple.opacity(0.2), lineWidth: 1)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 12)
            .background(Color.white.opacity(0.9))
        }
    }

    private var entryDateLabel: String {
        if let recordedAt = displayConversation.recordedAt {
            let day = recordedAt.formatted(date: .abbreviated, time: .omitted)
            let time = displayConversation.timelineTime
            return "\(day) · \(time)"
        }
        return "\(displayConversation.timelineTime) · \(displayConversation.timeAgo)"
    }

    private func openEditSheet() {
        showEditSheet = true
        DevotionHaptics.light()
    }

    private func continueChaplainConversation() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            resumeChaplainChat(displayConversation)
        }
    }

    private func exploreWithChaplain() {
        let seed = displayConversation.primaryUserText
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            openChaplainChat(
                "I'd like to go deeper on this: \"\(seed)\"",
                [ChaplainMessage(role: .user, text: seed)]
            )
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    ConversationDetailView(conversation: Conversation.samples[0])
}
