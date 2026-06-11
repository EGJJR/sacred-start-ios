//
//  PrayerCircleViews.swift
//  DevotionLock
//

import SwiftUI

// MARK: - Circles home (list)

struct SanctuaryCirclesHomeView: View {
    @Environment(\.sanctuaryPalette) private var palette
    var circleStore: PrayerCircleStore
    var onSelectCircle: (PrayerCircle) -> Void

    @State private var showCreate = false
    @State private var showJoin = false
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    circlesHeader

                    if circleStore.circles.isEmpty {
                        emptyCircles
                    } else {
                        VStack(spacing: 12) {
                            ForEach(circleStore.circles) { circle in
                                CircleFeedRow(
                                    circle: circle,
                                    members: circleStore.members(for: circle),
                                    latestPost: circleStore.posts(for: circle.id).sorted { $0.createdAt > $1.createdAt }.first,
                                    hasNewMilestone: CircleMilestoneStore.shared.hasUncelebratedMilestones(
                                        circleId: circle.id,
                                        stats: circleStore.collectiveStats(for: circle.id)
                                    )
                                ) {
                                    onSelectCircle(circle)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }

            if !circleStore.circles.isEmpty {
                Button {
                    showCreate = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Create")
                            .font(ABY.Font.captionMedium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(ABY.Color.pillPurple)
                    .clipShape(Capsule())
                    .shadow(color: ABY.Color.pillPurple.opacity(0.25), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, ABY.Spacing.screen)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
            Task { await circleStore.refreshFromRemote() }
        }
        .sheet(isPresented: $showCreate) {
            CreateCircleSheet(circleStore: circleStore) { circle in
                onSelectCircle(circle)
            }
        }
        .sheet(isPresented: $showJoin) {
            JoinCircleSheet(circleStore: circleStore) { circle in
                onSelectCircle(circle)
            }
        }
    }

    private var circlesHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Prayer circles")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(prayingTogetherLabel)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer(minLength: 12)
                Button("Join") { showJoin = true }
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ABY.Color.pillPurple.opacity(0.10))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                actionPill(title: "Create circle", icon: "plus.circle.fill", filled: true) {
                    showCreate = true
                }
                actionPill(title: "Invite code", icon: "qrcode", filled: false) {
                    showJoin = true
                }
            }
        }
        .padding(ABY.Spacing.card)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                .stroke(palette.divider, lineWidth: 1)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    private func actionPill(title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(ABY.Font.captionMedium)
            }
            .foregroundStyle(filled ? .white : ABY.Color.pillPurple)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(filled ? ABY.Color.pillPurple : ABY.Color.pillPurple.opacity(0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var prayingTogetherLabel: String {
        let count = circleStore.circles.reduce(0) { $0 + circleStore.members(for: $1).count }
        if count <= 1 {
            return "Create a circle or join with an invite code."
        }
        return "\(count) people praying together"
    }

    private var emptyCircles: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(ABY.Color.pillPurple.opacity(0.55))
            Text("No circles yet")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Start one for family or friends, or join an existing circle with a code.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            Button("Create your first circle") { showCreate = true }
                .font(ABY.Font.captionMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(ABY.Color.pillPurple)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 12)
        .background(palette.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
    }
}

private struct CircleFeedRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let circle: PrayerCircle
    let members: [CircleMember]
    let latestPost: CirclePost?
    var hasNewMilestone: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(colors: circle.coverColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 54, height: 54)
                        .overlay {
                            CircleMemberAvatarStack(members: members, size: 22, maxVisible: 3)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(circle.name)
                                .font(ABY.Font.headline)
                                .foregroundStyle(palette.textPrimary)
                            if hasNewMilestone {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ABY.Color.pillOrange)
                            }
                        }
                        Text("\(members.count) members")
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(ABY.Font.iconSmall)
                        .foregroundStyle(palette.textTertiary)
                }

                if let latestPost {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: latestPost.kind.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(latestPost.authorName)
                                .font(ABY.Font.captionMedium)
                        }
                        .foregroundStyle(palette.textSecondary)

