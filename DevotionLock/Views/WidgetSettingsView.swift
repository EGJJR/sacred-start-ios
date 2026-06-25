//
//  WidgetSettingsView.swift
//  DevotionLock
//

import SwiftUI

enum WidgetGuideTab: String, CaseIterable, Identifiable {
    case home
    case lock

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: "Home Screen"
        case .lock: "Lock Screen"
        }
    }
}

struct WidgetSettingsView: View {
    @State private var tab: WidgetGuideTab = .home

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Widgets",
                    subtitle: "Keep your streak, verse, and prayer wall on your Home and Lock screens."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 16)

                Picker("Surface", selection: $tab) {
                    ForEach(WidgetGuideTab.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 16)

                widgetPreview
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)

                ABYSectionHeader(title: tab == .home ? "Available widgets" : "Lock screen widgets")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 8)

                ABYSettingsGroup {
                    if tab == .home {
                        widgetRow("Streak", detail: "Small & medium · tap to begin devotion")
                        ABYSettingsDivider()
                        widgetRow("Verse of the Day", detail: "Medium & large · opens Chaplain")
                        ABYSettingsDivider()
                        widgetRow("Prayer Wall", detail: "Add requests & reminders from the widget")
                    } else {
                        widgetRow("Sanctuary ring", detail: "Circular · streak + weekly progress")
                        ABYSettingsDivider()
                        widgetRow("Verse strip", detail: "Rectangular · daily promise with reference")
                        ABYSettingsDivider()
                        widgetRow("Inline status", detail: "Above the clock · streak or verse")
                        ABYSettingsDivider()
                        widgetRow("Live Activity", detail: "Morning devotion & prayer breath in Dynamic Island")
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)

                ABYSectionHeader(title: "How to add")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 12) {
                    instructionStep(1, tab == .home ? "Long-press your Home Screen" : "Long-press your Lock Screen")
                    instructionStep(2, tab == .home ? "Tap Edit → Add Widget" : "Tap Customize → Add Widgets")
                    instructionStep(3, "Search Devotion Lock and choose a widget")
                    instructionStep(4, tab == .home ? "Use + buttons on Prayer Wall to pin prayers" : "Place Sanctuary or Verse near your clock")
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
        }
        .abySettingsBackNavigation()
    }

    private var widgetPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .fill(ABY.Color.surface)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ABY.Color.track)
                    .frame(width: 80, height: 22)
                if tab == .home {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [ABY.Color.meshLilac, ABY.Color.pillPurple.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 130)
                        .overlay {
                            HStack(spacing: 14) {
                                Circle()
                                    .stroke(.white.opacity(0.35), lineWidth: 4)
                                    .frame(width: 56, height: 56)
                                    .overlay {
                                        VStack(spacing: 0) {
                                            Text("3")
                                                .font(ABY.Font.title2)
                                            Text("days")
                                                .font(ABY.Font.microBold)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("LOOK AT YOU GO!")
                                        .font(ABY.Font.microBold)
                                        .foregroundStyle(.white.opacity(0.75))
                                    Text("Begin your devotion")
                                        .font(ABY.Font.bodySemibold)
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                    HStack(spacing: 10) {
                        miniTile(title: "Verse", color: ABY.Color.meshLilac.opacity(0.25))
                        miniTile(title: "Prayer wall", color: ABY.Color.pillOrange.opacity(0.2))
                    }
                } else {
                    Text("9:41")
                        .font(ABY.Font.largeTitle)
                    liveActivityPreviewMock
                    HStack(spacing: 10) {
                        Circle()
                            .stroke(ABY.Color.pillTeal, lineWidth: 3)
                            .frame(width: 44, height: 44)
                            .overlay { Image(systemName: "flame.fill").font(ABY.Font.caption) }
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ABY.Color.meshLilac.opacity(0.2))
                            .frame(height: 44)
                            .overlay {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Be still, and know…")
                                        .font(ABY.Font.caption)
                                        .lineLimit(1)
                                    Text("Psalm 46:10")
                                        .font(ABY.Font.microBold)
                                        .foregroundStyle(ABY.Color.textSecondary)
                                }
                                .padding(.horizontal, 8)
                            }
                    }
                }
            }
            .padding()
        }
        .frame(height: tab == .home ? 280 : 260)
    }

    private var liveActivityPreviewMock: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(ABY.Color.meshLilac.opacity(0.35))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "book.fill")
                            .font(ABY.Font.caption)
                            .foregroundStyle(ABY.Color.pillPurple)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text("2:34")
                        .font(ABY.Font.title2)
                    Text("Today's word")
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textSecondary)
                }
                Spacer()
                Text("3/5")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(ABY.Color.pillPurple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ABY.Color.pillPurple.opacity(0.12))
                    .clipShape(Capsule())
            }
            Capsule()
                .fill(ABY.Color.pillTeal)
                .frame(height: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
            HStack {
                Label("Morning Devotion", systemImage: "sparkles")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.textSecondary)
                Spacer()
                Text("Hang in there")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.textSecondary)
            }
            .padding(.top, 10)
        }
        .padding(12)
        .background(ABY.Color.meshLilac.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func miniTile(title: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(color)
            .frame(height: 56)
            .overlay {
                Text(title)
                    .font(ABY.Font.captionMedium)
            }
    }

    private func widgetRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textPrimary)
            Text(detail)
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func instructionStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(ABY.Color.pillPurple)
                .clipShape(Circle())
            Text(text)
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textPrimary)
        }
    }
}

struct WidgetOnboardingView: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()
            VStack(spacing: 24) {
                Spacer()
                Text("Keep your streak\non track")
                    .font(ABY.Font.title)
                    .multilineTextAlignment(.center)
                Text("Add a widget to see your sanctuary, verse, and prayer wall without opening the app.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                widgetPreviewMock
                    .padding(.horizontal, ABY.Spacing.screen)

                ABYPrimaryButton(title: "See widget options", icon: "square.grid.2x2") {
                    onDismiss()
                }
                .padding(.horizontal, ABY.Spacing.screen)

                Button("Maybe later", action: onDismiss)
                    .font(ABY.Font.callout)
                    .foregroundStyle(ABY.Color.textSecondary)
                Spacer()
            }
        }
        .abyScreen()
    }

    private var widgetPreviewMock: some View {
        RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
            .fill(ABY.Color.surface)
            .frame(height: 200)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ABY.Color.orbSage, ABY.Color.pillTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(24)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3 day streak")
                                .font(ABY.Font.title2)
                                .foregroundStyle(.white)
                            Text("Love this for you!")
                                .font(ABY.Font.callout)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(40)
                    }
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
    }
}
