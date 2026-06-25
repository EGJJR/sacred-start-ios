//
//  JournalRhythmSteps.swift
//  DevotionLock
//

import SwiftUI
import UIKit

struct FocusTagsStepView: View {
    @Binding var selectedTags: [String]
    var appeared: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ABYHeadline(
                title: "What's in focus today?",
                subtitle: "Your Chaplain and prayer wall will lean into what matters most."
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(Array(FocusTag.allCases.enumerated()), id: \.element.id) { index, tag in
                    FocusTagChip(
                        tag: tag,
                        isSelected: selectedTags.contains(tag.rawValue)
                    ) {
                        withAnimation(AppTheme.springSnappy) {
                            toggle(tag)
                        }
                    }
                    .animation(AppTheme.springGentle.delay(0.04 + Double(index) * 0.03), value: appeared)
                }
            }
        }
        .padding(.top, 8)
    }

    private func toggle(_ tag: FocusTag) {
        if selectedTags.contains(tag.rawValue) {
            selectedTags.removeAll { $0 == tag.rawValue }
        } else if selectedTags.count < 3 {
            selectedTags.append(tag.rawValue)
        }
    }
}

private struct FocusTagChip: View {
    let tag: FocusTag
    let isSelected: Bool
    let action: () -> Void

    private var accent: Color { ABY.Color.pillTeal }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tag.icon)
                    .font(ABY.Font.iconSmall)
                Text(tag.label)
                    .font(ABY.Font.calloutMedium)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ABY.Font.callout)
                }
            }
            .foregroundStyle(isSelected ? ABY.Color.textPrimary : accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white : accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        accent.opacity(isSelected ? 0.85 : 0.55),
                        style: isSelected ? StrokeStyle(lineWidth: 1.5) : StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GratitudeStepView: View {
    @Binding var items: [String]
    var appeared: Bool

    private let prompts = [
        "Someone who showed up for you",
        "A small mercy you noticed",
        "Something your body can do",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ABYHeadline(
                title: "Three gratitudes",
                subtitle: "Name at least two — small things count."
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("Knowing this, I'm grateful for:")
                    .font(ABY.Font.body)
                    .foregroundStyle(ABY.Color.textPrimary)

                ForEach(0..<3, id: \.self) { index in
                    HStack(alignment: .center, spacing: 10) {
                        Text("\(index + 1).")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(ABY.Color.pillOrange)
                            .frame(width: 18, alignment: .trailing)

                        TextField(prompts[index], text: binding(for: index))
                            .font(ABY.Font.bodyMedium)
                            .foregroundStyle(ABY.Color.pillOrange)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(ABY.Color.pillOrange.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        ABY.Color.pillOrange.opacity(0.45),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                                    )
                            }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(AppTheme.springGentle.delay(0.05 + Double(index) * 0.05), value: appeared)
                }
            }
        }
        .padding(.top, 8)
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { items.indices.contains(index) ? items[index] : "" },
            set: { newValue in
                while items.count <= index { items.append("") }
                items[index] = newValue
            }
        )
    }
}

struct AffirmationStepView: View {
    @Binding var affirmation: String
    var appeared: Bool

    private let suggestions = [
        "Today I will move gently",
        "Today I will receive rest",
        "Today I will speak with kindness",
        "Today I will trust the next step",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ABYHeadline(
                title: "Today I will…",
                subtitle: "One intention to carry through the day."
            )

            TextField("Today I will…", text: $affirmation)
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(ABY.Color.textPrimary)
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            ABY.Color.pillPurple.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                }
                .shadow(color: .black.opacity(0.04), radius: 10, y: 3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            affirmation = suggestion
                        } label: {
                            Text(suggestion)
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(ABY.Color.pillPurple)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(ABY.Color.pillPurple.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(ABY.Color.pillPurple.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }
}

struct BlackoutVerseView: View {
    let verse: String
    let reference: String
    @Binding var savedPhrase: String

    @State private var selectedIndices: Set<Int> = []

    private var words: [String] {
        verse.split(separator: " ").map(String.init)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tap the words that speak to you")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)

            FlowWordLayout(words: words, selectedIndices: $selectedIndices) { indices in
                updateSavedPhrase(indices: indices)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ABY.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))

            Text(reference)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(ABY.Color.textSecondary)

            if !savedPhrase.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your phrase")
                        .font(ABY.Font.section)
                        .foregroundStyle(ABY.Color.textSecondary)
                    Text("“\(savedPhrase)”")
                        .font(ABY.Font.editorialBody)
                        .foregroundStyle(ABY.Color.pillPurple)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ABY.Color.pillPurple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private func updateSavedPhrase(indices: Set<Int>) {
        let phrase = indices.sorted().compactMap { index in
            words.indices.contains(index) ? words[index] : nil
        }.joined(separator: " ")
        withAnimation(AppTheme.springSnappy) {
            savedPhrase = phrase
        }
    }
}

private struct FlowWordLayout: View {
    let words: [String]
    @Binding var selectedIndices: Set<Int>
    var onChange: (Set<Int>) -> Void

    var body: some View {
        WrappingHStack(spacing: 6, lineSpacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                let selected = selectedIndices.contains(index)
                Button {
                    if selected {
                        selectedIndices.remove(index)
                    } else {
                        selectedIndices.insert(index)
                    }
                    onChange(selectedIndices)
                } label: {
                    Text(word)
                        .font(ABY.Font.editorialBody)
                        .foregroundStyle(selected ? ABY.Color.textPrimary : ABY.Color.textTertiary.opacity(0.55))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(selected ? ABY.Color.pillPurple.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WrappingHStack<Content: View>: View {
    var spacing: CGFloat
    var lineSpacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        _WrappingLayout(spacing: spacing, lineSpacing: lineSpacing) {
            content()
        }
    }
}

private struct _WrappingLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

/// Prompt-led free write from the Chaplain hub — same surface as Guided Entry.
struct WisdomReflectionView: View {
    let prompt: String
    var onSave: (String) -> Void
    var onExpandWithAI: ((String) -> Void)?

    @State private var text = ""

    private static let alternatePrompts = [
        "What is God inviting you to notice today?",
        "Where did you sense grace in an ordinary moment?",
        "What truth do you need to carry into the rest of today?",
        "What feels unfinished — and what might God be saying through it?",
        "What would it look like to receive today without striving?",
    ]

    var body: some View {
        GuidedJournalEntryView(
            navigationTitle: "Guided Entry",
            seedPrompt: prompt,
            text: $text,
            alternatePrompts: Self.alternatePrompts,
            starterPhrases: [
                "I'm noticing…",
                "God seems to be…",
                "I want to remember…",
            ],
            onExpandWithAI: onExpandWithAI,
            onSave: onSave
        )
    }
}

struct PrayerConfettiView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                Circle()
                    .fill([ABY.Color.pillPurple, ABY.Color.pillTeal, ABY.Color.pillOrange, ABY.Color.orbSage][index % 4])
                    .frame(width: 6, height: 6)
                    .offset(
                        x: animate ? CGFloat.random(in: -120...120) : 0,
                        y: animate ? CGFloat.random(in: -160...40) : -10
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.2).delay(Double(index) * 0.03),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

struct FocusTagPromptCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let prompt: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                    .frame(width: 36, height: 36)
                    .background(ABY.Color.pillTeal.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's focus")
                        .font(ABY.Font.section)
                        .foregroundStyle(palette.textSecondary)
                    Text(prompt)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct WisdomReflectionEntryCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
                    .frame(width: 44, height: 44)
                    .background(ABY.Color.pillPurple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reflection")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("One prompt · write freely · optional Chaplain handoff")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
