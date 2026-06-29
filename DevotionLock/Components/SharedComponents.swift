//
//  SharedComponents.swift
//  test1
//

import SwiftUI

struct ConversationCard: View {
    let conversation: Conversation
    var onTap: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(conversation.tag)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(DevotionTheme.sage.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DevotionTheme.sage.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DevotionTheme.sage.opacity(0.2), lineWidth: 0.5))

                    Text(conversation.timeAgo)
                        .font(ABY.Font.caption)
                        .foregroundStyle(AppTheme.textTertiary)

                    Spacer()

                    Text(conversation.duration)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Text(conversation.title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(conversation.preview)
                    .font(ABY.Font.body)
                    .foregroundStyle(AppTheme.textTertiary.opacity(1.15))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .darkGlass(cornerRadius: 16)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(AppTheme.springGentle) {
                appeared = true
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.springSnappy, value: configuration.isPressed)
    }
}

struct SearchBar: View {
    var placeholder: String = "Search Devotions"
    @Binding var text: String
    var autofocus: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(ABY.Font.bodyMedium)
                .foregroundStyle(AppTheme.textTertiary)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppTheme.textTertiary))
                .font(ABY.Font.body)
                .foregroundStyle(AppTheme.textPrimary)
                .focused($focused)
            if !text.isEmpty {
                Button {
                    withAnimation(AppTheme.springSnappy) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .darkGlass(cornerRadius: 14)
        .onAppear {
            if autofocus { focused = true }
        }
    }
}

struct FilterIconButton: View {
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(ABY.Font.bodyMedium)
            .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            .frame(width: 40, height: 40)
            .darkGlass(cornerRadius: 12)
    }
}

/// Orbiting dots around a centered cross — the sacred mark on the dynamic orb.
struct DotPatternIcon: View {
    var dotColor: Color = .black.opacity(0.75)
    var rotationDuration: Double = 20
    @State private var rotation: Double = 0

    var body: some View {
        Canvas { context, size in
            drawDots(in: &context, size: size, rotation: rotation)
        }
        .onAppear {
            withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .onChange(of: rotationDuration) { _, duration in
            rotation = 0
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    private func drawDots(in context: inout GraphicsContext, size: CGSize, rotation: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let canvasRadius = min(size.width, size.height) / 2
        let orbitRadius = canvasRadius * 0.88
        let dotCount = 12
        let dotRadius = canvasRadius * 0.075
        let rotationRadians = CGFloat(rotation * .pi / 180)

        for index in 0..<dotCount {
            let angle = (CGFloat(index) / CGFloat(dotCount)) * 2 * .pi - .pi / 2 + rotationRadians
            let x = center.x + cos(angle) * orbitRadius
            let y = center.y + sin(angle) * orbitRadius
            let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(dotColor))
        }

        drawCenterCross(in: &context, center: center, canvasRadius: canvasRadius)
    }

    private func drawCenterCross(in context: inout GraphicsContext, center: CGPoint, canvasRadius: CGFloat) {
        let armHalfLength = canvasRadius * 0.26
        let thickness = canvasRadius * 0.058
        let corner = thickness / 2

        let vertical = CGRect(
            x: center.x - thickness / 2,
            y: center.y - armHalfLength,
            width: thickness,
            height: armHalfLength * 2
        )
        let horizontal = CGRect(
            x: center.x - armHalfLength,
            y: center.y - thickness / 2,
            width: armHalfLength * 2,
            height: thickness
        )

        context.fill(Path(roundedRect: vertical, cornerRadius: corner), with: .color(dotColor))
        context.fill(Path(roundedRect: horizontal, cornerRadius: corner), with: .color(dotColor))
    }
}

struct FadeBottomMask: ViewModifier {
    func body(content: Content) -> some View {
        content.mask(
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 0.65),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

extension View {
    func fadeBottomMask() -> some View {
        modifier(FadeBottomMask())
    }
}
