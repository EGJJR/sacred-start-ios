//
//  MeshLoadingOverlay.swift
//  DevotionLock
//

import SwiftUI

struct MeshLoadingOverlay: View {
    var message = "Opening Scripture…"

    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [ABY.Color.meshLilac, ABY.Color.meshSky, ABY.Color.meshSage.opacity(0.4)],
                                center: .center,
                                startRadius: 8,
                                endRadius: 90
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 24)
                        .scaleEffect(pulse ? 1.08 : 0.92)
                        .opacity(pulse ? 1 : 0.7)

                    ProgressView()
                        .tint(ABY.Color.pillPurple)
                }

                Text(message)
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(ABY.Color.textPrimary)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(ABY.Color.divider, lineWidth: 1)
            }
            .padding(.horizontal, 48)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
