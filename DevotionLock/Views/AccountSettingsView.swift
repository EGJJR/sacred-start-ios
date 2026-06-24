//
//  AccountSettingsView.swift
//  DevotionLock
//
//  Mobbin ABY account editing pattern
//

import PhotosUI
import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.authManager) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var usernameDraft = ""
    @State private var usernameStatus: UsernameStatus = .idle
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSaving = false
    @State private var localError: String?
    @State private var availabilityTask: Task<Void, Never>?

    private enum UsernameStatus: Equatable {
        case idle
        case checking
        case available
        case taken
        case unchanged
        case invalid
    }

    private var normalizedDraft: String? {
        UsernameValidator.normalize(usernameDraft)
    }

    private var hasUsernameChange: Bool {
        guard let normalizedDraft else { return false }
        return normalizedDraft != auth.username
    }

    private var hasPhotoSelected: Bool {
        selectedPhoto != nil
    }

    private var canSave: Bool {
        guard !isSaving else { return false }
        if hasPhotoSelected { return true }
        guard hasUsernameChange else { return false }
        switch usernameStatus {
        case .available, .idle:
            return normalizedDraft != nil
        default:
            return false
        }
    }

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Edit profile",
                    subtitle: "Update your photo and how Sacred Start greets you."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24)

                photoSection
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)

                ABYSectionHeader(title: "Account")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 8)

                ABYSettingsGroup {
                    ABYSettingsTextFieldGroup(
                        label: "Username",
                        text: $usernameDraft,
                        placeholder: "Username",
                        helperText: usernameStatusMessage,
                        helperColor: usernameStatusColor
                    )
                    .onChange(of: usernameDraft) { _, _ in
                        scheduleUsernameCheck()
                    }

                    ABYSettingsDivider()

                    ABYSettingsReadOnlyRow(
                        icon: "envelope",
                        title: "Email",
                        value: auth.email ?? "—"
                    )
                }
                .padding(.horizontal, ABY.Spacing.screen)

                if let localError {
                    Text(localError)
                        .font(ABY.Font.footnote)
                        .foregroundStyle(.red.opacity(0.85))
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 16)
                }

                ABYSettingsPrimaryButton(
                    title: "Save changes",
                    isEnabled: canSave,
                    isLoading: isSaving,
                    action: saveChanges
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign out and delete account are in Settings → Danger zone.")
                        .font(ABY.Font.footnote)
                        .foregroundStyle(palette.textTertiary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { ABYBackToolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            usernameDraft = auth.username ?? ""
            if auth.username != nil {
                usernameStatus = .unchanged
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard item != nil else { return }
            localError = nil
        }
    }

    private var photoSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ProfileAvatarView(
                    name: auth.displayName,
                    avatarURL: auth.avatarURL,
                    size: 96,
                    showsEditBadge: true
                )
            }
            .buttonStyle(.plain)

            Text("Tap to change photo")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
        }
    }

    private var usernameStatusMessage: String {
        switch usernameStatus {
        case .idle:
            "2–30 characters. Letters, numbers, spaces, dots, dashes, underscores."
        case .checking:
            "Checking availability…"
        case .available:
            "Username is available."
        case .taken:
            "That username is already taken."
        case .unchanged:
            "This is your current username."
        case .invalid:
            "Enter a valid username."
        }
    }

    private var usernameStatusColor: Color {
        switch usernameStatus {
        case .available, .unchanged:
            palette.textSecondary
        case .taken, .invalid:
            .red.opacity(0.85)
        case .checking, .idle:
            palette.textTertiary
        }
    }

    private func scheduleUsernameCheck() {
        availabilityTask?.cancel()
        localError = nil

        guard hasUsernameChange else {
            usernameStatus = auth.username == nil ? .idle : .unchanged
            return
        }

        guard let normalizedDraft else {
            usernameStatus = .invalid
            return
        }

        usernameStatus = .checking
        availabilityTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            do {
                let available = try await ProfileRepository.shared.isUsernameAvailable(normalizedDraft)
                guard !Task.isCancelled else { return }
                usernameStatus = available ? .available : .taken
            } catch {
                guard !Task.isCancelled else { return }
                usernameStatus = .idle
            }
        }
    }

    private func saveChanges() {
        Task {
            isSaving = true
            localError = nil
            defer { isSaving = false }

            do {
                if hasUsernameChange, let normalizedDraft {
                    try await auth.updateUsername(normalizedDraft)
                }

                if let selectedPhoto {
                    guard let rawData = try await selectedPhoto.loadTransferable(type: Data.self) else {
                        localError = ProfileError.uploadFailed.localizedDescription
                        return
                    }
                    let uploadData = AvatarImageProcessor.jpegData(from: rawData) ?? rawData
                    try await auth.updateAvatar(data: uploadData, contentType: "image/jpeg")
                    self.selectedPhoto = nil
                }

                dismiss()
            } catch {
                localError = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
            .environment(\.authManager, AuthManager.shared)
    }
}
