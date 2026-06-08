//
//  ShieldSelectionStore.swift
//  DevotionLock
//

import Foundation

#if canImport(FamilyControls)
import FamilyControls

enum ShieldSelectionStore {
    private static let key = "shieldActivitySelection"

    static func save(_ selection: FamilyActivitySelection) {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier),
              let data = try? PropertyListEncoder().encode(selection)
        else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> FamilyActivitySelection? {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier),
              let data = defaults.data(forKey: key)
        else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func clear() {
        UserDefaults(suiteName: DevotionAppGroup.identifier)?
            .removeObject(forKey: key)
    }
}

extension FamilyActivitySelection {
    var isEmpty: Bool {
        applicationTokens.isEmpty && categoryTokens.isEmpty && webDomainTokens.isEmpty
    }

    var summaryLabel: String {
        var parts: [String] = []
        let appCount = applicationTokens.count
        let categoryCount = categoryTokens.count
        let webCount = webDomainTokens.count

        if appCount > 0 {
            parts.append("\(appCount) app\(appCount == 1 ? "" : "s")")
        }
        if categoryCount > 0 {
            parts.append("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")")
        }
        if webCount > 0 {
            parts.append("\(webCount) site\(webCount == 1 ? "" : "s")")
        }
        return parts.isEmpty ? "None selected" : parts.joined(separator: ", ")
    }
}
#endif
