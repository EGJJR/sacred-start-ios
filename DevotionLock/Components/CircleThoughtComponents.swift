//
//  CircleThoughtComponents.swift
//  DevotionLock
//
//  Mobbin refs:
//  - ABY Journal mad-libs: https://mobbin.com/screens/fba2b5b0-119d-4022-9ef1-0727ee8e5cf2
//  - Zesty post composer prompts: https://mobbin.com/screens/6682ca8a-d593-4a12-a4d4-6702e011ef21
//

import SwiftUI

// MARK: - Empty feed prompt card

struct CircleEmptyFeedPrompt: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onAddThought: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Start the conversation")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text("Pick a prompt below or share what's on your heart. Your circle is here to pray with you.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CircleThoughtTemplate.starters.prefix(3)) { template in
                        CircleThoughtStarterChip(template: template, compact: true) {
                            onAddThought()
                        }
                    }
                }
            }

            Button(action: onAddThought) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(ABY.Font.calloutSemibold)
                    Text("Add your first thought")
                        .font(ABY.Font.captionMedium)
                }
                .foregroundStyle(ABY.Color.pillPurple)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(ABY.Color.pillPurple.opacity(0.10))
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                .stroke(ABY.Color.pillPurple.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct CircleThoughtStarterChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let template: CircleThoughtTemplate
    var compact: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: template.kind.icon)
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(template.kind.tint)
                    Text(template.title)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textPrimary)
                }
                if !compact {
                    Text(template.prompt)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, compact ? 10 : 12)
            .background(palette.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thought composer

struct CircleThoughtComposeSheet: View {
    let circle: PrayerCircle
    var circleStore: PrayerCircleStore
    var initialTemplate: CircleThoughtTemplate?

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    @State private var selectedKind: CirclePostKind = .request
    @State private var selectedFocus: FocusTag?
    @State private var text = ""
    @State private var visibility: CircleShareVisibility = .named
    @FocusState private var focused: Bool

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var activePrompt: String {
        CircleThoughtTemplate.starters.first { $0.kind == selectedKind }?.prompt
            ?? "Share a thought with your circle…"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    promptHeader

                    kindPicker

                    focusChips

                    templateRow

                    madLibPreview

                    textEditor

                    visibilityPicker
                }
                .padding(ABY.Spacing.screen)
                .padding(.bottom, 24)
            }
            .background(palette.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ABYPrimaryButton(title: "Share with circle", icon: "paperplane.fill") {
                    postThought()
                }
                .opacity(trimmedText.isEmpty ? 0.45 : 1)
                .disabled(trimmedText.isEmpty)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background {
                    SanctuaryGradientBottomFade()
                }
            }
            .navigationTitle("Add a thought")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let initialTemplate {
                    applyTemplate(initialTemplate)
                }
                focused = true
            }
        }
        .abyScreen()
        .presentationDetents([.large])
        .presentationBackground(palette.background)
    }

    private var promptHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(activePrompt)
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Your private journal stays yours. Only what you share here appears in the circle.")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
        }
    }

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you sharing?")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)

            HStack(spacing: 8) {
                ForEach([CirclePostKind.request, .reminder, .testimony], id: \.rawValue) { kind in
                    Button {
                        withAnimation(AppTheme.springSnappy) { selectedKind = kind }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: kind.icon)
                                .font(ABY.Font.captionSemibold)
                            Text(kind.label)
                                .font(ABY.Font.captionMedium)
                        }
                        .foregroundStyle(selectedKind == kind ? .white : kind.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedKind == kind ? kind.tint : kind.tint.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var focusChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus area")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FocusTag.allCases) { tag in
                        Button {
                            withAnimation(AppTheme.springSnappy) {
                                selectedFocus = selectedFocus == tag ? nil : tag
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: tag.icon)
                                    .font(ABY.Font.emojiSmall)
                                Text(tag.label)
                                    .font(ABY.Font.captionMedium)
                            }
                            .foregroundStyle(selectedFocus == tag ? .white : palette.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedFocus == tag ? ABY.Color.pillPurple : palette.surfaceMuted)
                            .clipShape(Capsule())
                            .overlay {
                                if selectedFocus != tag {
                                    Capsule().stroke(palette.divider, lineWidth: 1)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var templateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick starters")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CircleThoughtTemplate.starters.filter { $0.kind == selectedKind || selectedKind == .request && $0.id == "gratitude" }) { template in
                        CircleThoughtStarterChip(template: template) {
                            applyTemplate(template)
                            DevotionHaptics.light()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var madLibPreview: some View {
        if let template = CircleThoughtTemplate.starters.first(where: { matchesTemplate($0) }),
           template.madLibPrefix != nil || template.madLibSuffix != nil {
            HStack(spacing: 0) {
                if let prefix = template.madLibPrefix {
                    Text(prefix)
                        .foregroundStyle(palette.textTertiary)
                }
                Text(trimmedText.isEmpty ? "…" : trimmedText)
                    .foregroundStyle(palette.textPrimary)
                    .fontWeight(.medium)
                if let suffix = template.madLibSuffix {
                    Text(suffix)
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .font(ABY.Font.callout)
            .lineSpacing(4)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ABY.Color.pillPurple.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
        }
    }

    private var textEditor: some View {
        TextEditor(text: $text)
            .font(ABY.Font.body)
            .foregroundStyle(palette.textPrimary)
            .frame(minHeight: 100)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(palette.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.card)
                    .stroke(palette.divider, lineWidth: 1)
            }
            .focused($focused)
            .overlay(alignment: .topLeading) {
                if trimmedText.isEmpty {
                    Text("Type here…")
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
    }

    private var visibilityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visibility")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)
            Picker("Visibility", selection: $visibility) {
                ForEach(CircleShareVisibility.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func applyTemplate(_ template: CircleThoughtTemplate) {
        selectedKind = template.kind
        if let prefix = template.madLibPrefix {
            text = prefix
        } else {
            text = ""
        }
        focused = true
        if template.id == "request-family" {
            selectedFocus = .family
        } else if template.id == "gratitude" {
            selectedFocus = .faith
        }
    }

    private func matchesTemplate(_ template: CircleThoughtTemplate) -> Bool {
        guard let prefix = template.madLibPrefix else { return false }
        return text.hasPrefix(prefix)
    }

    private func postThought() {
        guard let me = circleStore.currentMember else { return }
        guard !trimmedText.isEmpty else { return }

        circleStore.addPost(CirclePost(
            id: UUID(),
            circleId: circle.id,
            authorId: me.id,
            authorName: me.displayName,
            isAnonymous: visibility == .anonymous,
            kind: selectedKind,
            text: composedText,
            createdAt: Date(),
            focusTag: selectedFocus?.rawValue,
            sourceNoteId: nil,
            verseReference: nil,
            prayingMemberIds: [],
            encouragements: []
        ))
        DevotionHaptics.success()
        dismiss()
    }

    private var composedText: String {
        guard let template = CircleThoughtTemplate.starters.first(where: { matchesTemplate($0) }),
              let suffix = template.madLibSuffix,
              let prefix = template.madLibPrefix,
              text.hasPrefix(prefix) else {
            return trimmedText
        }
        let middle = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !middle.isEmpty else { return trimmedText }
        return "\(prefix)\(middle)\(suffix)"
    }
}

// MARK: - Circle settings & lifecycle

struct CircleSettingsSheet: View {
    let circle: PrayerCircle
    var circleStore: PrayerCircleStore
    var isCreator: Bool
    var onInvite: () -> Void
    var onMembers: () -> Void
    var onLeave: () -> Void
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        settingsRow(icon: "person.2.fill", title: "Members", subtitle: "\(circleStore.members(for: circle).count) praying together") {
                            dismiss()
                            onMembers()
                        }
                        divider
                        settingsRow(icon: "person.badge.plus", title: "Invite someone", subtitle: "Share code \(circle.inviteCode)") {
                            dismiss()
                            onInvite()
                        }
                    }
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.divider, lineWidth: 1)
                    }

                    VStack(spacing: 0) {
                        if isCreator {
                            destructiveRow(
                                icon: "trash",
                                title: "Delete circle",
                                subtitle: "Removes the circle and all shared posts for everyone"
                            ) {
                                dismiss()
                                onDelete()
                            }
                        } else {
                            destructiveRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Leave circle",
                                subtitle: "Your private journal stays yours"
                            ) {
                                dismiss()
                                onLeave()
                            }
                        }
                    }
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.divider, lineWidth: 1)
                    }
                }
                .padding(ABY.Spacing.screen)
            }
            .background(palette.background)
            .navigationTitle("Circle settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(palette.background)
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.divider)
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func settingsRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(ABY.Color.pillPurple)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func destructiveRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(.red.opacity(0.9))
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

struct CircleLifecycleConfirmSheet: View {
    enum Action: Equatable {
        case leave
        case delete
    }

    let circleName: String
    let action: Action
    var isProcessing: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(title)
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                Button {
                    onConfirm()
                } label: {
                    Text(confirmLabel)
                        .font(ABY.Font.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.88))
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.6 : 1)

                Button("Cancel", action: onCancel)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .disabled(isProcessing)
            }
        }
        .padding(ABY.Spacing.screen)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var title: String {
        switch action {
        case .leave: "Leave \(circleName)?"
        case .delete: "Delete \(circleName)?"
        }
    }

    private var message: String {
        switch action {
        case .leave:
            "You'll no longer see posts from this circle. Your private journal and prayer wall stay exactly as they are, and you can rejoin anytime with the invite code."
        case .delete:
            "This permanently removes the circle for all members. Shared posts and encouragements will be gone, but each person's private journal is untouched."
        }
    }

    private var confirmLabel: String {
        if isProcessing {
            return "One moment…"
        }
        switch action {
        case .leave: return "Leave circle"
        case .delete: return "Delete circle"
        }
    }
}
