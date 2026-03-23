import SwiftUI

struct CactusAnimationView: View {
    @State private var breathing = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom drawn cactus
            CactusShape()
                .scaleEffect(breathing ? 1.02 : 0.98)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: breathing
                )
                .frame(width: 140, height: 200)

            // Vase / pot
            ZStack {
                // Pot body
                PotShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.accent.opacity(0.4),
                                Theme.accent.opacity(0.15),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 110, height: 65)
                    .overlay(
                        PotShape()
                            .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                    )
                    .shadow(color: Theme.accent.opacity(glowPulse ? 0.4 : 0.1), radius: glowPulse ? 12 : 4)

                Text("Healthy Plant")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
                    .offset(y: 4)
            }
            .offset(y: -6)
        }
        .onAppear {
            breathing = true
            glowPulse = true
        }
        .animation(
            .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
            value: glowPulse
        )
    }
}

// MARK: - Custom Cactus Drawing

struct CactusShape: View {
    var body: some View {
        Canvas { context, size in
            let midX = size.width / 2
            let baseY = size.height

            // Main body
            let bodyWidth: CGFloat = 36
            let bodyHeight: CGFloat = size.height * 0.75
            let bodyRect = CGRect(
                x: midX - bodyWidth / 2,
                y: baseY - bodyHeight,
                width: bodyWidth,
                height: bodyHeight
            )
            let bodyPath = RoundedRectangle(cornerRadius: bodyWidth / 2)
                .path(in: bodyRect)

            // Gradient fill
            let gradient = Gradient(colors: [
                Color(red: 0.2, green: 0.7, blue: 0.3),
                Color(red: 0.1, green: 0.55, blue: 0.2),
                Color(red: 0.05, green: 0.4, blue: 0.15),
            ])

            // Draw shadow
            context.drawLayer { ctx in
                ctx.addFilter(.shadow(color: Color.green.opacity(0.3), radius: 8, y: 4))
                ctx.fill(bodyPath, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: midX, y: bodyRect.minY),
                    endPoint: CGPoint(x: midX, y: baseY)
                ))
            }

            // Draw body
            context.fill(bodyPath, with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: midX, y: bodyRect.minY),
                endPoint: CGPoint(x: midX, y: baseY)
            ))

            // Vertical highlight lines on body
            let lineColor = Color.white.opacity(0.12)
            for offset: CGFloat in [-6, 0, 6] {
                var line = Path()
                line.move(to: CGPoint(x: midX + offset, y: bodyRect.minY + 20))
                line.addLine(to: CGPoint(x: midX + offset, y: baseY - 10))
                context.stroke(line, with: .color(lineColor), lineWidth: 1)
            }

            // Small spines / dots
            let spineColor = Color.white.opacity(0.4)
            let spinePositions: [(CGFloat, CGFloat)] = [
                (midX - 14, baseY - bodyHeight * 0.8),
                (midX + 14, baseY - bodyHeight * 0.75),
                (midX - 14, baseY - bodyHeight * 0.6),
                (midX + 14, baseY - bodyHeight * 0.55),
                (midX - 14, baseY - bodyHeight * 0.4),
                (midX + 14, baseY - bodyHeight * 0.35),
                (midX, baseY - bodyHeight * 0.92),
            ]
            for (sx, sy) in spinePositions {
                let dot = Circle().path(in: CGRect(x: sx - 1.5, y: sy - 1.5, width: 3, height: 3))
                context.fill(dot, with: .color(spineColor))
            }

            // Small flower on top
            let flowerCenter = CGPoint(x: midX + 2, y: bodyRect.minY + 5)
            for i in 0..<5 {
                let angle = Double(i) * (2 * .pi / 5) - .pi / 2
                let petalX = flowerCenter.x + cos(angle) * 7
                let petalY = flowerCenter.y + sin(angle) * 7
                let petal = Circle().path(in: CGRect(x: petalX - 4, y: petalY - 4, width: 8, height: 8))
                context.fill(petal, with: .color(Color.pink.opacity(0.8)))
            }
            let center = Circle().path(in: CGRect(x: flowerCenter.x - 3, y: flowerCenter.y - 3, width: 6, height: 6))
            context.fill(center, with: .color(Color.yellow))
        }
    }

}

// MARK: - Pot Shape

struct PotShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Rim
        let rimHeight: CGFloat = 12
        let rimRect = CGRect(x: inset.minX, y: inset.minY, width: inset.width, height: rimHeight)
        path.addRoundedRect(in: rimRect, cornerSize: CGSize(width: 4, height: 4))

        // Tapered body
        let topWidth = inset.width * 0.92
        let bottomWidth = inset.width * 0.65
        let bodyTop = inset.minY + rimHeight
        let bodyBottom = inset.maxY

        path.move(to: CGPoint(x: inset.midX - topWidth / 2, y: bodyTop))
        path.addLine(to: CGPoint(x: inset.midX - bottomWidth / 2, y: bodyBottom - 8))
        path.addQuadCurve(
            to: CGPoint(x: inset.midX + bottomWidth / 2, y: bodyBottom - 8),
            control: CGPoint(x: inset.midX, y: bodyBottom + 4)
        )
        path.addLine(to: CGPoint(x: inset.midX + topWidth / 2, y: bodyTop))
        path.closeSubpath()

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CactusAnimationView()
    }
}
