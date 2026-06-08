//
//  ConversationDetailView.swift
//  test1
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

    var body: some View {
        ZStack {
            ABYBackground()

            VStack(spacing: 0) {
                detailHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        JournalDetailHero(conversation: displayConversation)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(displayConversation.title)
                                .font(ABY.Font.title2)
                                .foregroundStyle(palette.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("\(displayConversation.transcript.count) messages · \(displayConversation.tag)")
                                .font(ABY.Font.caption)
                                .foregroundStyle(palette.textTertiary)
                        }
                        .opacity(appeared ? 1 : 0)

                        transcriptSection
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 40)
                }
            }
        }
        .abyScreen()
        .task(id: conversation.id) {
            if conversation.transcript.isEmpty, conversation.remoteID != nil {
                loadedConversation = await ConversationRepository.shared.loadTranscript(for: conversation.id)
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var detailHeader: some View {
        HStack {
            ABYIconButton(icon: "chevron.down") { dismiss() }
            Spacer()
            Text("Entry")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textSecondary)
            Spacer()
            ABYIconButton(icon: "square.and.arrow.up") {}
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ABYSectionHeader(title: "Conversation")

            ForEach(Array(displayConversation.transcript.enumerated()), id: \.element.id) { index, segment in
                JournalTranscriptRow(segment: segment)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(
                        AppTheme.springGentle.delay(0.06 + Double(index) * 0.04),
                        value: appeared
                    )
            }
        }
    }
}

#Preview {
    ConversationDetailView(conversation: Conversation.samples[0])
}
