//
//  CircleRepository.swift
//  DevotionLock
//

import Foundation
import Supabase

// MARK: - DB row types

struct DBCircle: Codable {
    let id: UUID
    let name: String
    let inviteCode: String
    let coverPaletteIndex: Int
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case coverPaletteIndex = "cover_palette_index"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct DBCircleMembership: Codable {
    let id: UUID
    let circleId: UUID
    let userId: UUID
    let displayName: String
    let avatarHue: Double
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case circleId = "circle_id"
        case userId = "user_id"
        case displayName = "display_name"
        case avatarHue = "avatar_hue"
        case joinedAt = "joined_at"
    }
}

struct DBCirclePost: Codable {
    let id: UUID
    let circleId: UUID
    let authorMembershipId: UUID
    let authorName: String
    let isAnonymous: Bool
    let kind: String
    let text: String
    let focusTag: String?
    let sourceNoteId: UUID?
    let verseReference: String?
    let challengeId: UUID?
    let prayingMemberIds: [UUID]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case circleId = "circle_id"
        case authorMembershipId = "author_membership_id"
        case authorName = "author_name"
        case isAnonymous = "is_anonymous"
        case kind, text
        case focusTag = "focus_tag"
        case sourceNoteId = "source_note_id"
        case verseReference = "verse_reference"
        case challengeId = "challenge_id"
        case prayingMemberIds = "praying_member_ids"
        case createdAt = "created_at"
    }
}

struct DBCircleChallenge: Codable {
    let id: UUID
    let circleId: UUID
    let title: String
    let prompt: String
    let verseReference: String?
    let kind: String
    let startsAt: Date
    let endsAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case circleId = "circle_id"
        case title, prompt
        case verseReference = "verse_reference"
        case kind
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case createdAt = "created_at"
    }
}

struct DBCircleEncouragement: Codable {
    let id: UUID
    let postId: UUID
    let authorMembershipId: UUID
    let authorName: String
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case authorMembershipId = "author_membership_id"
        case authorName = "author_name"
        case text
        case createdAt = "created_at"
    }
}

// MARK: - Offline queue

enum CircleSyncOperationKind: String, Codable {
    case createCircle
    case joinCircle
    case createPost
    case updatePostPrayers
    case addEncouragement
    case createChallenge
}

struct CircleSyncOperation: Codable, Identifiable {
    let id: UUID
    let kind: CircleSyncOperationKind
    let circle: PrayerCircle?
    let memberId: UUID?
    let inviteCode: String?
    let post: CirclePost?
    let challenge: CircleChallenge?
    let encouragement: CircleEncouragement?
    let authorMembershipId: UUID?
    let enqueuedAt: Date
}

@MainActor
final class CircleOfflineQueue {
    static let shared = CircleOfflineQueue()

    private let key = "circleSyncPendingOps"
    private(set) var pendingCount = 0

    func enqueue(_ operation: CircleSyncOperation) {
        var ops = load()
        ops.append(operation)
        save(ops)
    }

    func pending() -> [CircleSyncOperation] {
        load()
    }

    func remove(_ id: UUID) {
        var ops = load()
        ops.removeAll { $0.id == id }
        save(ops)
    }

