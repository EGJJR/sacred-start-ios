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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DevotionTheme.sage.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DevotionTheme.sage.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DevotionTheme.sage.opacity(0.2), lineWidth: 0.5))

                    Text(conversation.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)

                    Spacer()

                    Text(conversation.duration)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Text(conversation.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(conversation.preview)
                    .font(.system(size: 15))
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
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppTheme.textTertiary))
                .font(.system(size: 15))
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
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            .frame(width: 40, height: 40)
            .darkGlass(cornerRadius: 12)
    }
}

struct DotPatternIcon: View {
    var dotColor: Color = .black.opacity(0.75)
    @State private var rotation: Double = 0

    var body: some View {
        Canvas { context, size in
            drawDots(in: &context, size: size, rotation: rotation)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    private func drawDots(in context: inout GraphicsContext, size: CGSize, rotation: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius: CGFloat = 10
        let dotCount = 12
        let dotRadius: CGFloat = 1.8
        let rotationRadians = CGFloat(rotation * .pi / 180)

        for index in 0..<dotCount {
            let angle = (CGFloat(index) / CGFloat(dotCount)) * 2 * .pi - .pi / 2 + rotationRadians
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(dotColor))
        }

        let innerRect = CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)
        context.fill(Path(ellipseIn: innerRect), with: .color(dotColor))
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
