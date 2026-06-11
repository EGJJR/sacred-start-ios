//
//  GlassActionBar.swift
//  DevotionLock
//

import SwiftUI

struct GlassActionBarItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let action: () -> Void
}

struct GlassActionBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    let items: [GlassActionBarItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .medium))
                        Text(item.title)
                            .font(ABY.Font.caption)
                    }
                    .foregroundStyle(palette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}
