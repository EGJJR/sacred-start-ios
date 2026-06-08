//
//  PrayerWallView.swift
//  DevotionLock
//

import SwiftUI

struct ChaplainPrayerWallSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Bindable var store: PrayerWallStore
    var circleStore: PrayerCircleStore = .shared
    var suggestion: String? = nil
    var onOpen: () -> Void

    @State private var floatPhase = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Prayer wall")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.5)
                Text("Requests, reminders, praise & circles")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            if hasStats {
                HStack(spacing: 8) {
                    if !circleStore.circles.isEmpty {
                        wallStat(count: circleStore.circles.count, icon: "person.3.fill", tint: ABY.Color.pillTeal)
                    }
                    if store.notes.isEmpty == false {
                        wallStat(count: store.requestCount, icon: "hands.sparkles.fill", tint: ABY.Color.pillPurple)
                        wallStat(count: store.answeredCount, icon: "checkmark.seal.fill", tint: ABY.Color.orbSage)
                    }
                    Spacer(minLength: 0)
                }
            }

            if let suggestion {
                Text(suggestion)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(palette.surface.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card, style: .continuous))
            }

            Button(action: onOpen) {
                VStack(spacing: 0) {
                    if store.previewNotes.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(ABY.Color.pillPurple.opacity(0.7))
                            Text("Pin your first prayer")
                                .font(ABY.Font.callout)
                                .foregroundStyle(palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    } else {
                        ZStack {
                            ForEach(Array(store.previewNotes.prefix(3).enumerated()), id: \.element.id) { index, note in
                                miniNote(note, index: index)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 148)
                        .padding(.top, 18)
                        .padding(.bottom, 4)
                    }

                    HStack(spacing: 6) {
                        Text("Open wall")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textPrimary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(palette.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(palette.surfaceElevated.opacity(0.88))
                    .clipShape(Capsule())
                    .padding(.top, store.previewNotes.isEmpty ? 0 : 4)
                    .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .fill(previewCardFill)
                        .overlay {
                            if !palette.isNight {
                                PrayerWallTexture()
                                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                            }
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                }
                .shadow(color: .black.opacity(palette.isNight ? 0.28 : 0.04), radius: 10, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                floatPhase = true
            }
        }
    }

    private var hasStats: Bool {
        !circleStore.circles.isEmpty || !store.notes.isEmpty
    }

    private var previewCardFill: AnyShapeStyle {
        if palette.isNight {
            AnyShapeStyle(
                LinearGradient(
                    colors: [palette.surfaceElevated, palette.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.90),
                        Color(red: 0.94, green: 0.96, blue: 0.98),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private func miniNote(_ note: PrayerWallNote, index: Int) -> some View {
        let offsets: [(x: CGFloat, y: CGFloat)] = [(-48, 4), (0, -10), (48, 6)]
        let offset = offsets[index % offsets.count]
        let bob = floatPhase ? CGFloat(index + 1) * 1.5 : CGFloat(-index) * 1.2

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: note.kind.icon)
                    .font(.system(size: 9, weight: .semibold))
                Text(note.kind.shortLabel)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(note.kind.tint)

            Text(note.text)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(PrayerWallNote.inkColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(width: 124, alignment: .leading)
        .background(note.paperColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(note.kind.tint.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .rotationEffect(.degrees(note.rotation * 1.2))
        .offset(x: offset.x, y: offset.y + bob)
        .zIndex(Double(3 - index))
    }

    private func wallStat(count: Int, icon: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text("\(count)")
                .font(ABY.Font.captionMedium)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct PrayerWallView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Bindable var store: PrayerWallStore
    var onReflect: (String) -> Void
    var initialAddKind: PrayerNoteKind? = nil
    var initialTab: PrayerWallTab = .myWall
    var initialJoinCode: String? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var circleStore = PrayerCircleStore.shared
    @State private var wallTab: PrayerWallTab = .myWall
    @State private var filter: PrayerWallFilter = .all
    @State private var showAddMenu = false
    @State private var addKind: PrayerNoteKind?
    @State private var selectedNote: PrayerWallNote?
    @State private var shareNote: PrayerWallNote?
    @State private var testimonyNote: PrayerWallNote?
    @State private var selectedCircle: PrayerCircle?
    @State private var showJoinFromLink = false
    @State private var appeared = false
    @State private var celebratingID: UUID?
    @State private var newNoteID: UUID?

    private var filteredNotes: [PrayerWallNote] {
        store.filtered(by: filter)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ABYCleanGradientBackground()

                VStack(spacing: 0) {
                    PrayerWallSegmentedControl(selection: $wallTab)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 4)
                        .padding(.bottom, 16)

                    if wallTab == .myWall {
                        myWallContent
                    } else {
                        SanctuaryCirclesHomeView(circleStore: circleStore) { circle in
                            selectedCircle = circle
                        }
                    }
                }

                if wallTab == .myWall {
                    addButton
                        .padding(.bottom, 24)

                    if celebratingID != nil {
                        PrayerConfettiView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Prayer wall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(ABY.Font.callout)
                }
            }
            .navigationDestination(item: $selectedCircle) { circle in
                CircleDiscussionView(circle: circle, circleStore: circleStore)
            }
        }
        .abyScreen()
        .sheet(item: $addKind) { kind in
            PrayerWallComposeSheet(kind: kind) { text in
                let note = store.add(kind: kind, text: text)
                newNoteID = note.id
                DevotionHaptics.light()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    newNoteID = nil
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(item: $selectedNote) { note in
            PrayerWallDetailSheet(
                note: note,
                onMarkAnswered: {
                    celebratingID = note.id
                    store.markAnswered(note.id)
                    DevotionHaptics.success()
                    selectedNote = nil
                    testimonyNote = store.notes.first { $0.id == note.id } ?? note
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        celebratingID = nil
                    }
                },
                onShare: {
                    let noteToShare = note
                    selectedNote = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        shareNote = noteToShare
                    }
                },
                onDelete: {
                    store.delete(note.id)
                    selectedNote = nil
                },
                onReflect: {
                    let prompt = note.chatPrompt
                    selectedNote = nil
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onReflect(prompt)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(item: $shareNote) { note in
            ShareToCircleSheet(note: note, circleStore: circleStore) {
                wallTab = .circles
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $testimonyNote) { note in
            ShareTestimonySheet(
                note: note,
                circleStore: circleStore,
                verseReference: SharedQuoteProvider.today.reference,
                onShared: { wallTab = .circles },
                onSkip: { testimonyNote = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showJoinFromLink) {
            JoinCircleSheet(circleStore: circleStore) { circle in
                wallTab = .circles
                selectedCircle = circle
            }
        }
        .onAppear {
            wallTab = initialTab
            withAnimation(AppTheme.springGentle.delay(0.05)) { appeared = true }
            if let initialAddKind {
                addKind = initialAddKind
            }
            if let code = initialJoinCode, !code.isEmpty {
                wallTab = .circles
                Task {
                    if let circle = await circleStore.joinCircleRemote(code: code) {
                        selectedCircle = circle
                    } else {
                        showJoinFromLink = true
                    }
                }
            }
        }
    }

    private var myWallContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                filterBar
                    .padding(.horizontal, ABY.Spacing.screen)

                if filteredNotes.isEmpty {
                    emptyState
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 40)
                } else {
                    PrayerWallMasonryGrid(
                        notes: filteredNotes,
                        appeared: appeared,
                        celebratingID: celebratingID,
                        newNoteID: newNoteID
                    ) { note in
                        selectedNote = note
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 120)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PrayerWallFilter.allCases) { item in
                    Button {
                        withAnimation(AppTheme.springSnappy) { filter = item }
                    } label: {
                        HStack(spacing: 5) {
                            if item != .all {
                                Image(systemName: item.kind?.icon ?? "")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            Text(item.label)
                                .font(ABY.Font.captionMedium)
                        }
                        .foregroundStyle(filter == item ? filterForeground(for: item) : palette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            if filter == item {
                                Capsule().fill(filterFill(for: item))
                            } else {
                                Capsule().fill(palette.surface)
                            }
                        }
                        .overlay {
                            Capsule().stroke(filter == item ? Color.clear : palette.divider, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func filterFill(for item: PrayerWallFilter) -> Color {
        if let tint = item.kind?.tint { return tint }
        return palette.isNight ? palette.buttonFill : palette.textPrimary
    }

    private func filterForeground(for item: PrayerWallFilter) -> Color {
        if item.kind != nil { return .white }
        return palette.isNight ? palette.buttonForeground : .white
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(PrayerWallNote.paperVariants[index])
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(Double(index - 1) * 8))
                        .offset(x: CGFloat(index - 1) * 28, y: CGFloat(index) * 4)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                }
            }
            .frame(height: 110)

            Text("Your wall is waiting")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Pin a prayer request, a reminder to yourself,\nor celebrate something God has done.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var addButton: some View {
        ZStack(alignment: .bottom) {
            if showAddMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(AppTheme.springSnappy) { showAddMenu = false }
                    }

                VStack(spacing: 12) {
                    addMenuOption(kind: .request, label: "Prayer request", icon: "hands.sparkles.fill")
                    addMenuOption(kind: .reminder, label: "Reminder to self", icon: "bell.fill")
                    addMenuOption(kind: .answered, label: "Answered prayer", icon: "checkmark.seal.fill")
                }
                .padding(.bottom, 72)
                .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(AppTheme.springSnappy) { showAddMenu.toggle() }
                DevotionHaptics.light()
            } label: {
                Image(systemName: showAddMenu ? "xmark" : "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background {
                        Circle().fill(
                            LinearGradient(
                                colors: [ABY.Color.pillPurple, ABY.Color.pillTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .shadow(color: ABY.Color.pillPurple.opacity(0.35), radius: 16, y: 6)
                    .rotationEffect(.degrees(showAddMenu ? 90 : 0))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func addMenuOption(kind: PrayerNoteKind, label: String, icon: String) -> some View {
        Button {
            withAnimation(AppTheme.springSnappy) { showAddMenu = false }
            addKind = kind
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(kind.tint)
                    .frame(width: 32, height: 32)
                    .background(kind.tint.opacity(0.14))
                    .clipShape(Circle())
                Text(label)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(palette.surface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct PrayerWallMasonryGrid: View {
    @Environment(\.sanctuaryPalette) private var palette
    let notes: [PrayerWallNote]
    var appeared: Bool
    var celebratingID: UUID?
    var newNoteID: UUID?
    var onSelect: (PrayerWallNote) -> Void

    private var leftColumn: [PrayerWallNote] {
        notes.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element)
    }

    private var rightColumn: [PrayerWallNote] {
        notes.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            LazyVStack(spacing: 16) {
                ForEach(Array(leftColumn.enumerated()), id: \.element.id) { index, note in
                    noteCard(note, staggerIndex: index * 2)
                }
            }
            LazyVStack(spacing: 16) {
                ForEach(Array(rightColumn.enumerated()), id: \.element.id) { index, note in
                    noteCard(note, staggerIndex: index * 2 + 1)
                }
            }
        }
    }

    @ViewBuilder
    private func noteCard(_ note: PrayerWallNote, staggerIndex: Int) -> some View {
        PrayerWallNoteCard(
            note: note,
            isCelebrating: celebratingID == note.id,
            isNew: newNoteID == note.id
        ) {
            onSelect(note)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(AppTheme.springGentle.delay(Double(staggerIndex) * 0.06), value: appeared)
    }
}

struct PrayerWallNoteCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let note: PrayerWallNote
    var isCelebrating: Bool
    var isNew: Bool
    var onTap: () -> Void

    @State private var floating = false
    @State private var glow = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                PrayerWallPin()
                    .offset(y: -6)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 5) {
                    Image(systemName: note.kind.icon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(note.kind.shortLabel)
                        .font(ABY.Font.captionMedium)
                    Spacer()
                    Text(note.relativeDate)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }
                .foregroundStyle(note.kind.tint)
                .padding(.bottom, 10)

                Text(note.text)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(PrayerWallNote.inkColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if note.kind == .answered, let answeredAt = note.answeredAt {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Answered \(answeredAt.formatted(.relative(presentation: .named)))")
                            .font(ABY.Font.caption)
                    }
                    .foregroundStyle(ABY.Color.orbSage)
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 16)
            .background(note.paperColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(note.kind.tint.opacity(note.kind == .answered ? 0.35 : 0.12), lineWidth: note.kind == .answered ? 1.5 : 1)
            }
            .overlay {
                if isCelebrating || glow {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ABY.Color.accentDot.opacity(glow ? 0.8 : 0), lineWidth: 2)
                        .shadow(color: ABY.Color.accentDot.opacity(glow ? 0.5 : 0), radius: 12)
                }
            }
            .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
            .rotationEffect(.degrees(note.rotation))
            .scaleEffect(isNew ? 1.04 : 1)
            .offset(y: floating ? -2.5 : 2.5)
        }
        .buttonStyle(.plain)
        .overlay {
            if isCelebrating {
                PrayerWallSparkleBurst()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8 + Double(abs(note.rotation))).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
        .onChange(of: isCelebrating) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                    glow = true
                }
            }
        }
        .onChange(of: isNew) { _, active in
            if active {
                withAnimation(AppTheme.springSnappy) {}
            }
        }
    }
}

struct PrayerWallPin: View {
    @Environment(\.sanctuaryPalette) private var palette
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.95, green: 0.35, blue: 0.32), Color(red: 0.72, green: 0.18, blue: 0.20)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 14
                    )
                )
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            Circle()
                .fill(.white.opacity(0.35))
                .frame(width: 5, height: 5)
                .offset(x: -2, y: -2)
        }
    }
}

struct PrayerWallTexture: View {
    @Environment(\.sanctuaryPalette) private var palette
    var body: some View {
        Canvas { context, size in
            for row in stride(from: 0, to: size.height, by: 18) {
                for col in stride(from: 0, to: size.width, by: 18) {
                    let rect = CGRect(x: col, y: row, width: 1, height: 1)
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.025)))
                }
            }
        }
    }
}

struct PrayerWallSparkleBurst: View {
    @Environment(\.sanctuaryPalette) private var palette
    @State private var burst = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ABY.Color.accentDot)
                    .offset(
                        x: burst ? cos(Double(index) / 8 * .pi * 2) * 52 : 0,
                        y: burst ? sin(Double(index) / 8 * .pi * 2) * 52 : 0
                    )
                    .opacity(burst ? 0 : 1)
                    .scaleEffect(burst ? 1.4 : 0.3)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { burst = true }
        }
    }
}

struct PrayerWallComposeSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    let kind: PrayerNoteKind
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var text = ""

    private var placeholder: String {
        switch kind {
        case .request: "Who or what are you bringing before God?"
        case .reminder: "What truth do you want to remember?"
        case .answered: "What has God done? Write it down."
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: kind.icon)
                        .foregroundStyle(kind.tint)
                    Text(kind.shortLabel)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                }

                TextEditor(text: $text)
                    .font(.system(size: 17, design: .serif))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 140)
                    .background(kind.paperColor)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                    .overlay {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.system(size: 17, design: .serif))
                                .foregroundStyle(palette.textTertiary)
                                .padding(16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                    .focused($focused)

                ABYPrimaryButton(title: "Pin to wall", icon: "pin.fill") {
                    guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return }
                    onSave(text)
                    dismiss()
                }
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(ABY.Spacing.screen)
            .background(ABYCleanGradientBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { focused = true }
    }
}

struct PrayerWallDetailSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    let note: PrayerWallNote
    var onMarkAnswered: () -> Void
    var onShare: () -> Void
    var onDelete: () -> Void
    var onReflect: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Label(note.kind.shortLabel, systemImage: note.kind.icon)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(note.kind.tint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(note.kind.tint.opacity(0.12))
                            .clipShape(Capsule())
                        Spacer()
                        Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textTertiary)
                    }

                    Text(note.text)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(note.paperColor)
                        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                        .rotationEffect(.degrees(note.rotation * 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                    VStack(spacing: 12) {
                        if note.kind == .request {
                            ABYPrimaryButton(title: "Mark as answered", icon: "checkmark.seal.fill", action: onMarkAnswered)
                        }
                        ABYPrimaryButton(title: "Share to circle", icon: "person.3.fill", action: onShare)
                        ABYPrimaryButton(title: "Reflect with Chaplain", icon: "ellipsis.bubble", action: onReflect)
                        Button("Remove from wall", role: .destructive) {
                            showDeleteConfirm = true
                        }
                        .font(ABY.Font.callout)
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
            .confirmationDialog("Remove this note?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Remove", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}


#Preview("Wall") {
    PrayerWallView(store: .shared, onReflect: { _ in })
}

#Preview("Section") {
    ChaplainPrayerWallSection(store: .shared, onOpen: {})
        .padding()
}
