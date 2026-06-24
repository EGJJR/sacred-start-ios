//
//  PrayerCircleStore.swift
//  DevotionLock
//

import Foundation
import Observation

@Observable
@MainActor
final class PrayerCircleStore {
    static let shared = PrayerCircleStore()

    private enum Keys {
        static let circles = "prayerCircles"
        static let members = "prayerCircleMembers"
        static let posts = "prayerCirclePosts"
        static let challenges = "prayerCircleChallenges"
        static let currentMemberId = "prayerCircleCurrentMemberId"
        static let didSeed = "prayerCircleDidSeed"
        static let acceptedGuidelines = "prayerCircleAcceptedGuidelines"
    }

    private(set) var circles: [PrayerCircle] = []
    private(set) var members: [CircleMember] = []
    private(set) var posts: [CirclePost] = []
    private(set) var challenges: [CircleChallenge] = []
    private(set) var currentMemberId: UUID?
    private(set) var isSyncing = false

    var hasAcceptedGuidelines: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.acceptedGuidelines) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.acceptedGuidelines) }
    }

    var currentMember: CircleMember? {
        guard let currentMemberId else { return nil }
        return members.first { $0.id == currentMemberId }
    }

    var totalUnreadPosts: Int {
        posts.filter { $0.createdAt > lastOpenedAt }.count
    }

    private var lastOpenedAt: Date {
        UserDefaults.standard.object(forKey: "prayerCircleLastOpened") as? Date ?? .distantPast
    }

    init() {
        load()
        ensureCurrentMember()
        seedIfNeeded()
    }

    func markFeedOpened() {
        UserDefaults.standard.set(Date(), forKey: "prayerCircleLastOpened")
    }

    func refreshFromRemote() async {
        isSyncing = true
        defer { isSyncing = false }
        await CircleRepository.shared.pullRemote(into: self)
    }

    func members(for circle: PrayerCircle) -> [CircleMember] {
        circle.memberIds.compactMap { id in members.first { $0.id == id } }
    }

    func member(for id: UUID) -> CircleMember? {
        members.first { $0.id == id }
    }

    func collectiveStats(for circleId: UUID) -> CircleCollectiveStats {
        CircleCollectiveStats.compute(from: posts.filter { $0.circleId == circleId })
    }

    func activeChallenge(for circleId: UUID) -> CircleChallenge? {
        challenges
            .filter { $0.circleId == circleId && $0.isActive }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func latestEndedChallenge(for circleId: UUID) -> CircleChallenge? {
        challenges
            .filter { $0.circleId == circleId && $0.isEnded }
            .sorted { $0.endsAt > $1.endsAt }
            .first
    }

    func reflections(for challengeId: UUID) -> [CirclePost] {
        posts
            .filter { $0.challengeId == challengeId && $0.kind == .reflection }
            .sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func startChallenge(
        template: CircleChallengeTemplate,
        circleId: UUID,
        durationDays: Int = 7
    ) -> CircleChallenge? {
        guard activeChallenge(for: circleId) == nil else { return nil }
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .day, value: durationDays, to: now) ?? now
        let challenge = CircleChallenge(
            id: UUID(),
            circleId: circleId,
            title: template.title,
            prompt: template.prompt,
            verseReference: template.verseReference,
            kind: template.kind,
            startsAt: now,
            endsAt: endsAt,
            createdAt: now
        )
        challenges.insert(challenge, at: 0)
        persist()
        if AuthManager.shared.isAuthenticated {
            CircleRepository.shared.enqueueCreateChallenge(challenge)
        }
        return challenge
    }

    @discardableResult
    func addReflection(
        text: String,
        challengeId: UUID,
        circleId: UUID,
        visibility: CircleShareVisibility = .named
    ) -> CirclePost? {
        guard let me = currentMember,
              let challenge = challenges.first(where: { $0.id == challengeId })
        else { return nil }

        let post = CirclePost(
            id: UUID(),
            circleId: circleId,
            authorId: me.id,
            authorName: me.displayName,
            isAnonymous: visibility == .anonymous,
            kind: .reflection,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            focusTag: nil,
            sourceNoteId: nil,
            verseReference: challenge.verseReference,
            challengeId: challengeId,
            prayingMemberIds: [],
            encouragements: []
        )
        posts.insert(post, at: 0)
        persist()
        enqueuePostIfNeeded(post)
        return post
    }

    func posts(for circleId: UUID, sort: CircleFeedSort = .newest) -> [CirclePost] {
        let filtered = posts.filter { $0.circleId == circleId }
        switch sort {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .testimonies:
            return filtered.filter { $0.kind == .testimony }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func latestPost(for circleId: UUID) -> CirclePost? {
        posts(for: circleId, sort: .newest).first
    }

    @discardableResult
    private func createCircleLocal(name: String) -> PrayerCircle {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = Self.generateInviteCode()
        var memberIds: [UUID] = []
        if let me = currentMember {
            memberIds.append(me.id)
        }
        let circle = PrayerCircle(
            id: UUID(),
            name: trimmed.isEmpty ? "Prayer Circle" : trimmed,
            inviteCode: code,
            createdAt: Date(),
            memberIds: memberIds,
            coverPaletteIndex: circles.count
        )
        circles.insert(circle, at: 0)
        persist()
        return circle
    }

    @discardableResult
    func createCircle(name: String) async -> PrayerCircle {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = Self.generateInviteCode()
        var memberIds: [UUID] = []
        if let me = currentMember {
            memberIds.append(me.id)
        }
        let circle = PrayerCircle(
            id: UUID(),
            name: trimmed.isEmpty ? "Prayer Circle" : trimmed,
            inviteCode: code,
            createdAt: Date(),
            memberIds: memberIds,
            coverPaletteIndex: circles.count
        )
        circles.insert(circle, at: 0)
        persist()

        if AuthManager.shared.isAuthenticated,
           let memberId = currentMemberId,
           let userId = AuthManager.shared.userId {
            do {
                try await CircleRepository.shared.createCircleRemote(
                    circle,
                    creatorMembershipId: memberId,
                    userId: userId
                )
            } catch {
                #if DEBUG
                print("createCircle remote sync failed, queueing: \(error)")
                #endif
                CircleRepository.shared.enqueueCreateCircle(circle, memberId: memberId)
            }
        }
        return circle
    }

    @discardableResult
    func joinCircle(code: String) -> PrayerCircle? {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard var circle = circles.first(where: { $0.inviteCode.uppercased() == normalized }) else {
            return nil
        }
        guard let me = currentMember, !circle.memberIds.contains(me.id) else {
            return circle
        }
        circle.memberIds.append(me.id)
        if let index = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[index] = circle
        }
        persist()

        if AuthManager.shared.isAuthenticated, let memberId = currentMemberId {
            CircleRepository.shared.enqueueJoinCircle(code: normalized, memberId: memberId)
        }
        return circle
    }

    func joinCircleRemote(code: String) async -> PrayerCircle? {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return nil }

        guard AuthManager.shared.isAuthenticated else {
            return joinCircle(code: normalized)
        }

        if let local = circles.first(where: { $0.inviteCode.uppercased() == normalized }),
           local.memberIds.contains(where: { $0 == currentMemberId }) {
            return local
        }

        guard let circleId = await CircleRepository.shared.joinCircleRemote(code: normalized) else {
            return nil
        }

        await refreshFromRemote()
        if let joined = circles.first(where: { $0.id == circleId }) {
            return joined
        }

        if let row = await CircleRepository.shared.fetchCircle(id: circleId),
           let userId = AuthManager.shared.userId {
            mergeRemoteSnapshot(
                circles: [row],
                memberships: [],
                posts: [],
                encouragements: [],
                currentUserId: userId
            )
            _ = joinCircle(code: normalized)
            return circles.first { $0.id == circleId }
        }

        return nil
    }

    func shareNote(
        _ note: PrayerWallNote,
        to circleId: UUID,
        visibility: CircleShareVisibility,
        focusTag: String? = nil
    ) -> CirclePost? {
        guard let me = currentMember else { return nil }
        let kind: CirclePostKind = switch note.kind {
        case .request: .request
        case .reminder: .reminder
        case .answered: .testimony
        }
        let post = CirclePost(
            id: UUID(),
            circleId: circleId,
            authorId: me.id,
            authorName: me.displayName,
            isAnonymous: visibility == .anonymous,
            kind: kind,
            text: note.text,
            createdAt: Date(),
            focusTag: focusTag ?? TodayFocusStore.tags.first?.rawValue,
            sourceNoteId: note.id,
            verseReference: nil,
            prayingMemberIds: [],
            encouragements: []
        )
        posts.insert(post, at: 0)
        persist()
        enqueuePostIfNeeded(post)
        return post
    }

    func shareTestimony(
        text: String,
        to circleId: UUID,
        sourceNoteId: UUID?,
        verseReference: String? = nil,
        visibility: CircleShareVisibility = .named
    ) -> CirclePost? {
        guard let me = currentMember else { return nil }
        let post = CirclePost(
            id: UUID(),
            circleId: circleId,
            authorId: me.id,
            authorName: me.displayName,
            isAnonymous: visibility == .anonymous,
            kind: .testimony,
            text: text,
            createdAt: Date(),
            focusTag: TodayFocusStore.tags.first?.rawValue,
            sourceNoteId: sourceNoteId,
            verseReference: verseReference,
            prayingMemberIds: [],
            encouragements: []
        )
        posts.insert(post, at: 0)
        persist()
        enqueuePostIfNeeded(post)
        return post
    }

    func togglePraying(postId: UUID) {
        guard let me = currentMember,
              let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        if posts[index].prayingMemberIds.contains(me.id) {
            posts[index].prayingMemberIds.removeAll { $0 == me.id }
        } else {
            posts[index].prayingMemberIds.append(me.id)
        }
        persist()

        if AuthManager.shared.isAuthenticated {
            CircleRepository.shared.enqueueUpdatePrayers(
                postId: postId,
                prayingMemberIds: posts[index].prayingMemberIds
            )
        }
    }

    func isPraying(postId: UUID) -> Bool {
        guard let me = currentMember,
              let post = posts.first(where: { $0.id == postId }) else { return false }
        return post.prayingMemberIds.contains(me.id)
    }

    func addEncouragement(postId: UUID, text: String) {
        guard let me = currentMember,
              let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let encouragement = CircleEncouragement(
            id: UUID(),
            authorName: me.displayName,
            text: trimmed,
            createdAt: Date()
        )
        posts[index].encouragements.insert(encouragement, at: 0)
        persist()

        if AuthManager.shared.isAuthenticated {
            CircleRepository.shared.enqueueEncouragement(
                postId: postId,
                encouragement: encouragement,
                authorMembershipId: me.id
            )
        }
    }

    func addPost(_ post: CirclePost) {
        posts.insert(post, at: 0)
        persist()
        enqueuePostIfNeeded(post)
    }

    func inviteURL(for circle: PrayerCircle) -> URL? {
        DevotionDeepLink.url(host: .joinCircle, query: ["code": circle.inviteCode])
    }

    // MARK: - Remote merge

    func mergeRemoteSnapshot(
        circles remoteCircles: [DBCircle],
        memberships: [DBCircleMembership],
        posts remotePosts: [DBCirclePost],
        challenges remoteChallenges: [DBCircleChallenge] = [],
        encouragements: [DBCircleEncouragement],
        currentUserId: UUID
    ) {
        var mergedMembers = members
        for row in memberships {
            let member = CircleMember(
                id: row.id,
                displayName: row.displayName,
                avatarHue: row.avatarHue,
                isCurrentUser: row.userId == currentUserId
            )
            if let index = mergedMembers.firstIndex(where: { $0.id == row.id }) {
                mergedMembers[index] = member
            } else {
                mergedMembers.append(member)
            }
            if row.userId == currentUserId {
                currentMemberId = row.id
                UserDefaults.standard.set(row.id.uuidString, forKey: Keys.currentMemberId)
            }
        }

        var mergedCircles = circles
        for row in remoteCircles {
            let memberIds = memberships.filter { $0.circleId == row.id }.map(\.id)
            let circle = PrayerCircle(
                id: row.id,
                name: row.name,
                inviteCode: row.inviteCode,
                createdAt: row.createdAt,
                memberIds: memberIds,
                coverPaletteIndex: row.coverPaletteIndex
            )
            if let index = mergedCircles.firstIndex(where: { $0.id == row.id }) {
                mergedCircles[index] = circle
            } else {
                mergedCircles.insert(circle, at: 0)
            }
        }

        var encouragementByPost = Dictionary(grouping: encouragements, by: \.postId)
        var mergedPosts = posts
        for row in remotePosts {
            let postEncouragements = (encouragementByPost[row.id] ?? []).map {
                CircleEncouragement(
                    id: $0.id,
                    authorName: $0.authorName,
                    text: $0.text,
                    createdAt: $0.createdAt
                )
            }
            let kind = CirclePostKind(rawValue: row.kind) ?? .request
            let post = CirclePost(
                id: row.id,
                circleId: row.circleId,
                authorId: row.authorMembershipId,
                authorName: row.authorName,
                isAnonymous: row.isAnonymous,
                kind: kind,
                text: row.text,
                createdAt: row.createdAt,
                focusTag: row.focusTag,
                sourceNoteId: row.sourceNoteId,
                verseReference: row.verseReference,
                challengeId: row.challengeId,
                prayingMemberIds: row.prayingMemberIds,
                encouragements: postEncouragements.sorted { $0.createdAt > $1.createdAt }
            )
            if let index = mergedPosts.firstIndex(where: { $0.id == row.id }) {
                mergedPosts[index] = post
            } else {
                mergedPosts.append(post)
            }
        }

        var mergedChallenges = challenges
        for row in remoteChallenges {
            let challenge = challengeFromRow(row)
            if let index = mergedChallenges.firstIndex(where: { $0.id == row.id }) {
                mergedChallenges[index] = challenge
            } else {
                mergedChallenges.append(challenge)
            }
        }

        members = mergedMembers
        circles = mergedCircles.sorted { $0.createdAt > $1.createdAt }
        posts = mergedPosts.sorted { $0.createdAt > $1.createdAt }
        challenges = mergedChallenges.sorted { $0.createdAt > $1.createdAt }
        persist()
    }

    func mergeRemoteChallenge(_ row: DBCircleChallenge) {
        let challenge = challengeFromRow(row)
        if let index = challenges.firstIndex(where: { $0.id == row.id }) {
            challenges[index] = challenge
        } else {
            challenges.insert(challenge, at: 0)
        }
        persist()
    }

    func mergeRemotePost(_ row: DBCirclePost) {
        let kind = CirclePostKind(rawValue: row.kind) ?? .request
        let post = CirclePost(
            id: row.id,
            circleId: row.circleId,
            authorId: row.authorMembershipId,
            authorName: row.authorName,
            isAnonymous: row.isAnonymous,
            kind: kind,
            text: row.text,
            createdAt: row.createdAt,
            focusTag: row.focusTag,
            sourceNoteId: row.sourceNoteId,
            verseReference: row.verseReference,
            challengeId: row.challengeId,
            prayingMemberIds: row.prayingMemberIds,
            encouragements: posts.first(where: { $0.id == row.id })?.encouragements ?? []
        )
        if let index = posts.firstIndex(where: { $0.id == row.id }) {
            posts[index] = post
        } else {
            posts.insert(post, at: 0)
        }
        persist()
    }

    private func challengeFromRow(_ row: DBCircleChallenge) -> CircleChallenge {
        CircleChallenge(
            id: row.id,
            circleId: row.circleId,
            title: row.title,
            prompt: row.prompt,
            verseReference: row.verseReference,
            kind: CircleChallengeKind(rawValue: row.kind) ?? .gratitude,
            startsAt: row.startsAt,
            endsAt: row.endsAt,
            createdAt: row.createdAt
        )
    }

    func mergeRemoteEncouragement(_ row: DBCircleEncouragement) {
        guard let index = posts.firstIndex(where: { $0.id == row.postId }) else { return }
        let encouragement = CircleEncouragement(
            id: row.id,
            authorName: row.authorName,
            text: row.text,
            createdAt: row.createdAt
        )
        if !posts[index].encouragements.contains(where: { $0.id == row.id }) {
            posts[index].encouragements.insert(encouragement, at: 0)
            persist()
        }
    }

    func mergeRemoteMembership(_ row: DBCircleMembership) {
        let member = CircleMember(
            id: row.id,
            displayName: row.displayName,
            avatarHue: row.avatarHue,
            isCurrentUser: row.userId == AuthManager.shared.userId
        )
        if !members.contains(where: { $0.id == row.id }) {
            members.append(member)
        }
        if let circleIndex = circles.firstIndex(where: { $0.id == row.circleId }),
           !circles[circleIndex].memberIds.contains(row.id) {
            circles[circleIndex].memberIds.append(row.id)
        }
        persist()
    }

    private func enqueuePostIfNeeded(_ post: CirclePost) {
        if AuthManager.shared.isAuthenticated {
            CircleRepository.shared.enqueueCreatePost(post)
        }
    }

    private func ensureCurrentMember() {
        if let idString = UserDefaults.standard.string(forKey: Keys.currentMemberId),
           let id = UUID(uuidString: idString),
           members.contains(where: { $0.id == id }) {
            currentMemberId = id
            syncCurrentMemberName()
            return
        }
        let name = AuthManager.shared.displayName
        let member = CircleMember(
            id: UUID(),
            displayName: name,
            avatarHue: Double.random(in: 0...1),
            isCurrentUser: true
        )
        members.append(member)
        currentMemberId = member.id
        UserDefaults.standard.set(member.id.uuidString, forKey: Keys.currentMemberId)
        persist()
    }

    private func syncCurrentMemberName() {
        guard let id = currentMemberId,
              let index = members.firstIndex(where: { $0.id == id }) else { return }
        members[index].displayName = AuthManager.shared.displayName
        persist()
    }

    private static func generateInviteCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.circles),
           let decoded = try? JSONDecoder().decode([PrayerCircle].self, from: data) {
            circles = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Keys.members),
           let decoded = try? JSONDecoder().decode([CircleMember].self, from: data) {
            members = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Keys.posts),
           let decoded = try? JSONDecoder().decode([CirclePost].self, from: data) {
            posts = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Keys.challenges),
           let decoded = try? JSONDecoder().decode([CircleChallenge].self, from: data) {
            challenges = decoded
        }
        if let idString = UserDefaults.standard.string(forKey: Keys.currentMemberId) {
            currentMemberId = UUID(uuidString: idString)
        }
    }

    func persist() {
        if let data = try? JSONEncoder().encode(circles) {
            UserDefaults.standard.set(data, forKey: Keys.circles)
        }
        if let data = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(data, forKey: Keys.members)
        }
        if let data = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(data, forKey: Keys.posts)
        }
        if let data = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(data, forKey: Keys.challenges)
        }
    }

    private func seedIfNeeded() {
        guard !AuthManager.shared.isAuthenticated,
              !UserDefaults.standard.bool(forKey: Keys.didSeed),
              circles.isEmpty else { return }

        let circle = createCircleLocal(name: "Family Circle")

        let maria = CircleMember(id: UUID(), displayName: "Maria", avatarHue: 0.08, isCurrentUser: false)
        let james = CircleMember(id: UUID(), displayName: "James", avatarHue: 0.55, isCurrentUser: false)
        members.append(contentsOf: [maria, james])

        if let index = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[index].memberIds.append(contentsOf: [maria.id, james.id])
        }

        posts = [
            CirclePost(
                id: UUID(),
                circleId: circle.id,
                authorId: maria.id,
                authorName: maria.displayName,
                isAnonymous: false,
                kind: .request,
                text: "Praying for peace in our home this week — would love your prayers too.",
                createdAt: Date().addingTimeInterval(-3600 * 5),
                focusTag: FocusTag.family.rawValue,
                sourceNoteId: nil,
                verseReference: nil,
                prayingMemberIds: currentMemberId.map { [$0] } ?? [],
                encouragements: [
                    CircleEncouragement(id: UUID(), authorName: james.displayName, text: "Holding you in prayer 🤍", createdAt: Date().addingTimeInterval(-3600 * 4))
                ]
            ),
            CirclePost(
                id: UUID(),
                circleId: circle.id,
                authorId: james.id,
                authorName: james.displayName,
                isAnonymous: false,
                kind: .testimony,
                text: "Doors opened gently on the job decision — grateful for everyone who prayed.",
                createdAt: Date().addingTimeInterval(-86400 * 2),
                focusTag: FocusTag.work.rawValue,
                sourceNoteId: nil,
                verseReference: "Romans 15:13",
                prayingMemberIds: [maria.id],
                encouragements: []
            ),
        ]

        UserDefaults.standard.set(true, forKey: Keys.didSeed)
        persist()
    }

    func clearDemoData() {
        guard UserDefaults.standard.bool(forKey: Keys.didSeed) else { return }
        circles.removeAll()
        members.removeAll()
        posts.removeAll()
        persist()
    }
}
