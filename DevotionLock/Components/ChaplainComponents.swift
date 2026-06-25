//
//  ChaplainComponents.swift
//  DevotionLock
//

import SwiftUI

enum ChaplainStarterPrompt: String, CaseIterable, Identifiable {
    case peace = "I need peace"
    case pray = "Help me pray"
    case bibleQuestion = "I have a Bible question"
    case bibleVerse = "What does this verse mean?"
    case biblePeace = "Find a verse about peace"
    case distracted = "I'm feeling distracted"
    case alone = "I feel alone today"
    case gratitude = "What am I grateful for?"
    case scripture = "Help me understand Scripture"
    case weighing = "What's weighing on me"

    var id: String { rawValue }

    struct GeminiChip: Identifiable {
        let id = UUID()
        let emoji: String
        let prompt: String
    }

    static var hubSuggestions: [String] {
        [Self.peace, Self.pray, Self.bibleQuestion, Self.gratitude, Self.scripture].map(\.rawValue)
    }

    static var chatSuggestions: [String] {
        [Self.peace, Self.pray, Self.bibleQuestion].map(\.rawValue)
    }

    static var geminiChips: [GeminiChip] {
        [
            GeminiChip(emoji: "📖", prompt: Self.bibleQuestion.rawValue),
            GeminiChip(emoji: "🙏", prompt: Self.pray.rawValue),
            GeminiChip(emoji: "🕊️", prompt: Self.peace.rawValue),
        ]
    }
}

struct ChaplainHeroCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let voice: ChaplainVoice
    var streak: Int
    var onTalk: () -> Void
    var onWrite: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Chaplain \(voice.name)")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                Text(voice.personality)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                if streak > 0 {
                    Text("\(streak) day streak · here when you're ready")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, 24)

            VoiceOrb(state: .idle, size: 152)
                .padding(.bottom, 28)

            Button(action: onTalk) {
                HStack(spacing: 8) {
                    Text("Talk with Chaplain")
                        .font(ABY.Font.button)
                    Image(systemName: "waveform")
                        .font(ABY.Font.iconSmall)
                }
                .foregroundStyle(palette.buttonForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(palette.buttonFill)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            if let onWrite {
                Button(action: onWrite) {
                    Text("or write instead")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, ABY.Spacing.card)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .fill(palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: palette.isNight
                                    ? [ABY.Color.nightMeshIndigo.opacity(0.35), palette.surface]
                                    : [ABY.Color.moodPeach.opacity(0.35), palette.surface],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.isNight ? 0.28 : 0.04), radius: 12, y: 4)
    }
}

struct ChaplainPromptChips: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onSelect: (String) -> Void
    var appeared: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Or write about…")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)
                .tracking(0.5)

            FlowLayoutChips(spacing: 8) {
                ForEach(Array(ChaplainStarterPrompt.allCases.enumerated()), id: \.element.id) { index, starter in
                    Button {
                        onSelect(starter.rawValue)
                    } label: {
                        Text(starter.rawValue)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(palette.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(AppTheme.springGentle.delay(0.12 + Double(index) * 0.06), value: appeared)
                }
            }
        }
    }
}

