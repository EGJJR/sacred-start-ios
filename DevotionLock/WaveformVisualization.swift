//
//  WaveformVisualization.swift
//  test1
//

import SwiftUI

struct WaveformVisualization: View {
    var intensity: CGFloat = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let midY = size.height / 2
                let width = size.width

                var path = Path()
                let points = 120
                for i in 0...points {
                    let x = width * CGFloat(i) / CGFloat(points)
                    let normalized = CGFloat(i) / CGFloat(points)
                    let envelope = sin(normalized * .pi)
                    let wave1 = sin(normalized * 14 * .pi + CGFloat(t) * 3.2) * 0.55
                    let wave2 = sin(normalized * 22 * .pi - CGFloat(t) * 2.4) * 0.35
                    let wave3 = sin(normalized * 8 * .pi + CGFloat(t) * 1.8) * 0.25
                    let amplitude = (wave1 + wave2 + wave3) * envelope * intensity
                    let y = midY + amplitude * (size.height * 0.42)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                context.addFilter(.blur(radius: 8))
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            DevotionTheme.teal,
                            DevotionTheme.sage,
                            Color.white.opacity(0.8),
                            DevotionTheme.teal.opacity(0.8),
                        ]),
                        startPoint: CGPoint(x: 0, y: midY),
                        endPoint: CGPoint(x: width, y: midY)
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                )

                context.addFilter(.blur(radius: 14))
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            DevotionTheme.teal.opacity(0.6),
                            DevotionTheme.sage.opacity(0.6),
                            Color.white.opacity(0.5),
                        ]),
                        startPoint: CGPoint(x: 0, y: midY),
                        endPoint: CGPoint(x: width, y: midY)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(height: 80)
    }
}

struct MiniWaveformIcon: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    let height = 8 + abs(sin(t * 4 + Double(i) * 1.2)) * 10
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 2, height: height)
                }
            }
        }
        .frame(height: 18)
    }
}

struct LiveTranscriptionText: View {
    @State private var highlightPulse = false

    var body: some View {
        Text(attributedTranscript)
            .font(ABY.Font.title2)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .overlay {
                Text("this day before you,")
                    .font(ABY.Font.title2)
                    .foregroundStyle(.clear)
                    .background(
                        LinearGradient(
                            colors: [
                                DevotionTheme.sage.opacity(highlightPulse ? 0.35 : 0),
                                DevotionTheme.teal.opacity(highlightPulse ? 0.25 : 0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .blur(radius: 8)
                        .padding(.horizontal, -4)
                    )
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    highlightPulse = true
                }
            }
    }

    private var attributedTranscript: AttributedString {
        var text = AttributedString("Lord, I bring ")
        text.foregroundColor = .white.opacity(0.75)

        var highlight = AttributedString("this day before you,")
        highlight.foregroundColor = .white
        highlight.inlinePresentationIntent = .stronglyEmphasized

        var trailing = AttributedString(" and ask for your peace...")
        trailing.foregroundColor = .white.opacity(0.35)

        text.append(highlight)
        text.append(trailing)
        return text
    }
}

#Preview {
    ZStack {
        Color.black
        VStack {
            WaveformVisualization()
            LiveTranscriptionText()
        }
        .padding()
    }
}
