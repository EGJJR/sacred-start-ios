//
//  DevotionCompletionView.swift
//  DevotionLock
//

import SwiftUI

struct DevotionCompletionView: View {
    let streak: Int
    let mood: String
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var orbScale: CGFloat = 0.6

    var body: some View {
        ZStack {
            ConfettiView(isActive: appeared)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(orbScale)
                    Text("🐣")
                        .font(.system(size: 64))
                        .scaleEffect(appeared ? 1 : 0.5)
                }

                VStack(spacing: 10) {
                    Text("You showed up")
                        .font(ABY.Font.onboardingTitle)
                        .foregroundStyle(ABY.Color.onboardingText)
                    Text("That's what matters most. Your \(mood.lowercased()) morning is logged.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.onboardingTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.22))
                        .symbolEffect(.pulse, options: .repeating, value: appeared)
                    AnimatedStreakNumber(target: streak, color: ABY.Color.onboardingText)
                        .font(ABY.Font.headline)
                    Text("day morning streak")
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.onboardingText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(ABY.Color.glassFill)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(ABY.Color.glassStroke, lineWidth: 1))
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)

                Spacer()

                ABYOnboardingPrimaryButton(title: "Return home", icon: "arrow.right") {
                    DevotionHaptics.light()
                    onContinue()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.springGentle) {
                appeared = true
                orbScale = 1.05
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                orbScale = 1.12
            }
        }
    }
}

#Preview {
    ZStack {
        ABYOnboardingMeshBackground()
        DevotionCompletionView(streak: 6, mood: "Peaceful", onContinue: {})
    }
    .preferredColorScheme(.dark)
}
