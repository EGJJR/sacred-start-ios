//
//  AppShieldManager.swift
//  DevotionLock
//
//  Uses Apple's Screen Time APIs:
//  - FamilyControls / AuthorizationCenter for user consent
//  - FamilyActivityPicker selections (privacy-preserving tokens)
//  - ManagedSettingsStore.shield to block apps until devotion completes
//

import Foundation
import Observation

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings

@Observable
@MainActor
final class AppShieldManager {
    static let shared = AppShieldManager()

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("devotionlock.shield"))

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var lastErrorMessage: String?
    private(set) var isShieldActive = false

    var isAuthorized: Bool { authorizationStatus == .approved }

    var hasSelection: Bool {
        guard let selection = ShieldSelectionStore.load() else { return false }
        return !selection.isEmpty
    }

    var selectionSummary: String {
        ShieldSelectionStore.load()?.summaryLabel ?? "None selected"
    }

    var isAvailable: Bool { true }

    private init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            lastErrorMessage = nil
            syncShieldState()
        } catch {
            lastErrorMessage = friendlyMessage(for: error)
        }
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        ShieldSelectionStore.save(selection)
        syncShieldState()
    }

    /// Applies shields when enabled and devotion is incomplete; clears otherwise.
    func syncShieldState() {
        refreshAuthorizationStatus()

        let shieldEnabled = UserDefaults.standard.object(forKey: "shieldEnabled") as? Bool ?? true
        let devotionComplete = StreakManager.shared.isCompletedToday

        guard shieldEnabled, isAuthorized, !devotionComplete else {
            clearShields()
            return
        }

        guard let selection = ShieldSelectionStore.load(), !selection.isEmpty else {
            clearShields()
            return
        }

        applyShields(selection)
    }

    func unlockForCompletedDevotion() {
        clearShields()
    }

    private func applyShields(_ selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        isShieldActive = true
        lastErrorMessage = nil
    }

    private func clearShields() {
        store.clearAllSettings()
        isShieldActive = false
    }

    private func friendlyMessage(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("cancel") {
            return "Screen Time access is required to shield apps."
        }
        return error.localizedDescription
    }
}

#else

@Observable
@MainActor
final class AppShieldManager {
    static let shared = AppShieldManager()

    private(set) var authorizationStatus: Int = 0
    private(set) var lastErrorMessage: String?
    private(set) var isShieldActive = false

    var isAuthorized: Bool { false }
    var hasSelection: Bool { false }
    var selectionSummary: String { "Unavailable on this platform" }
    var isAvailable: Bool { false }

    func refreshAuthorizationStatus() {}
    func requestAuthorization() async {
        lastErrorMessage = "App shield requires Family Controls on a physical iPhone or iPad."
    }
    func saveSelection(_ selection: Any) {}
    func syncShieldState() {}
    func unlockForCompletedDevotion() {}
}

#endif
