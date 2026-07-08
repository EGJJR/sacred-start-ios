//
//  ABYFadingScrollHeader.swift
//  DevotionLock
//
//  Scroll-linked fading header pattern. As the user scrolls, the inline large
//  title fades out and a compact frosted sticky bar fades in at the top.
//
//  Mobbin refs (large title collapse to compact frosted bar on scroll):
//  - Apple News+ Leaderboards: https://mobbin.com/screens/55b3c969-5c59-412c-8415-f81fbb71111a
//  - NYTimes article: https://mobbin.com/screens/0fb385af-382d-4ef4-b26f-64cf3bb0d0ca
//  - Play read view: https://mobbin.com/screens/b64ef9f1-1e6c-4312-893f-747a1c1a0c88
//  - Instagram feed: https://mobbin.com/screens/2e470413-512c-463c-9af3-1c79d3762337
//  - Swarm profile: https://mobbin.com/screens/84bc253e-f9f1-4888-a58c-b77d30fae73a
//

import SwiftUI

/// Scroll container that renders a standard `ABYScreenHeader` at the top of its
/// content and cross-fades it with a compact frosted title bar as scroll offset
/// crosses a threshold.
struct ABYFadingHeaderScrollView<Trailing: View, Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var showDot: Bool = false
    var bottomPadding: CGFloat = 120
    var showsIndicators: Bool = false
    var inlineTopPadding: CGFloat = 12
    var inlineBottomPadding: CGFloat = 16
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    var body: some View {
        ABYCustomFadingHeaderScrollView(
            compactTitle: title,
            showDotInCompact: showDot,
            bottomPadding: bottomPadding,
            showsIndicators: showsIndicators,
            inlineTopPadding: inlineTopPadding,
            inlineBottomPadding: inlineBottomPadding,
            inlineHeader: {
                ABYScreenHeader(
                    title: title,
                    showDot: showDot,
                    subtitle: subtitle,
                    trailing: trailing
                )
            },
            compactTrailing: trailing,
            content: content
        )
    }
}

/// Scroll container that renders a caller-provided inline header and cross-fades
/// it with a compact frosted title bar carrying `compactTitle` and `compactTrailing`.
/// Use when the standard `ABYScreenHeader` layout doesn't fit (e.g., timeline
/// screens with a category kicker above the section title).
struct ABYCustomFadingHeaderScrollView<InlineHeader: View, CompactTrailing: View, Content: View>: View {
    var compactTitle: String
    var showDotInCompact: Bool = false
    var bottomPadding: CGFloat = 120
    var showsIndicators: Bool = false
    var inlineHorizontalPadding: CGFloat = ABY.Spacing.screen
    var inlineTopPadding: CGFloat = 12
    var inlineBottomPadding: CGFloat = 16
    @ViewBuilder let inlineHeader: () -> InlineHeader
    @ViewBuilder let compactTrailing: () -> CompactTrailing
    @ViewBuilder let content: () -> Content

    @State private var scrollY: CGFloat = 0

    private let fadeStart: CGFloat = 8
    private let fadeEnd: CGFloat = 64

    private var progress: CGFloat {
        let range = fadeEnd - fadeStart
        guard range > 0 else { return 0 }
        return min(max((scrollY - fadeStart) / range, 0), 1)
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            VStack(alignment: .leading, spacing: 0) {
                inlineHeader()
                    .padding(.horizontal, inlineHorizontalPadding)
                    .padding(.top, inlineTopPadding)
                    .padding(.bottom, inlineBottomPadding)
                    .opacity(Double(1 - progress))
                    .offset(y: -12 * progress)
                    .allowsHitTesting(progress < 0.5)

                content()
            }
            .padding(.bottom, bottomPadding)
        }
        .abyTransparentScroll()
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { _, newValue in
            if abs(newValue - scrollY) > 0.5 { scrollY = newValue }
        }
        .overlay(alignment: .top) {
            ABYFadingCompactHeaderBar(
                title: compactTitle,
                showDot: showDotInCompact,
                trailing: compactTrailing
            )
            .opacity(Double(progress))
            .allowsHitTesting(progress > 0.5)
        }
    }
}

/// Compact frosted title bar used by both `ABYFadingHeaderScrollView` variants.
/// Extends its frosted material into the top safe area so it reads as a native
/// navigation surface behind the status bar.
struct ABYFadingCompactHeaderBar<Trailing: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    var showDot: Bool = false
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                if showDot {
                    Circle()
                        .fill(ABY.Color.accentDot)
                        .frame(width: 6, height: 6)
                        .offset(y: 1)
                }
            }

            Spacer(minLength: 12)

            trailing()
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) {
            ABYFadingCompactBarSurface()
                .ignoresSafeArea(edges: .top)
        }
    }
}

private struct ABYFadingCompactBarSurface: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(palette.navBarFill)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(palette.divider.opacity(palette.isNight ? 0.45 : 0.55))
                    .frame(height: 0.5)
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.22 : 0.04), radius: 10, y: 4)
    }
}
