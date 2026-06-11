//
//  CircleChallengeComponents.swift
//  DevotionLock
//
//  Mobbin: Headway 5-day challenge, Strava create challenge, Duolingo garden card.
//

import SwiftUI

// MARK: - Active challenge card

struct CircleChallengeCard: View {
    @Environment(\.sanctuaryPalette) private var palette

    let challenge: CircleChallenge
    let reflectionCount: Int
    var onAddReflection: () -> Void
    var onViewArchive: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(challenge.isActive ? "This week's challenge" : "Challenge ended")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                Spacer()
                if challenge.isActive {
                    Text("\(challenge.daysRemaining) day\(challenge.daysRemaining == 1 ? "" : "s") left")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }

            Text(challenge.title)
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)

            if let verse = challenge.verseReference {
                Text(verse)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
            }

            Text(challenge.prompt)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)

            HStack(spacing: 8) {
                Label("\(reflectionCount) reflection\(reflectionCount == 1 ? "" : "s")", systemImage: "text.quote")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)

                Spacer()

                if challenge.isActive {
                    Button(action: onAddReflection) {
                        Text("Add reflection")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ABY.Color.pillTeal)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else if let onViewArchive {
                    Button(action: onViewArchive) {
                        Text("Wisdom scroll")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(ABY.Color.pillTeal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [ABY.Color.pillTeal.opacity(0.08), palette.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(ABY.Color.pillTeal.opacity(0.25), lineWidth: 1)
        }
    }
}

// MARK: - Start challenge sheet (Strava create)

struct CircleChallengeStartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    let circleName: String
    var onStart: (CircleChallengeTemplate) -> Void

    @State private var selectedTemplate: CircleChallengeTemplate?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start a challenge")
                            .font(ABY.Font.title2)
                            .foregroundStyle(palette.textPrimary)
                        Text("A 7-day reflection for \(circleName). One active challenge at a time.")
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textSecondary)
                            .lineSpacing(4)
                    }

                    ForEach(CircleChallengeTemplate.curated) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: template.kind == .gratitude ? "heart.fill" : "book.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(ABY.Color.pillTeal)
                                    .frame(width: 36, height: 36)
                                    .background(ABY.Color.pillTeal.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.title)
                                        .font(ABY.Font.headline)
                                        .foregroundStyle(palette.textPrimary)
                                    if let verse = template.verseReference {
                                        Text(verse)
                                            .font(ABY.Font.caption)
                                            .foregroundStyle(ABY.Color.pillPurple)
                                    }
                                    Text(template.prompt)
                                        .font(ABY.Font.caption)
                                        .foregroundStyle(palette.textSecondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                if selectedTemplate?.id == template.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ABY.Color.pillTeal)
                                }
                            }
                            .padding(14)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                            .overlay {
                                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                                    .stroke(
                                        selectedTemplate?.id == template.id ? ABY.Color.pillTeal : palette.divider,
                                        lineWidth: selectedTemplate?.id == template.id ? 2 : 1
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(ABY.Spacing.screen)
            }
            .background(ABYCleanGradientBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        guard let template = selectedTemplate else { return }
                        onStart(template)
                        dismiss()
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Reflection compose (Fable share)

struct CircleReflectionComposeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    let challenge: CircleChallenge
    var onSubmit: (String, CircleShareVisibility) -> Void

    @State private var text = ""
    @State private var visibility: CircleShareVisibility = .named

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(challenge.prompt)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)

                TextField("Share one line that landed…", text: $text, axis: .vertical)
                    .lineLimit(4...8)
                    .font(ABY.Font.body)
                    .padding(14)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))

                Picker("Visibility", selection: $visibility) {
                    ForEach(CircleShareVisibility.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()
            }
            .padding(ABY.Spacing.screen)
            .background(ABYCleanGradientBackground())
            .navigationTitle("Add reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSubmit(trimmed, visibility)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Archive / wisdom scroll

struct CircleChallengeArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    let challenge: CircleChallenge
    let reflections: [CirclePost]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your circle's wisdom scroll")
                            .font(ABY.Font.title2)
                            .foregroundStyle(palette.textPrimary)
                        Text(challenge.title)
                            .font(ABY.Font.headline)
                            .foregroundStyle(ABY.Color.pillTeal)
                        if let verse = challenge.verseReference {
                            Text(verse)
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }

                    if reflections.isEmpty {
                        Text("No reflections were shared for this challenge.")
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textTertiary)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(reflections) { reflection in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(reflection.displayAuthor)
                                    .font(ABY.Font.captionMedium)
                                    .foregroundStyle(palette.textSecondary)
                                Text(reflection.text)
                                    .font(.system(size: 17, weight: .regular, design: .serif))
                                    .foregroundStyle(palette.textPrimary)
                                    .lineSpacing(5)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                        }
                    }
                }
                .padding(ABY.Spacing.screen)
            }
            .background(ABYCleanGradientBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
