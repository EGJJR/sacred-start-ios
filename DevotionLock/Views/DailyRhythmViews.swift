//
//  DailyRhythmViews.swift
//  DevotionLock
//

import SwiftUI

struct DailyStoryRingsRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    var rhythmStore: DailyRhythmStore
    var onRing: (DailyRhythmRing) -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's rhythm")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(DailyRhythmRing.allCases.enumerated()), id: \.element.id) { index, ring in
                        StoryRingButton(
                            ring: ring,
                            isComplete: rhythmStore.isComplete(ring),
                            appeared: appeared,
                            delay: Double(index) * 0.06
                        ) {
                            onRing(ring)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }
}

private struct StoryRingButton: View {
    @Environment(\.sanctuaryPalette) private var palette
    let ring: DailyRhythmRing
    let isComplete: Bool
    let appeared: Bool
    let delay: Double
    let action: () -> Void

    private var ringColor: Color {
        isComplete ? ABY.Color.accentDot : Color(
            red: Double((ring.accentHex >> 16) & 0xFF) / 255,
            green: Double((ring.accentHex >> 8) & 0xFF) / 255,
            blue: Double(ring.accentHex & 0xFF) / 255
        )
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(isComplete ? ringColor : palette.track, lineWidth: isComplete ? 3 : 2)
                        .frame(width: 64, height: 64)

                    if isComplete {
                        Circle()
                            .trim(from: 0, to: 1)
                            .stroke(
                                AngularGradient(
                                    colors: [ringColor, ringColor.opacity(0.5), ringColor],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 64, height: 64)
                    }

                    Circle()
                        .fill(isComplete ? ringColor.opacity(0.14) : palette.surface)
                        .frame(width: 52, height: 52)

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ringColor)
                    } else {
                        Image(systemName: ring.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(ringColor.opacity(0.85))
                    }
                }

                Text(ring.shortLabel)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(isComplete ? palette.textPrimary : palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.88)
        .animation(AppTheme.springGentle.delay(delay), value: appeared)
    }
}

struct DailyVerseSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let passage: SpiritualPassage
    var onReflect: () -> Void
    var onComplete: () -> Void

    @State private var revealed = false

    var body: some View {
        NavigationStack {
            ZStack {
                SanctuarySplashBackground()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 16) {
                        Text(passage.source.label.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ABY.Color.pillPurple)
                            .tracking(1.2)

                        Text("“")
                            .font(.system(size: 48, weight: .light, design: .serif))
                            .foregroundStyle(ABY.Color.pillPurple.opacity(0.35))

                        Text(passage.text)
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.textPrimary)
                            .lineSpacing(6)
                            .opacity(revealed ? 1 : 0)
                            .offset(y: revealed ? 0 : 12)

                        Text(passage.attribution)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(ABY.Color.pillPurple)
                            .opacity(revealed ? 1 : 0)
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    VStack(spacing: 10) {
                        ABYPrimaryButton(title: "Reflect with Chaplain", icon: "sparkles") {
                            onComplete()
                            onReflect()
                            dismiss()
                        }
                        Button("Mark as read") {
                            onComplete()
                            dismiss()
                        }
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Daily passage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.15)) { revealed = true }
        }
    }
}

struct EveningReflectionSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    var onComplete: (String) -> Void
    var onVoiceHandoff: ((String) -> Void)? = nil

    @State private var highlight = ""
    @State private var appeared = false
    @State private var selectedPrompt: String?
    @State private var showVoiceCapture = false
    @FocusState private var editorFocused: Bool

    private let prompts = [
        "A moment of peace",
        "Unexpected grace",
        "Someone who helped me",
        "What I learned today",
        "What I'd like to release",
    ]

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var canSave: Bool {
        !highlight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.09, blue: 0.18),
                        Color(red: 0.14, green: 0.12, blue: 0.24),
                        Color(red: 0.08, green: 0.10, blue: 0.16),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        promptSection
                        responseSection
                        inputModeRow
                    }
                    .padding(ABY.Spacing.screen)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack {
                    Spacer()
                    saveBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showVoiceCapture) {
            RecordingSessionView(
                isPresented: $showVoiceCapture,
                initialPrompt: "What brought you peace or gratitude today?",
                onComplete: { transcript in
                    let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !spoken.isEmpty { highlight = spoken }
                },
                onSwitchToChat: { transcript in
                    showVoiceCapture = false
                    let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !spoken.isEmpty { highlight = spoken }
                    onVoiceHandoff?(spoken)
                },
                saveOnlyLabel: "Use in reflection only"
            )
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.65))
                Text(dateLabel)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Text("Close the day")
                .font(ABY.Font.onboardingTitle)
                .foregroundStyle(.white)

            Text("Name one grace before you rest — or speak it aloud.")
                .font(ABY.Font.callout)
                .foregroundStyle(Color.white.opacity(0.72))
                .lineSpacing(4)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("START WITH")
                .font(ABY.Font.section)
                .foregroundStyle(Color.white.opacity(0.45))
                .tracking(0.8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        selectedPrompt = prompt
                        if highlight.isEmpty {
                            highlight = "\(prompt): "
                        }
                        editorFocused = true
                    } label: {
                        Text(prompt)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(selectedPrompt == prompt ? .white : Color.white.opacity(0.78))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(selectedPrompt == prompt ? Color.white.opacity(0.16) : Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(selectedPrompt == prompt ? 0.22 : 0.10), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR REFLECTION")
                .font(ABY.Font.section)
                .foregroundStyle(Color.white.opacity(0.45))
                .tracking(0.8)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(editorFocused ? 0.22 : 0.12), lineWidth: 1)
                    }

                if highlight.isEmpty {
                    Text("A quiet moment, a kindness, a small mercy…")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .padding(18)
                }

                TextEditor(text: $highlight)
                    .focused($editorFocused)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.95))
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .frame(minHeight: 150)
            }
        }
    }

    private var inputModeRow: some View {
        HStack(spacing: 10) {
            Button {
                editorFocused = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                    Text("Type")
                }
                .font(ABY.Font.captionMedium)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                editorFocused = false
                showVoiceCapture = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                    Text("Speak")
                }
                .font(ABY.Font.captionMedium)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.clear, Color(red: 0.10, green: 0.09, blue: 0.18).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            Button(action: save) {
                Text(canSave ? "Save to your journey" : "Skip for tonight")
                    .font(ABY.Font.button)
                    .foregroundStyle(Color(red: 0.12, green: 0.10, blue: 0.22))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(canSave ? 0.95 : 0.55))
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 24)
            .background(Color(red: 0.10, green: 0.09, blue: 0.18))
        }
    }

    private func save() {
        let trimmed = highlight.trimmingCharacters(in: .whitespacesAndNewlines)
        onComplete(trimmed.isEmpty ? "Quiet gratitude for today." : trimmed)
        DevotionHaptics.success()
        dismiss()
    }
}

struct JourneyTimelinePreviewSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    var store: JourneyTimelineStore
    var onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your journey")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.5)
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
            }

            if store.todayEntries.isEmpty {
                Text("Your mood, verses, and prayers will gather here through the day.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .padding(ABY.Spacing.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
            } else {
                VStack(spacing: 10) {
                    ForEach(store.todayEntries.prefix(3)) { entry in
                        JourneyTimelineRow(entry: entry, compact: true)
                    }
                }
            }
        }
    }
}
