//
//  ConversationDetailView.swift
//  DevotionLock
//
//  Mobbin refs: Pi chat read (aa1c3adb), pillowtalk transcript (67acccfc), ABY read-only (bd815cf1)
//

import SwiftUI

struct ConversationDetailView: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var loadedConversation: Conversation?

    private var displayConversation: Conversation {
        loadedConversation ?? conversation
    }

    private var isSimpleReflection: Bool {
        let transcript = displayConversation.transcript
        return transcript.count <= 1 && transcript.allSatisfy { $0.speaker == "You" }
    }

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()

            VStack(spacing: 0) {
                detailHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        entryHeader
                            .blurReveal(appeared, blurRadius: 6, scale: 1.004)

                        if isSimpleReflection {
                            simpleReflectionBody
                                .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                        } else {
                            transcriptThread
                        }
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .abyScrollEdgeFades(top: false)
            }
        }
        .abyScreen()
        .task(id: conversation.id) {
            if conversation.transcript.isEmpty, conversation.remoteID != nil {
                loadedConversation = await ConversationRepository.shared.loadTranscript(for: conversation.id)
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.04)) { appeared = true }
        }
    }

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

            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayConversation.title)
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(entryDateLabel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)

                if !displayConversation.moodLabel.isEmpty {
                    Text("·")
                        .foregroundStyle(palette.textTertiary)
                    Text("\(displayConversation.moodEmoji) \(displayConversation.moodLabel)")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var simpleReflectionBody: some View {
        let text = displayConversation.transcript.first?.text ?? displayConversation.preview
        Text(text)
            .font(ABY.Font.editorialBody)
            .foregroundStyle(palette.textPrimary)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transcriptThread: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(displayConversation.transcript.enumerated()), id: \.element.id) { index, segment in
                ABYEntryMessageView(segment: segment)
                    .blurRevealOnAppear(index: index, stagger: 0.04, delay: 0.03)
            }
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
}

#Preview {
    ConversationDetailView(conversation: Conversation.samples[0])
}
