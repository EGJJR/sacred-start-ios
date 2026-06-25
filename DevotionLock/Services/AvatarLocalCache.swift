//
//  AvatarLocalCache.swift
//  DevotionLock
//

import Foundation

enum AvatarLocalCache {
    private static func fileURL(for userId: UUID) -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar-\(userId.uuidString.lowercased()).jpg")
    }

    static func save(_ data: Data, for userId: UUID) {
        try? data.write(to: fileURL(for: userId), options: .atomic)
    }

    static func load(for userId: UUID) -> Data? {
        let url = fileURL(for: userId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func remove(for userId: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: userId))
    }
}
