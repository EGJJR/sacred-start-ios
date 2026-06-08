//
//  ChaplainResourcesViews.swift
//  DevotionLock
//

import SwiftUI

struct ChaplainResourcesSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onReflect: (String) -> Void

    @AppStorage("savedSpiritualResourceIDs") private var savedIDsData = Data()
    @State private var selectedTopic: SpiritualTopic?
    @State private var selectedResource: SpiritualResource?

    private var savedIDs: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: savedIDsData)) ?? []
    }

    private var filteredResources: [SpiritualResource] {
        SpiritualResourceCatalog.filtered(by: selectedTopic)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Promises & passages")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.5)
                Text("Scripture and wisdom for where you are")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            topicFilter

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(filteredResources) { resource in
                        SpiritualResourceCard(
                            resource: resource,
                            isSaved: savedIDs.contains(resource.id)
                        ) {
                            selectedResource = resource
                        } onSave: {
                            toggleSave(resource.id)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .animation(AppTheme.springGentle, value: selectedTopic)
        }
        .sheet(item: $selectedResource) { resource in
            SpiritualResourceDetailView(
                resource: resource,
                isSaved: savedIDs.contains(resource.id),
                onSave: { toggleSave(resource.id) },
                onReflect: {
                    selectedResource = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onReflect(resource.chatPrompt)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    private var topicFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                topicChip(label: "All", topic: nil, isSelected: selectedTopic == nil)
                ForEach(SpiritualTopic.allCases) { topic in
                    topicChip(label: topic.label, topic: topic, isSelected: selectedTopic == topic)
                }
            }
        }
    }

    private func topicChip(label: String, topic: SpiritualTopic?, isSelected: Bool) -> some View {
        Button {
            withAnimation(AppTheme.springSnappy) {
                selectedTopic = topic
            }
        } label: {
            Text(label)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(isSelected ? .white : palette.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule().fill(topic?.tint ?? palette.textPrimary)
                    } else {
                        Capsule().fill(palette.surface)
                    }
                }
                .overlay {
                    Capsule().stroke(isSelected ? Color.clear : palette.divider, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func toggleSave(_ id: String) {
        var ids = savedIDs
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
            DevotionHaptics.light()
        }
        savedIDsData = (try? JSONEncoder().encode(ids)) ?? Data()
    }
}

struct SpiritualResourceCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let resource: SpiritualResource
    var isSaved: Bool
    var onOpen: () -> Void
    var onSave: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label(resource.kind.label, systemImage: resource.kind.icon)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Button(action: onSave) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 16)

                Text("“")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white.opacity(0.35))
                    .offset(y: 4)

                Text(resource.text)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text(resource.reference)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(.white.opacity(0.95))
                    if let author = resource.author {
                        Text(author)
                            .font(ABY.Font.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .italic()
                    }
                }
            }
            .padding(18)
            .frame(width: 280, height: 300, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: resource.topic.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: resource.topic.tint.opacity(0.25), radius: 16, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SpiritualResourceDetailView: View {
    @Environment(\.sanctuaryPalette) private var palette
    let resource: SpiritualResource
    var isSaved: Bool
    var onSave: () -> Void
    var onReflect: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        kindBadge
                        Spacer()
                        Button(action: onSave) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(ABY.Font.iconMedium)
                                .foregroundStyle(palette.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(palette.surface)
                                .clipShape(Circle())
                        }
                        Button {
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(ABY.Font.iconMedium)
                                .foregroundStyle(palette.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(palette.surface)
                                .clipShape(Circle())
                        }
                    }

                    VStack(spacing: 20) {
                        Text("“")
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .foregroundStyle(resource.topic.tint.opacity(0.45))

                        Text(resource.text)
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .foregroundStyle(palette.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)

                        Rectangle()
                            .fill(palette.divider)
                            .frame(width: 40, height: 1)

                        VStack(spacing: 4) {
                            Text(resource.reference)
                                .font(ABY.Font.headline)
                                .foregroundStyle(palette.textPrimary)
                            if let author = resource.author {
                                Text(author)
                                    .font(ABY.Font.callout)
                                    .foregroundStyle(palette.textSecondary)
                                    .italic()
                            }
                        }

                        Text(resource.topic.label)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(resource.topic.tint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(resource.topic.tint.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 12, y: 4)

                    VStack(spacing: 12) {
                        ABYPrimaryButton(title: "Reflect with Chaplain", icon: "ellipsis.bubble") {
                            onReflect()
                        }
                        Button("Close") { dismiss() }
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .abyScreen()
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
    }

    private var kindBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: resource.kind.icon)
            Text(resource.kind.label)
        }
        .font(ABY.Font.captionMedium)
        .foregroundStyle(resource.topic.tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(resource.topic.tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private var shareText: String {
        if let author = resource.author {
            return "\(resource.text)\n\n— \(author), \(resource.reference)"
        }
        return "\(resource.text)\n\n— \(resource.reference)"
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ChaplainResourcesSection(onReflect: { _ in })
        .padding()
}