                        Text(latestPost.text)
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.background.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
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

private struct CircleListRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let circle: PrayerCircle
    let members: [CircleMember]
    let postCount: Int
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(colors: circle.coverColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                    .overlay {
                        CircleMemberAvatarStack(members: members, size: 22, maxVisible: 3)
                            .scaleEffect(0.95)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("\(members.count) members · \(postCount) posts")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
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

// MARK: - Circle discussion feed (Headspace-style)

struct CircleDiscussionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    let circle: PrayerCircle
    var circleStore: PrayerCircleStore
    var onShareFromWall: (() -> Void)?

    @State private var sort: CircleFeedSort = .newest
    @State private var showInvite = false
    @State private var showMembers = false
    @State private var showCompose = false
    @State private var showStartChallenge = false
    @State private var showReflectionCompose = false
    @State private var showChallengeArchive = false
    @State private var selectedPost: CirclePost?
    @State private var appeared = false
    @State private var pendingMilestone: CircleMilestonePresentation?

    private var activeChallenge: CircleChallenge? {
        circleStore.activeChallenge(for: circle.id)
    }

    private var endedChallenge: CircleChallenge? {
        circleStore.latestEndedChallenge(for: circle.id)
    }

    private var challengeReflections: [CirclePost] {
        guard let challenge = activeChallenge ?? endedChallenge else { return [] }
        return circleStore.reflections(for: challenge.id)
    }

    private var feedPosts: [CirclePost] {
        let all = circleStore.posts(for: circle.id, sort: sort)
        if activeChallenge != nil || endedChallenge != nil {
            return all.filter { $0.kind != .reflection }
        }
        return all
    }

    private var circleMembers: [CircleMember] {
        circleStore.members(for: circle)
    }

    private var collectiveStats: CircleCollectiveStats {
        circleStore.collectiveStats(for: circle.id)
    }

    private var momentContext: CircleMomentContext {
        CircleMomentContext(
            posts: feedPosts,
            members: circleMembers,
            currentMemberId: circleStore.currentMemberId,
            isPrayingOnAny: feedPosts.contains { circleStore.isPraying(postId: $0.id) },
            stats: collectiveStats,
            circleId: circle.id
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ABYCleanGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HeadspaceCircleHeader(
                        circle: circle,
                        members: circleStore.members(for: circle),
                        stats: collectiveStats,
                        onMembersTap: { showMembers = true },
                        onBack: { dismiss() },
                        onInvite: { showInvite = true }
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        if let challenge = activeChallenge {
                            CircleChallengeCard(
                                challenge: challenge,
                                reflectionCount: challengeReflections.count,
                                onAddReflection: { showReflectionCompose = true }
                            )
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.top, 8)
                        } else if let ended = endedChallenge, !challengeReflections.isEmpty {
                            CircleChallengeCard(
                                challenge: ended,
                                reflectionCount: challengeReflections.count,
                                onAddReflection: {},
                                onViewArchive: { showChallengeArchive = true }
                            )
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.top, 8)
                        }

                        sortMenu
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.top, 4)

                        if let moment = momentContext.banner {
                            CircleMomentBanner(moment: moment) {
                                handleMomentAction(moment)
                            }
                            .padding(.horizontal, ABY.Spacing.screen)
                        }

                        if !challengeReflections.isEmpty, activeChallenge != nil {
                            challengeReflectionsSection
                                .padding(.horizontal, ABY.Spacing.screen)
                        }

                        if feedPosts.isEmpty, challengeReflections.isEmpty {
                            emptyFeed
                                .padding(.horizontal, ABY.Spacing.screen)
                        } else if !feedPosts.isEmpty {
                            LazyVStack(spacing: 14) {
                                ForEach(Array(feedPosts.enumerated()), id: \.element.id) { index, post in
                                    CirclePostCard(
                                        post: post,
                                        authorHue: circleStore.member(for: post.authorId)?.avatarHue ?? 0.12,
                                        isCurrentUser: post.authorId == circleStore.currentMemberId,
                                        isPraying: circleStore.isPraying(postId: post.id)
                                    ) {
                                        let previous = collectiveStats
                                        circleStore.togglePraying(postId: post.id)
                                        DevotionHaptics.light()
                                        checkForNewMilestones(previous: previous)
                                    } onOpen: {
                                        selectedPost = post
                                    } onQuickEncourage: { text in
                                        circleStore.addEncouragement(postId: post.id, text: text)
                                        DevotionHaptics.success()
                                    }
                                    .padding(.horizontal, ABY.Spacing.screen)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 12)
                                    .animation(AppTheme.springGentle.delay(Double(index) * 0.04), value: appeared)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.bottom, 120)
                }
            }
            .scrollContentBackground(.hidden)

            bottomActionBar
        }
        .abyScreen()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $pendingMilestone) { presentation in
            CircleMilestoneCelebrationView(
                circleName: circle.name,
                milestone: presentation.kind
            ) {
                CircleMilestoneStore.shared.markCelebrated(presentation.kind, circleId: circle.id)
                pendingMilestone = nil
            }
        }
        .onAppear {
            circleStore.markFeedOpened()
            withAnimation(AppTheme.springGentle) { appeared = true }
            CircleRepository.shared.subscribeToCircle(circle.id, store: circleStore)
            presentUncelebratedMilestones()
        }
        .onDisappear {
            CircleRepository.shared.unsubscribeFromCircle(circle.id)
        }
        .sheet(isPresented: $showInvite) {
            CircleInviteSheet(circle: circle, circleStore: circleStore)
        }
        .sheet(isPresented: $showMembers) {
            CircleMembersSheet(
                circle: circle,
                members: circleMembers,
                canStartChallenge: activeChallenge == nil,
                onStartChallenge: {
                    showMembers = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showStartChallenge = true
                    }
                },
                onInvite: {
                    showMembers = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showInvite = true
                    }
                }
            )
        }
        .sheet(isPresented: $showStartChallenge) {
            CircleChallengeStartSheet(circleName: circle.name) { template in
                _ = circleStore.startChallenge(template: template, circleId: circle.id)
                DevotionHaptics.success()
            }
        }
        .sheet(isPresented: $showReflectionCompose) {
            if let challenge = activeChallenge {
                CircleReflectionComposeSheet(challenge: challenge) { text, visibility in
                    _ = circleStore.addReflection(
                        text: text,
                        challengeId: challenge.id,
                        circleId: circle.id,
                        visibility: visibility
                    )
                    DevotionHaptics.success()
                }
            }
        }
        .sheet(isPresented: $showChallengeArchive) {
            if let challenge = endedChallenge {
                CircleChallengeArchiveView(
                    challenge: challenge,
                    reflections: circleStore.reflections(for: challenge.id)
                )
            }
        }
        .sheet(isPresented: $showCompose) {
            CircleComposeSheet(circle: circle, circleStore: circleStore)
        }
        .sheet(item: $selectedPost) { post in
            CirclePostDetailSheet(post: post, circleStore: circleStore)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(CircleFeedSort.allCases) { option in
                Button(option.label) { sort = option }
            }
        } label: {
            HStack(spacing: 6) {
                Text(sort.label)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }

    private var emptyFeed: some View {
        VStack(spacing: 10) {
            Text("Your circle is quiet")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Share a prayer from your wall or add a thought for the group.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func handleMomentAction(_ moment: CircleMoment) {
        switch moment.actionLabel {
        case "See testimonies":
            sort = .testimonies
        case "Respond", "View posts":
            if let target = momentContext.suggestedPost {
                selectedPost = target
            }
        default:
            showCompose = true
        }
    }

    private func checkForNewMilestones(previous: CircleCollectiveStats) {
        let current = circleStore.collectiveStats(for: circle.id)
        let reached = CircleMilestoneStore.shared.newlyReached(
            circleId: circle.id,
            stats: current,
            previousStats: previous
        )
        if let first = reached.first {
            pendingMilestone = CircleMilestonePresentation(kind: first)
        }
    }

    private func presentUncelebratedMilestones() {
        let uncelebrated = CircleMilestoneStore.shared.uncelebratedReached(
            circleId: circle.id,
            stats: collectiveStats
        )
        if let first = uncelebrated.first, pendingMilestone == nil {
            pendingMilestone = CircleMilestonePresentation(kind: first)
        }
    }

    private var challengeReflectionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week's reflections")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)

            ForEach(challengeReflections.prefix(5)) { reflection in
                VStack(alignment: .leading, spacing: 6) {
                    Text(reflection.displayAuthor)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textTertiary)
                    Text(reflection.text)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(4)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            }
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            SanctuaryGradientBottomFade()
                .frame(height: 24)

            if circleStore.hasAcceptedGuidelines {
                Button {
                    if activeChallenge != nil {
                        showReflectionCompose = true
                    } else {
                        showCompose = true
                    }
                } label: {
                    Text(activeChallenge != nil ? "Add reflection" : "Add your thoughts")
                        .font(ABY.Font.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.22, green: 0.48, blue: 0.92), Color(red: 0.18, green: 0.42, blue: 0.86)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)
            } else {
                Button {
                    circleStore.hasAcceptedGuidelines = true
                    showCompose = true
                } label: {
                    Text("Accept guidelines to post")
                        .font(ABY.Font.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.22, green: 0.48, blue: 0.92))
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)
            }
        }
        .background(SanctuaryGradientBottomFade())
    }
}