    private func load() -> [CircleSyncOperation] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let ops = try? JSONDecoder().decode([CircleSyncOperation].self, from: data) else {
            pendingCount = 0
            return []
        }
        pendingCount = ops.count
        return ops
    }

    private func save(_ ops: [CircleSyncOperation]) {
        pendingCount = ops.count
        if let data = try? JSONEncoder().encode(ops) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Repository

@MainActor
final class CircleRepository {
    static let shared = CircleRepository()

    private static let realtimeDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private var activeChannels: [UUID: RealtimeChannelV2] = [:]

    private func teardownChannel(_ channel: RealtimeChannelV2) async {
        await channel.unsubscribe()
        await SupabaseManager.client.realtimeV2.removeChannel(channel)
    }

    func enqueueCreateCircle(_ circle: PrayerCircle, memberId: UUID) {
        CircleOfflineQueue.shared.enqueue(
            CircleSyncOperation(
                id: UUID(),
                kind: .createCircle,
                circle: circle,
                memberId: memberId,
                inviteCode: nil,
                post: nil,
                challenge: nil,
                encouragement: nil,
                authorMembershipId: memberId,
                enqueuedAt: Date()
            )
        )
        Task { await flushPending() }
    }

    func enqueueJoinCircle(code: String, memberId: UUID) {
        CircleOfflineQueue.shared.enqueue(
            CircleSyncOperation(
                id: UUID(),
                kind: .joinCircle,
                circle: nil,
                memberId: memberId,
                inviteCode: code,
                post: nil,
                challenge: nil,
                encouragement: nil,
                authorMembershipId: memberId,
                enqueuedAt: Date()
            )
        )
        Task { await flushPending() }
    }

    func enqueueCreatePost(_ post: CirclePost) {
        CircleOfflineQueue.shared.enqueue(
            CircleSyncOperation(
                id: UUID(),
                kind: .createPost,
                circle: nil,
                memberId: nil,
                inviteCode: nil,
                post: post,
                challenge: nil,
                encouragement: nil,
                authorMembershipId: post.authorId,
                enqueuedAt: Date()
            )
        )
        Task { await flushPending() }
    }

    func enqueueCreateChallenge(_ challenge: CircleChallenge) {
        CircleOfflineQueue.shared.enqueue(
            CircleSyncOperation(
                id: UUID(),
                kind: .createChallenge,
                circle: nil,
                memberId: nil,
                inviteCode: nil,
                post: nil,
                challenge: challenge,
                encouragement: nil,
                authorMembershipId: nil,
                enqueuedAt: Date()
            )
        )
        Task { await flushPending() }
    }

    func enqueueUpdatePrayers(postId: UUID, prayingMemberIds: [UUID]) {
        guard let post = PrayerCircleStore.shared.posts.first(where: { $0.id == postId }) else { return }
        var updated = post
        updated.prayingMemberIds = prayingMemberIds
        CircleOfflineQueue.shared.enqueue(
            CircleSyncOperation(
                id: UUID(),
                kind: .updatePostPrayers,
                circle: nil,
                memberId: nil,
                inviteCode: nil,
                post: updated,
                challenge: nil,
                encouragement: nil,
                authorMembershipId: nil,
                enqueuedAt: Date()
            )
        )
        Task { await flushPending() }
    }

    func enqueueEncouragement(
        postId: UUID,
        encouragement: CircleEncouragement,
        authorMembershipId: UUID
    ) {
        guard var post = PrayerCircleStore.shared.posts.first(where: { $0.id == postId }) else { return }
        post.encouragements.insert(encouragement, at: 0)
        CircleOfflineQueue.shared.enqueue(
            CircleSyncOperation(
                id: UUID(),
                kind: .addEncouragement,
                circle: nil,
                memberId: nil,
                inviteCode: nil,
                post: post,
                challenge: nil,
                encouragement: encouragement,
                authorMembershipId: authorMembershipId,
                enqueuedAt: Date()
            )
        )
        Task { await flushPending() }
    }

    func joinCircleRemote(code: String) async -> UUID? {
        guard AuthManager.shared.isAuthenticated else { return nil }
        do {
            let result: UUID? = try await SupabaseManager.client
                .rpc("join_prayer_circle", params: ["invite_code_param": code.uppercased()])
                .execute()
                .value
            return result
        } catch {
            #if DEBUG
            print("join_prayer_circle failed: \(error)")
            #endif
            return nil
        }
    }

    func flushPending() async {
        guard AuthManager.shared.isAuthenticated,
              let userId = AuthManager.shared.userId else { return }

        for op in CircleOfflineQueue.shared.pending() {
            do {
                switch op.kind {
                case .createCircle:
                    guard let circle = op.circle, let memberId = op.memberId else { continue }
                    try await insertCircle(circle, creatorMembershipId: memberId, userId: userId)
                case .joinCircle:
                    guard let code = op.inviteCode else { continue }
                    _ = try await joinCircleRemote(code: code)
                case .createPost:
                    guard let post = op.post else { continue }
                    try await insertPost(post)
                case .updatePostPrayers:
                    guard let post = op.post else { continue }
                    try await updatePostPrayers(post)
                case .addEncouragement:
                    guard let encouragement = op.encouragement,
                          let post = op.post,
                          let authorId = op.authorMembershipId else { continue }
                    try await insertEncouragement(encouragement, postId: post.id, authorMembershipId: authorId)
                case .createChallenge:
                    guard let challenge = op.challenge else { continue }
                    try await insertChallenge(challenge)
                }
                CircleOfflineQueue.shared.remove(op.id)
            } catch {
                #if DEBUG
                print("Circle sync op failed (\(op.kind)): \(error)")
                #endif
                break
            }
        }
    }

    func pullRemote(into store: PrayerCircleStore) async {
        guard AuthManager.shared.isAuthenticated,
              let userId = AuthManager.shared.userId else { return }

        do {
            let memberships: [DBCircleMembership] = try await SupabaseManager.client
                .from("circle_memberships")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            let circleIds = memberships.map(\.circleId)
            guard !circleIds.isEmpty else { return }

            let circles: [DBCircle] = try await SupabaseManager.client
                .from("prayer_circles")
                .select()
                .in("id", values: circleIds.map(\.uuidString))
                .execute()
                .value

            let allMemberships: [DBCircleMembership] = try await SupabaseManager.client
                .from("circle_memberships")
                .select()
                .in("circle_id", values: circleIds.map(\.uuidString))
                .execute()
                .value

            let posts: [DBCirclePost] = try await SupabaseManager.client
                .from("circle_posts")
                .select()
                .in("circle_id", values: circleIds.map(\.uuidString))
                .order("created_at", ascending: false)
                .execute()
                .value

            let postIds = posts.map(\.id)
            var encouragements: [DBCircleEncouragement] = []
            if !postIds.isEmpty {
                encouragements = try await SupabaseManager.client
                    .from("circle_encouragements")
                    .select()
                    .in("post_id", values: postIds.map(\.uuidString))
                    .execute()
                    .value
            }

            let challenges: [DBCircleChallenge] = try await SupabaseManager.client
                .from("circle_challenges")
                .select()
                .in("circle_id", values: circleIds.map(\.uuidString))
                .order("created_at", ascending: false)
                .execute()
                .value

            store.mergeRemoteSnapshot(
                circles: circles,
                memberships: allMemberships,
                posts: posts,
                challenges: challenges,
                encouragements: encouragements,
                currentUserId: userId
            )
        } catch {
            #if DEBUG
            print("Circle pull failed: \(error)")
            #endif
        }
    }

    func subscribeToCircle(_ circleId: UUID, store: PrayerCircleStore) {
        unsubscribeFromCircle(circleId)

        activeTasks[circleId] = Task {
            defer {
                Task { @MainActor in
                    activeTasks.removeValue(forKey: circleId)
                    if let channel = activeChannels.removeValue(forKey: circleId) {
                        await teardownChannel(channel)
                    }
                }
            }

            guard AuthManager.shared.isAuthenticated else { return }
            let channel = await SupabaseManager.client.realtimeV2.channel("circle:\(circleId.uuidString)")
            await MainActor.run {
                activeChannels[circleId] = channel
            }

            let filter = "circle_id=eq.\(circleId.uuidString)"

            let postInserts = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "circle_posts",
                filter: filter
            )
            let postUpdates = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "circle_posts",
                filter: filter
            )
            let membershipInserts = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "circle_memberships",
                filter: "circle_id=eq.\(circleId.uuidString)"
            )
            let challengeInserts = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "circle_challenges",
                filter: filter
            )

            await channel.subscribe()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await insert in postInserts {
                        guard !Task.isCancelled else { return }
                        guard let row = try? insert.decodeRecord(
                            as: DBCirclePost.self,
                            decoder: Self.realtimeDecoder
                        ) else { continue }
                        await store.mergeRemotePost(row)
                    }
                }
                group.addTask {
                    for await update in postUpdates {
                        guard !Task.isCancelled else { return }
                        guard let row = try? update.decodeRecord(
                            as: DBCirclePost.self,
                            decoder: Self.realtimeDecoder
                        ) else { continue }
                        await store.mergeRemotePost(row)
                    }
                }
                group.addTask {
                    for await insert in membershipInserts {
                        guard !Task.isCancelled else { return }
                        guard let row = try? insert.decodeRecord(
                            as: DBCircleMembership.self,
                            decoder: Self.realtimeDecoder
                        ) else { continue }
                        await store.mergeRemoteMembership(row)
                    }
                }
                group.addTask {
                    for await insert in challengeInserts {
                        guard !Task.isCancelled else { return }
                        guard let row = try? insert.decodeRecord(
                            as: DBCircleChallenge.self,
                            decoder: Self.realtimeDecoder
                        ) else { continue }
                        await store.mergeRemoteChallenge(row)
                    }
                }
            }
        }
    }

    func unsubscribeFromCircle(_ circleId: UUID) {
        activeTasks[circleId]?.cancel()
        activeTasks.removeValue(forKey: circleId)

        if let channel = activeChannels.removeValue(forKey: circleId) {
            Task { await teardownChannel(channel) }
        }
    }

    private func insertCircle(
        _ circle: PrayerCircle,
        creatorMembershipId: UUID,
        userId: UUID
    ) async throws {
        struct CircleInsert: Encodable {
            let id: UUID
            let name: String
            let inviteCode: String
            let coverPaletteIndex: Int
            let createdBy: UUID

            enum CodingKeys: String, CodingKey {
                case id, name
                case inviteCode = "invite_code"
                case coverPaletteIndex = "cover_palette_index"
                case createdBy = "created_by"
            }
        }

        struct MembershipInsert: Encodable {
            let id: UUID
            let circleId: UUID
            let userId: UUID
            let displayName: String
            let avatarHue: Double

            enum CodingKeys: String, CodingKey {
                case id
                case circleId = "circle_id"
                case userId = "user_id"
                case displayName = "display_name"
                case avatarHue = "avatar_hue"
            }
        }

        let displayName = AuthManager.shared.displayName
        let avatarHue = PrayerCircleStore.shared.currentMember?.avatarHue ?? Double.random(in: 0...1)

        try await SupabaseManager.client
            .from("prayer_circles")
            .upsert(
                CircleInsert(
                    id: circle.id,
                    name: circle.name,
                    inviteCode: circle.inviteCode,
                    coverPaletteIndex: circle.coverPaletteIndex,
                    createdBy: userId
                ),
                onConflict: "id"
            )
            .execute()

        try await SupabaseManager.client
            .from("circle_memberships")
            .upsert(
                MembershipInsert(
                    id: creatorMembershipId,
                    circleId: circle.id,
                    userId: userId,
                    displayName: displayName,
                    avatarHue: avatarHue
                ),
                onConflict: "id"
            )
            .execute()
    }

    private func insertPost(_ post: CirclePost) async throws {
        struct PostInsert: Encodable {
            let id: UUID
            let circleId: UUID
            let authorMembershipId: UUID
            let authorName: String
            let isAnonymous: Bool
            let kind: String
            let text: String
            let focusTag: String?
            let sourceNoteId: UUID?
            let verseReference: String?
            let challengeId: UUID?
            let prayingMemberIds: [UUID]
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case circleId = "circle_id"
                case authorMembershipId = "author_membership_id"
                case authorName = "author_name"
                case isAnonymous = "is_anonymous"
                case kind, text
                case focusTag = "focus_tag"
                case sourceNoteId = "source_note_id"
                case verseReference = "verse_reference"
                case challengeId = "challenge_id"
                case prayingMemberIds = "praying_member_ids"
                case createdAt = "created_at"
            }
        }

        try await SupabaseManager.client
            .from("circle_posts")
            .upsert(
                PostInsert(
                    id: post.id,
                    circleId: post.circleId,
                    authorMembershipId: post.authorId,
                    authorName: post.authorName,
                    isAnonymous: post.isAnonymous,
                    kind: post.kind.rawValue,
                    text: post.text,
                    focusTag: post.focusTag,
                    sourceNoteId: post.sourceNoteId,
                    verseReference: post.verseReference,
                    challengeId: post.challengeId,
                    prayingMemberIds: post.prayingMemberIds,
                    createdAt: post.createdAt
                ),
                onConflict: "id"
            )
            .execute()
    }

    private func insertChallenge(_ challenge: CircleChallenge) async throws {
        struct ChallengeInsert: Encodable {
            let id: UUID
            let circleId: UUID
            let title: String
            let prompt: String
            let verseReference: String?
            let kind: String
            let startsAt: Date
            let endsAt: Date
            let createdBy: UUID
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case circleId = "circle_id"
                case title, prompt
                case verseReference = "verse_reference"
                case kind
                case startsAt = "starts_at"
                case endsAt = "ends_at"
                case createdBy = "created_by"
                case createdAt = "created_at"
            }
        }

        guard let userId = AuthManager.shared.userId else { return }

        try await SupabaseManager.client
            .from("circle_challenges")
            .upsert(
                ChallengeInsert(
                    id: challenge.id,
                    circleId: challenge.circleId,
                    title: challenge.title,
                    prompt: challenge.prompt,
                    verseReference: challenge.verseReference,
                    kind: challenge.kind.rawValue,
                    startsAt: challenge.startsAt,
                    endsAt: challenge.endsAt,
                    createdBy: userId,
                    createdAt: challenge.createdAt
                ),
                onConflict: "id"
            )
            .execute()
    }

    private func updatePostPrayers(_ post: CirclePost) async throws {
        struct PrayerUpdate: Encodable {
            let prayingMemberIds: [UUID]
            enum CodingKeys: String, CodingKey {
                case prayingMemberIds = "praying_member_ids"
            }
        }

        try await SupabaseManager.client
            .from("circle_posts")
            .update(PrayerUpdate(prayingMemberIds: post.prayingMemberIds))
            .eq("id", value: post.id.uuidString)
            .execute()
    }

    private func insertEncouragement(
        _ encouragement: CircleEncouragement,
        postId: UUID,
        authorMembershipId: UUID
    ) async throws {
        struct EncouragementInsert: Encodable {
            let id: UUID
            let postId: UUID
            let authorMembershipId: UUID
            let authorName: String
            let text: String
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case id
                case postId = "post_id"
                case authorMembershipId = "author_membership_id"
                case authorName = "author_name"
                case text
                case createdAt = "created_at"
            }
        }

        try await SupabaseManager.client
            .from("circle_encouragements")
            .upsert(
                EncouragementInsert(
                    id: encouragement.id,
                    postId: postId,
                    authorMembershipId: authorMembershipId,
                    authorName: encouragement.authorName,
                    text: encouragement.text,
                    createdAt: encouragement.createdAt
                ),
                onConflict: "id"
            )
            .execute()
    }
}
