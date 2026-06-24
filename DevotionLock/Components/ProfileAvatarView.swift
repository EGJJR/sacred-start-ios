//
//  ProfileAvatarView.swift
//  DevotionLock
//

import SwiftUI

struct ProfileAvatarView: View {
    @Environment(\.sanctuaryPalette) private var palette

    let name: String
    var avatarURL: URL?
    var size: CGFloat = 56
    var showsEditBadge: Bool = false

    private var initials: String {
        UsernameValidator.initials(for: name)
    }

    private var fallbackHue: Double {
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double(hash % 360) / 360.0
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: size, height: size)
                .clipShape(Circle())

            if showsEditBadge {
                Image(systemName: "camera.fill")
                    .font(.system(size: size * 0.18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(size * 0.1)
                    .background(palette.textPrimary)
                    .clipShape(Circle())
                    .offset(x: size * 0.04, y: size * 0.04)
            }
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    initialsAvatar
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(palette.background)
                }
            }
        } else {
            initialsAvatar
        }
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(hue: fallbackHue, saturation: 0.35, brightness: 0.92))
            Text(initials)
                .font(AppFont.font(size: size * 0.34, weight: .semibold))
                .foregroundStyle(palette.textPrimary.opacity(0.85))
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ProfileAvatarView(name: "Grace", size: 72)
        ProfileAvatarView(name: "Morning Seeker", size: 72, showsEditBadge: true)
    }
    .padding()
}