private struct HeadspaceCircleHeader: View {
    let circle: PrayerCircle
    let members: [CircleMember]
    let stats: CircleCollectiveStats
    var onMembersTap: () -> Void
    var onBack: () -> Void
    var onInvite: () -> Void

    private let headerHeight: CGFloat = 220
    private let waveHeight: CGFloat = 22

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: circle.coverColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        LinearGradient(
                            colors: [Color.black.opacity(0.06), Color.black.opacity(0.32)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                VStack(spacing: 0) {
                    HStack {
                        circleHeaderButton(icon: "chevron.left", action: onBack)
                        Spacer()
                        circleHeaderButton(icon: "person.badge.plus", action: onInvite)
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        Text(circle.name)
                            .font(ABY.Font.title2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                            .multilineTextAlignment(.center)

                        Button(action: onMembersTap) {
                            VStack(spacing: 6) {
                                CircleMemberAvatarStack(members: members, size: 36, maxVisible: 5)

                                Text(memberSummary)
                                    .font(ABY.Font.captionMedium)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .buttonStyle(.plain)

                        if stats.prayersLifted > 0 || stats.testimoniesCelebrated > 0 {
                            CircleCollectiveStatsRow(stats: stats)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .frame(height: headerHeight)

            HeadspaceWaveDivider()
                .fill(ABY.Color.gradientTop)
                .frame(height: waveHeight)
        }
        .background {
            VStack(spacing: 0) {
                LinearGradient(colors: circle.coverColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: headerHeight)
                ABY.Color.gradientTop
                    .frame(height: waveHeight)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private func circleHeaderButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.16))
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var memberSummary: String {
        let count = members.count
        if count == 0 { return "Invite someone to join" }
        if count == 1 { return "1 member" }
        return "\(count) members"
    }
}

private struct HeadspaceWaveDivider: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.75, y: rect.maxY * 0.4)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

struct CirclePostCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let post: CirclePost
    var authorHue: Double = 0.12
    var isCurrentUser: Bool
    var isPraying: Bool
    var onPraying: () -> Void
    var onOpen: () -> Void
    var onQuickEncourage: ((String) -> Void)?

    private static let quickEncouragements = [
        "Praying for you 🙏",
        "Standing with you",
        "God hears you",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CircleAvatarView(name: post.displayAuthor, hue: authorHue, compact: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCurrentUser ? "\(post.displayAuthor) (You)" : post.displayAuthor)
                        .font(ABY.Font.callout.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                    if let focus = post.focusLabel {
                        Text(focus)
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textSecondary)
                    } else {
                        Text(post.kind.label)
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                Spacer()
                if post.kind == .testimony {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ABY.Color.orbSage)
                }
            }

            Text(post.text)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let reference = post.verseReference {
                Text(reference)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
            }

            HStack(spacing: 8) {
                Button(action: onPraying) {
                    HStack(spacing: 6) {
                        Image(systemName: isPraying ? "hands.sparkles.fill" : "hands.sparkles")
                            .font(.system(size: 13, weight: .medium))
                        if post.prayingCount > 0 {
                            Text("\(post.prayingCount)")
                                .font(ABY.Font.captionMedium)
                        } else {
                            Text("Praying")
                                .font(ABY.Font.captionMedium)
                        }
                    }
                    .foregroundStyle(isPraying ? ABY.Color.pillPurple : palette.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isPraying ? ABY.Color.pillPurple.opacity(0.12) : palette.surfaceMuted)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if post.encouragements.isEmpty {
                    Text("Be the first to encourage")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(ABY.Color.pillOrange)
                        Text("\(post.encouragements.count)")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(palette.surfaceMuted)
                    .clipShape(Capsule())
                }

                Spacer()

                Button(action: onOpen) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }
                .buttonStyle(.plain)
            }

            if post.encouragements.isEmpty, !isCurrentUser, let onQuickEncourage {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.quickEncouragements, id: \.self) { phrase in
                            Button {
                                onQuickEncourage(phrase)
                            } label: {
                                Text(phrase)
                                    .font(ABY.Font.captionMedium)
                                    .foregroundStyle(ABY.Color.pillPurple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(ABY.Color.pillPurple.opacity(0.08))
                                    .clipShape(Capsule())
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(ABY.Color.pillPurple.opacity(0.18), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(isCurrentUser ? palette.surfaceElevated : palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(post.kind == .testimony ? ABY.Color.orbSage.opacity(0.25) : palette.divider, lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 8, y: 2)
    }
}

private struct CircleAvatarView: View {
    let name: String
    var hue: Double = 0.5
    var compact = false

    init(member: CircleMember, compact: Bool = false) {
        self.name = member.displayName
        self.hue = member.avatarHue
        self.compact = compact
    }

    init(name: String, hue: Double = 0.5, compact: Bool = false) {
        self.name = name
        self.hue = hue
        self.compact = compact
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hue: hue, saturation: 0.35, brightness: 0.92))
                .frame(width: compact ? 36 : 40, height: compact ? 36 : 40)
            Text(initials)
                .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ABY.Color.textPrimary.opacity(0.75))
        }
    }
}

private struct CircleMemberAvatarStack: View {
    let members: [CircleMember]
    var size: CGFloat = 36
    var maxVisible: Int = 5

    var body: some View {
        HStack(spacing: members.isEmpty ? 0 : -(size * 0.28)) {
            if members.isEmpty {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: size * 0.34, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 2)
                    }
            } else {
                ForEach(Array(visibleMembers.enumerated()), id: \.element.id) { index, member in
                    memberBubble(for: member)
                        .zIndex(Double(maxVisible - index))
                }

                if overflowCount > 0 {
                    Text("+\(overflowCount)")
                        .font(.system(size: size * 0.28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: size, height: size)
                        .background(Color.white.opacity(0.22))
                        .clipShape(Circle())
                        .overlay {
                            Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 2)
                        }
                }
            }
        }
    }

    private var visibleMembers: [CircleMember] {
        Array(members.prefix(maxVisible))
    }

    private var overflowCount: Int {
        max(0, members.count - maxVisible)
    }

    @ViewBuilder
    private func memberBubble(for member: CircleMember) -> some View {
        ZStack {
            Circle()
                .fill(member.avatarColor)
                .frame(width: size, height: size)
            Text(member.initials)
                .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                .foregroundStyle(ABY.Color.textPrimary.opacity(0.75))
        }
        .overlay {
            Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
        }
    }
}

private struct CircleCollectiveStatsRow: View {
    let stats: CircleCollectiveStats

    var body: some View {
        HStack(spacing: 8) {
            if stats.prayersLifted > 0 {
                statChip(
                    icon: "hands.sparkles.fill",
                    label: "\(stats.prayersLifted) prayers lifted together"
                )
            }
            if stats.testimoniesCelebrated > 0 {
                statChip(
                    icon: "checkmark.seal.fill",
                    label: "\(stats.testimoniesCelebrated) testimonies celebrated"
                )
            }
        }
    }

    private func statChip(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.18))
        .clipShape(Capsule())
    }
}

struct CircleMilestonePresentation: Identifiable {
    let kind: CircleMilestoneKind
    var id: String { kind.rawValue }
}

struct CircleMilestoneCelebrationView: View {
    let circleName: String
    let milestone: CircleMilestoneKind
    var onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()
            ConfettiView(isActive: appeared)

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(ABY.Color.pillPurple.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: milestone.isPrayerMilestone ? "hands.sparkles.fill" : "checkmark.seal.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(ABY.Color.pillPurple)
                }
                .scaleEffect(appeared ? 1 : 0.5)