/// ABY-style exchange: user bubble + chaplain prose in warm gold.
struct ChaplainRecentExchange: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    var onOpen: () -> Void

    private var userLine: String? {
        conversation.transcript.first { $0.speaker == "You" }?.text
    }

    private var chaplainLine: String? {
        conversation.transcript.first { $0.speaker == "Chaplain" }?.text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's devotion")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.5)
                Spacer()
                Text(conversation.timelineTime)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            if let userLine {
                Text(userLine)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ABY.Color.moodPeach.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            }

            if let chaplainLine {
                Text(chaplainLine)
                    .font(ABY.Font.body)
                    .foregroundStyle(ABY.Color.moodPeachText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onOpen) {
                HStack(spacing: 6) {
                    Text("Continue conversation")
                        .font(ABY.Font.captionMedium)
                    Image(systemName: "arrow.right")
                        .font(ABY.Font.iconSmall)
                }
                .foregroundStyle(palette.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(ABY.Spacing.card)
        .background(palette.surface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

struct ChaplainReflectionTeaser: View {
    @Environment(\.sanctuaryPalette) private var palette
    let insight: AIInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: insight.icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(palette.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(insight.title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
            }
            Text(insight.body)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .abyCard()
    }
}

/// Wrapping horizontal chip layout.
struct FlowLayoutChips: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

struct ChaplainMessageBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder: String = "Say something to your Chaplain…"
    var onSend: () -> Void
    var onVoice: (() -> Void)?
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if FeatureFlags.voiceChatEnabled, let onVoice {
            voiceEnabledBar(onVoice: onVoice)
        } else {
            ABYChatComposerBar(
                text: $text,
                placeholder: placeholder,
                onSend: onSend,
                enablesDictation: true
            )
        }
    }

    private func voiceEnabledBar(onVoice: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Button(action: onVoice) {
                Image(systemName: "mic")
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(palette.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)

            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(1...4)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit { if canSend { onSend() } }

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(canSend ? palette.buttonForeground : palette.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(canSend ? palette.buttonFill : palette.surfaceMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge).stroke(palette.divider, lineWidth: 1))
        .shadow(color: .black.opacity(palette.isNight ? 0.22 : 0.06), radius: 12, y: 4)
    }
}

struct ChaplainChatBubble: View {
    let message: ChaplainMessage
    var timestamp: String? = nil
    var useSerifStyle: Bool = false
    var isRevealed: Bool = true
    var isStreaming: Bool = false

    var body: some View {
        switch message.role {
        case .user:
            ABYUserMessageBubble(text: message.text)
                .blurReveal(isRevealed, blurRadius: 6, scale: 1.004)
        case .chaplain:
            ABYChaplainMessageCard(
                text: message.displayText,
                timestamp: timestamp,
                useSerifStyle: useSerifStyle,
                isRevealed: isRevealed,
                isStreaming: isStreaming
            )
        }
    }
}

// MARK: - Chat presence (thinking, scripture lookup, thread load)

enum ChaplainPresenceMode: Equatable {
    case thinking
    case searchingScripture(String)
    case loadingThread
}

struct ChaplainPresenceIndicator: View {
    @Environment(\.sanctuaryPalette) private var palette
    let mode: ChaplainPresenceMode

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ChaplainPresenceAvatar()

            VStack(alignment: .leading, spacing: 8) {
                switch mode {
                case .thinking:
                    thinkingCard
                case .searchingScripture(let label):
                    scriptureCard(label)
                case .loadingThread:
                    threadSkeleton
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch mode {
        case .thinking: "Chaplain is reflecting"
        case .searchingScripture(let label): label
        case .loadingThread: "Loading conversation"
        }
    }

    private var thinkingCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ChaplainThinkingDots()
            Text("Reflecting…")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(presenceCardBackground)
    }

    private func scriptureCard(_ label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "text.book.closed")
                .font(ABY.Font.footnoteMedium)
                .foregroundStyle(ABY.Color.pillTeal)
                .symbolEffect(.pulse, options: .repeating)

            Text(label)
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(presenceCardBackground)
    }

    private var threadSkeleton: some View {
        VStack(alignment: .leading, spacing: 8) {
            ChaplainSkeletonLine(widthRatio: 0.92)
            ChaplainSkeletonLine(widthRatio: 0.74)
            ChaplainSkeletonLine(widthRatio: 0.56)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(presenceCardBackground)
    }

    private var presenceCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(palette.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
    }
}

/// Legacy name — use `ChaplainPresenceIndicator`.
struct ChaplainTypingIndicator: View {
    var body: some View {
        ChaplainPresenceIndicator(mode: .thinking)
    }
}

private struct ChaplainPresenceAvatar: View {
    @State private var breathe = false

    var body: some View {
        ABYChaplainAvatar(size: 28)
            .padding(.top, 2)
            .scaleEffect(breathe ? 1.04 : 0.96)
            .opacity(breathe ? 1 : 0.88)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    breathe = true
                }
            }
    }
}

private struct ChaplainThinkingDots: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.34, paused: false)) { context in
            let phase = Int(context.date.timeIntervalSinceReferenceDate / 0.34) % 3
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(palette.textTertiary.opacity(phase == index ? 0.9 : 0.28))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == index ? 1.08 : 0.92)
                }
            }
        }
    }
}

private struct ChaplainSkeletonLine: View {
    @Environment(\.sanctuaryPalette) private var palette
    var widthRatio: CGFloat

    @State private var shimmer = false

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(palette.surfaceMuted.opacity(0.65))
                .frame(width: geo.size.width * widthRatio, height: 10)
                .overlay {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    palette.surface.opacity(0.85),
                                    Color.clear,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmer ? geo.size.width * 0.35 : -geo.size.width * 0.35)
                }
                .clipShape(Capsule())
        }
        .frame(height: 10)
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                shimmer = true
            }
        }
    }
}

struct ChaplainStreamCursor: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.55, paused: false)) { context in
            let visible = Int(context.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(ABY.Color.pillPurple.opacity(visible ? 0.75 : 0.2))
                .frame(width: 2, height: 15)
                .padding(.leading, 1)
        }
        .accessibilityHidden(true)
    }
}
