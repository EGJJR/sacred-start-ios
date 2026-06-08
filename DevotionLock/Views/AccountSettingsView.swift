//
//  AccountSettingsView.swift
//  DevotionLock
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
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteFinalConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false
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
                    title: "Edit account",
                    subtitle: "Update your profile photo and username."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24)

                photoSection
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)

                ABYSettingsGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(ABY.Font.footnote)
                            .foregroundStyle(palette.textSecondary)
                            .padding(.horizontal, ABY.Spacing.card)
                            .padding(.top, 14)

                        TextField("Username", text: $usernameDraft)
                            .font(ABY.Font.body)
                            .foregroundStyle(palette.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, ABY.Spacing.card)
                            .padding(.bottom, 4)
                            .onChange(of: usernameDraft) { _, _ in
                                scheduleUsernameCheck()
                            }

                        Text(usernameStatusMessage)
                            .font(ABY.Font.caption)
                            .foregroundStyle(usernameStatusColor)
                            .padding(.horizontal, ABY.Spacing.card)
                            .padding(.bottom, 14)
                    }

                    ABYSettingsDivider()

                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .font(ABY.Font.iconMedium)
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .font(ABY.Font.body)
                                .foregroundStyle(palette.textPrimary)
                            Text(auth.email ?? "—")
                                .font(ABY.Font.footnote)
                                .foregroundStyle(palette.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, ABY.Spacing.card)
                    .padding(.vertical, 14)
                }
                .padding(.horizontal, ABY.Spacing.screen)

                if let localError {
                    Text(localError)
                        .font(ABY.Font.footnote)
                        .foregroundStyle(.red.opacity(0.85))
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 12)
                }

                Button(action: saveChanges) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save changes")
                                .font(ABY.Font.button)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(canSave ? palette.textPrimary : palette.textPrimary.opacity(0.35))
                    .foregroundStyle(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 24)

                Button(action: { showSignOutConfirmation = true }) {
                    HStack {
                        Spacer()
                        if isSigningOut {
                            ProgressView()
                        } else {
                            Text("Sign out")
                                .font(ABY.Font.button)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(palette.surface)
                    .foregroundStyle(palette.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                    .overlay {
                        RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                            .stroke(palette.divider, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sign out")
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 16)

                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        } else {
                            Text("Delete account")
                                .font(ABY.Font.button)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.85))
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
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
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue", role: .destructive) {
                showDeleteFinalConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes your account, journal sync, and profile photo. This cannot be undone.")
        }
        .alert("Are you absolutely sure?", isPresented: $showDeleteFinalConfirmation) {
            Button("Delete account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All of your data will be permanently deleted.")
        }
        .confirmationDialog(
            "Sign out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                Task { await signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can sign back in anytime with your email and password.")
        }
    }

    private var photoSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ProfileAvatarView(
                name: auth.displayName,
                avatarURL: auth.avatarURL,
                size: 96,
                showsEditBadge: true
            )
        }
        .buttonStyle(.plain)
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

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await auth.signOut()
        dismiss()
    }

    private func deleteAccount() {
        Task {
            isDeleting = true
            localError = nil
            defer { isDeleting = false }

            do {
                try await auth.deleteAccount()
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