                VStack(spacing: 10) {
                    Text("Circle milestone")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.textTertiary)
                    Text(milestone.celebrationMessage(circleName: circleName))
                        .font(ABY.Font.title2)
                        .foregroundStyle(ABY.Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Celebrate what God is doing together — no rankings, just gratitude.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer()

                ABYPrimaryButton(title: "Celebrate with your circle", icon: "heart.fill") {
                    DevotionHaptics.success()
                    onContinue()
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 32)
            }
            .opacity(appeared ? 1 : 0)
        }
        .abyScreen()
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }
}

private struct CircleMomentContext {
    let posts: [CirclePost]
    let members: [CircleMember]
    let currentMemberId: UUID?
    let isPrayingOnAny: Bool
    let stats: CircleCollectiveStats
    let circleId: UUID

    var banner: CircleMoment? {
        guard !posts.isEmpty else { return nil }

        if let unanswered = posts.first(where: { needsResponse($0) }) {
            let name = unanswered.isAnonymous ? "Someone" : unanswered.displayAuthor
            return CircleMoment(
                icon: "hands.sparkles.fill",
                message: "\(name) could use your prayers today",
                actionLabel: "Respond"
            )
        }

        for kind in CircleMilestoneKind.allCases {
            if let proximity = kind.proximityMessage(stats: stats),
               !CircleMilestoneStore.shared.hasCelebrated(kind, circleId: circleId) {
                return CircleMoment(
                    icon: kind.isPrayerMilestone ? "hands.sparkles.fill" : "checkmark.seal.fill",
                    message: proximity,
                    actionLabel: "Keep going"
                )
            }
        }

        if !isPrayingOnAny, posts.contains(where: { $0.authorId != currentMemberId }) {
            return CircleMoment(
                icon: "heart.fill",
                message: "Take a moment to pray with your circle",
                actionLabel: "View posts"
            )
        }

        let testimonyCount = stats.testimoniesCelebrated
        if testimonyCount > 0 {
            return CircleMoment(
                icon: "checkmark.seal.fill",
                message: "\(testimonyCount) answered prayer\(testimonyCount == 1 ? "" : "s") to celebrate",
                actionLabel: "See testimonies"
            )
        }

        return nil
    }

    var suggestedPost: CirclePost? {
        posts.first(where: { needsResponse($0) }) ?? posts.first
    }

    private func needsResponse(_ post: CirclePost) -> Bool {
        guard post.authorId != currentMemberId else { return false }
        guard let currentMemberId else { return true }
        return !post.prayingMemberIds.contains(currentMemberId) && post.encouragements.isEmpty
    }
}

private struct CircleMoment {
    let icon: String
    let message: String
    let actionLabel: String
}

private struct CircleMomentBanner: View {
    @Environment(\.sanctuaryPalette) private var palette
    let moment: CircleMoment
    var onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 12) {
                Image(systemName: moment.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ABY.Color.pillPurple)
                    .frame(width: 36, height: 36)
                    .background(ABY.Color.pillPurple.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(moment.message)
                        .font(ABY.Font.callout.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(moment.actionLabel)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.pillPurple)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ABY.Color.pillPurple.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Sheets

struct ShareToCircleSheet: View {
    let note: PrayerWallNote
    var circleStore: PrayerCircleStore
    var onShared: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    @State private var selectedCircleId: UUID?
    @State private var visibility: CircleShareVisibility = .named

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Share to circle")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)

                Text("“\(note.text)”")
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(PrayerWallNote.inkColor)
                    .lineLimit(4)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(note.paperColor)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))

                Text("Choose a circle")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)

                if circleStore.circles.isEmpty {
                    Text("Create a circle first from the Circles tab.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                } else {
                    ForEach(circleStore.circles) { circle in
                        Button {
                            selectedCircleId = circle.id
                        } label: {
                            HStack {
                                Text(circle.name)
                                    .font(ABY.Font.callout)
                                    .foregroundStyle(palette.textPrimary)
                                Spacer()
                                if selectedCircleId == circle.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ABY.Color.pillPurple)
                                }
                            }
                            .padding(14)
                            .background(selectedCircleId == circle.id ? ABY.Color.pillPurple.opacity(0.08) : palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Picker("Visibility", selection: $visibility) {
                    ForEach(CircleShareVisibility.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()

                ABYPrimaryButton(title: "Share to circle", icon: "person.3.fill") {
                    guard let circleId = selectedCircleId ?? circleStore.circles.first?.id else { return }
                    _ = circleStore.shareNote(note, to: circleId, visibility: visibility)
                    DevotionHaptics.success()
                    onShared()
                    dismiss()
                }
                .opacity(selectedCircleId != nil || circleStore.circles.count == 1 ? 1 : 0.45)
                .disabled(selectedCircleId == nil && circleStore.circles.count != 1)
            }
            .padding(ABY.Spacing.screen)
            .background(ABYCleanGradientBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                selectedCircleId = circleStore.circles.first?.id
            }
        }
        .abyScreen()
    }
}

struct ShareTestimonySheet: View {
    let note: PrayerWallNote
    var circleStore: PrayerCircleStore
    var verseReference: String?
    var onShared: () -> Void
    var onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    @State private var selectedCircleId: UUID?
    @State private var visibility: CircleShareVisibility = .named

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(ABY.Color.orbSage)

                        Text("Answered!")
                            .font(ABY.Font.title2)
                            .foregroundStyle(palette.textPrimary)

                        Text("Share this testimony with your circle?")
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    Text("“\(note.text)”")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(PrayerWallNote.inkColor)
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(ABY.Color.orbSage.opacity(palette.isNight ? 0.18 : 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))

                    if !circleStore.circles.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(circleStore.circles) { circle in
                                Button {
                                    selectedCircleId = circle.id
                                } label: {
                                    HStack {
                                        Text(circle.name)
                                        Spacer()
                                        if selectedCircleId == circle.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(ABY.Color.orbSage)
                                        }
                                    }
                                    .font(ABY.Font.callout)
                                    .foregroundStyle(palette.textPrimary)
                                    .padding(14)
                                    .background(palette.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Picker("Visibility", selection: $visibility) {
                            ForEach(CircleShareVisibility.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 24)
            }
            .background(ABYCleanGradientBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 12) {
                    ABYPrimaryButton(title: "Share testimony", icon: "sparkles") {
                        guard let circleId = selectedCircleId ?? circleStore.circles.first?.id else { return }
                        _ = circleStore.shareTestimony(
                            text: note.text,
                            to: circleId,
                            sourceNoteId: note.id,
                            verseReference: verseReference,
                            visibility: visibility
                        )
                        DevotionHaptics.success()
                        onShared()
                        dismiss()
                    }

                    Button("Keep private", action: onSkip)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background {
                    SanctuaryGradientBottomFade()
                }
            }
            .onAppear {
                selectedCircleId = circleStore.circles.first?.id
            }
        }
        .abyScreen()
        .interactiveDismissDisabled(false)
    }
}

private struct CreateCircleSheet: View {
    var circleStore: PrayerCircleStore
    var onCreated: (PrayerCircle) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Name your circle")
                    .font(ABY.Font.headline)
                TextField("Family, small group, roommates…", text: $name)
                    .font(ABY.Font.body)
                    .padding(14)
                    .background(ABY.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                    .focused($focused)

                ABYPrimaryButton(title: "Create circle", icon: "plus") {
                    let circle = circleStore.createCircle(name: name)
                    onCreated(circle)
                    dismiss()
                }
                .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(ABY.Spacing.screen)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

struct JoinCircleSheet: View {
    var circleStore: PrayerCircleStore
    var onJoined: (PrayerCircle) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var error: String?
    @State private var isJoining = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter invite code")
                    .font(ABY.Font.headline)
                TextField("ABC123", text: $code)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .padding(14)
                    .background(ABY.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                    .focused($focused)

                if let error {
                    Text(error)
                        .font(ABY.Font.caption)
                        .foregroundStyle(.red.opacity(0.85))
                }

                ABYPrimaryButton(title: isJoining ? "Joining…" : "Join circle", icon: "link") {
                    Task {
                        isJoining = true
                        error = nil
                        if let circle = await circleStore.joinCircleRemote(code: code) {
                            onJoined(circle)
                            dismiss()
                        } else {
                            error = "We couldn't find a circle with that code."
                        }
                        isJoining = false
                    }
                }
                .opacity(code.count >= 4 && !isJoining ? 1 : 0.45)
                .disabled(code.count < 4 || isJoining)

                Spacer()
            }
            .padding(ABY.Spacing.screen)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

private struct CircleMembersSheet: View {
    let circle: PrayerCircle
    let members: [CircleMember]
    var canStartChallenge: Bool = true
    var onStartChallenge: (() -> Void)?
    var onInvite: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    CircleMemberAvatarStack(members: members, size: 48, maxVisible: 6)
                        .padding(.top, 8)

                    Text("\(members.count) member\(members.count == 1 ? "" : "s") in \(circle.name)")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        ForEach(members) { member in
                            HStack(spacing: 12) {
                                CircleAvatarView(member: member)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.isCurrentUser ? "\(member.displayName) (You)" : member.displayName)
                                        .font(ABY.Font.callout.weight(.semibold))
                                        .foregroundStyle(palette.textPrimary)
                                    Text(member.isCurrentUser ? "Circle member" : "Praying with you")
                                        .font(ABY.Font.caption)
                                        .foregroundStyle(palette.textSecondary)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(palette.divider, lineWidth: 1)
                            }
                        }
                    }

                    if canStartChallenge, let onStartChallenge {
                        Button(action: onStartChallenge) {
                            Label("Start a challenge", systemImage: "sparkles")
                                .font(ABY.Font.headline)
                                .foregroundStyle(ABY.Color.pillTeal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ABY.Color.pillTeal.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(ABY.Color.pillTeal.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    Button(action: onInvite) {
                        Label("Invite someone", systemImage: "person.badge.plus")
                            .font(ABY.Font.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ABY.Color.pillPurple)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(ABY.Spacing.screen)
            }
            .background(palette.background)
            .navigationTitle("Members")
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
}

private struct CircleInviteSheet: View {
    let circle: PrayerCircle
    var circleStore: PrayerCircleStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Invite to \(circle.name)")
                    .font(ABY.Font.title2)

                Text(circle.inviteCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(ABY.Color.pillPurple)
                    .padding(.vertical, 8)

                Text("Share this code or link with people you trust.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .multilineTextAlignment(.center)

                if let url = circleStore.inviteURL(for: circle) {
                    ShareLink(item: url, subject: Text("Join my prayer circle"), message: Text("Join \(circle.name) on Devotion Lock: \(circle.inviteCode)")) {
                        Label("Share invite link", systemImage: "square.and.arrow.up")
                            .font(ABY.Font.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ABY.Color.pillPurple)
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
            .padding(ABY.Spacing.screen)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct CircleComposeSheet: View {
    let circle: PrayerCircle
    var circleStore: PrayerCircleStore

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    @State private var text = ""
    @FocusState private var focused: Bool

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextEditor(text: $text)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(palette.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: ABY.Radius.card)
                            .stroke(palette.divider, lineWidth: 1)
                    }
                    .focused($focused)

                ABYPrimaryButton(title: "Post to circle", icon: "paperplane.fill") {
                    guard let me = circleStore.currentMember else { return }
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    circleStore.addPost(CirclePost(
                        id: UUID(),
                        circleId: circle.id,
                        authorId: me.id,
                        authorName: me.displayName,
                        isAnonymous: false,
                        kind: .request,
                        text: trimmed,
                        createdAt: Date(),
                        focusTag: TodayFocusStore.tags.first?.rawValue,
                        sourceNoteId: nil,
                        verseReference: nil,
                        prayingMemberIds: [],
                        encouragements: []
                    ))
                    dismiss()
                }
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(ABY.Spacing.screen)
            .background(palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } }
            }
            .onAppear { focused = true }
        }
        .abyScreen()
        .presentationDetents([.medium, .large])
        .presentationBackground(palette.background)
    }
}

private struct CirclePostDetailSheet: View {
    let post: CirclePost
    var circleStore: PrayerCircleStore

    @Environment(\.dismiss) private var dismiss
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    @State private var reply = ""

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                CirclePostCard(
                    post: post,
                    authorHue: circleStore.member(for: post.authorId)?.avatarHue ?? 0.12,
                    isCurrentUser: post.authorId == circleStore.currentMemberId,
                    isPraying: circleStore.isPraying(postId: post.id),
                    onPraying: { circleStore.togglePraying(postId: post.id) },
                    onOpen: {},
                    onQuickEncourage: { text in
                        circleStore.addEncouragement(postId: post.id, text: text)
                        DevotionHaptics.success()
                    }
                )

                if !post.encouragements.isEmpty {
                    Text("Encouragements")
                        .font(ABY.Font.section)
                        .foregroundStyle(palette.textSecondary)
                    ForEach(post.encouragements) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.authorName)
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(palette.textPrimary)
                            Text(item.text)
                                .font(ABY.Font.callout)
                                .foregroundStyle(palette.textSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                HStack(spacing: 10) {
                    TextField("Reply with encouragement…", text: $reply)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textPrimary)
                        .padding(12)
                        .background(palette.surfaceMuted)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(palette.divider, lineWidth: 1)
                        }

                    Button {
                        circleStore.addEncouragement(postId: post.id, text: reply)
                        reply = ""
                        DevotionHaptics.light()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(ABY.Color.pillPurple)
                    }
                    .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer()
            }
            .padding(ABY.Spacing.screen)
            .background(palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .abyScreen()
        .presentationDetents([.medium, .large])
        .presentationBackground(palette.background)
    }
}

// MARK: - Wall segment control

struct PrayerWallSegmentedControl: View {
    @Binding var selection: PrayerWallTab
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PrayerWallTab.allCases) { tab in
                Button {
                    withAnimation(AppTheme.springSnappy) { selection = tab }
                } label: {
                    Text(tab.label)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(selection == tab ? palette.textPrimary : palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == tab ? palette.surfaceElevated : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(palette.track.opacity(0.65))
        .clipShape(Capsule())
    }
}

enum PrayerWallTab: String, CaseIterable, Identifiable {
    case myWall
    case circles

    var id: String { rawValue }

    var label: String {
        switch self {
        case .myWall: "My wall"
        case .circles: "Circles"
        }
    }
}
