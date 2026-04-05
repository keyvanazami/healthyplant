import SwiftUI

struct CactusAnimationView: View {
    @State private var breathing = false
    @State private var glowPulse = false
    @State private var swaying = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom drawn cactus
            CactusShape()
                .scaleEffect(breathing ? 1.02 : 0.98)
                .rotationEffect(.degrees(swaying ? 2.5 : -2.5), anchor: .bottom)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: breathing
                )
                .animation(
                    .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                    value: swaying
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
            swaying = true
        }
        .animation(
            .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
            value: glowPulse
        )
    }
}

// MARK: - Custom Cactus Drawing (Multi-Branch Saguaro)

struct CactusShape: View {
    private let cactusGradient = Gradient(colors: [
        Color(red: 0.25, green: 0.72, blue: 0.35),
        Color(red: 0.12, green: 0.55, blue: 0.22),
        Color(red: 0.06, green: 0.38, blue: 0.14),
    ])

    var body: some View {
        Canvas { context, size in
            let midX: CGFloat = size.width / 2
            let baseY: CGFloat = size.height
            let w: CGFloat = 30
            let trunkH: CGFloat = baseY * 0.88
            let trunkTop: CGFloat = baseY - trunkH

            // Shadow
            context.drawLayer { ctx in
                ctx.addFilter(.shadow(color: Color.green.opacity(0.25), radius: 10, y: 5))
                let r = CGRect(x: midX - w/2, y: trunkTop, width: w, height: trunkH)
                ctx.fill(RoundedRectangle(cornerRadius: w/2).path(in: r), with: .color(.clear))
            }

            // Main trunk
            drawLimb(in: &context, rect: CGRect(x: midX - w/2, y: trunkTop, width: w, height: trunkH))

            // Left arm
            let lJoinY: CGFloat = baseY - trunkH * 0.55
            let lArmX: CGFloat = midX - w * 1.8
            let lArmH: CGFloat = trunkH * 0.35
            drawConnector(in: &context, fromX: midX - w/2, toX: lArmX + w/2, y: lJoinY, thickness: w * 0.85)
            drawLimb(in: &context, rect: CGRect(x: lArmX, y: lJoinY - lArmH, width: w * 0.85, height: lArmH + w/2))

            // Right arm
            let rJoinY: CGFloat = baseY - trunkH * 0.7
            let rArmX: CGFloat = midX + w * 1.1
            let rArmH: CGFloat = trunkH * 0.25
            drawConnector(in: &context, fromX: midX + w/2, toX: rArmX, y: rJoinY, thickness: w * 0.75)
            drawLimb(in: &context, rect: CGRect(x: rArmX, y: rJoinY - rArmH, width: w * 0.75, height: rArmH + w/2))

            // Small right nub
            let nJoinY: CGFloat = baseY - trunkH * 0.35
            let nX: CGFloat = midX + w * 0.9
            let nH: CGFloat = trunkH * 0.12
            drawConnector(in: &context, fromX: midX + w/2, toX: nX, y: nJoinY, thickness: w * 0.6)
            drawLimb(in: &context, rect: CGRect(x: nX, y: nJoinY - nH, width: w * 0.6, height: nH + w/2))

            // Spines
            drawSpines(in: &context, midX: midX, w: w, trunkTop: trunkTop, trunkH: trunkH,
                       lArmX: lArmX, lJoinY: lJoinY, lArmH: lArmH,
                       rArmX: rArmX, rJoinY: rJoinY, rArmH: rArmH)

            // Flowers
            drawFlower(in: &context, center: CGPoint(x: midX, y: trunkTop + 6), petalCount: 6, petalSize: 9, petalColor: .pink)
            drawFlower(in: &context, center: CGPoint(x: lArmX + w * 0.42, y: lJoinY - lArmH + 8), petalCount: 4, petalSize: 6, petalColor: .orange)
        }
    }

    private func drawLimb(in context: inout GraphicsContext, rect: CGRect) {
        let path = RoundedRectangle(cornerRadius: rect.width / 2).path(in: rect)
        context.fill(path, with: .linearGradient(
            cactusGradient,
            startPoint: CGPoint(x: rect.midX, y: rect.minY),
            endPoint: CGPoint(x: rect.midX, y: rect.maxY)
        ))
        let lineColor: Color = .white.opacity(0.1)
        for off: CGFloat in [-5, 0, 5] {
            var line = Path()
            line.move(to: CGPoint(x: rect.midX + off, y: rect.minY + rect.width / 2))
            line.addLine(to: CGPoint(x: rect.midX + off, y: rect.maxY - rect.width / 2))
            context.stroke(line, with: .color(lineColor), lineWidth: 0.8)
        }
    }

    private func drawConnector(in context: inout GraphicsContext, fromX: CGFloat, toX: CGFloat, y: CGFloat, thickness: CGFloat) {
        let rect = CGRect(x: min(fromX, toX), y: y - thickness / 2, width: abs(toX - fromX), height: thickness)
        let path = RoundedRectangle(cornerRadius: thickness / 2).path(in: rect)
        context.fill(path, with: .linearGradient(
            cactusGradient,
            startPoint: CGPoint(x: rect.minX, y: rect.midY),
            endPoint: CGPoint(x: rect.maxX, y: rect.midY)
        ))
    }

    private func drawSpines(in context: inout GraphicsContext, midX: CGFloat, w: CGFloat,
                            trunkTop: CGFloat, trunkH: CGFloat,
                            lArmX: CGFloat, lJoinY: CGFloat, lArmH: CGFloat,
                            rArmX: CGFloat, rJoinY: CGFloat, rArmH: CGFloat) {
        let spineColor: Color = .white.opacity(0.35)
        let positions: [(CGFloat, CGFloat)] = [
            (midX - w/2 - 2, trunkTop + trunkH * 0.15),
            (midX + w/2 + 2, trunkTop + trunkH * 0.1),
            (midX - w/2 - 2, trunkTop + trunkH * 0.35),
            (midX + w/2 + 2, trunkTop + trunkH * 0.5),
            (midX - w/2 - 2, trunkTop + trunkH * 0.65),
            (midX + w/2 + 2, trunkTop + trunkH * 0.8),
            (lArmX - 2, lJoinY - lArmH * 0.4),
            (lArmX + w * 0.85 + 2, lJoinY - lArmH * 0.6),
            (rArmX - 2, rJoinY - rArmH * 0.5),
            (rArmX + w * 0.75 + 2, rJoinY - rArmH * 0.3),
        ]
        for (sx, sy) in positions {
            let dot = Circle().path(in: CGRect(x: sx - 2, y: sy - 2, width: 4, height: 4))
            context.fill(dot, with: .color(spineColor))
        }
    }

    private func drawFlower(in context: inout GraphicsContext, center: CGPoint, petalCount: Int, petalSize: CGFloat, petalColor: Color) {
        let r = petalSize / 2.0
        for i in 0..<petalCount {
            let angle = Double(i) * (2.0 * .pi / Double(petalCount)) - .pi / 2
            let px = center.x + cos(angle) * (petalSize * 0.9)
            let py = center.y + sin(angle) * (petalSize * 0.9)
            let petal = Circle().path(in: CGRect(x: px - r, y: py - r, width: petalSize, height: petalSize))
            context.fill(petal, with: .color(petalColor.opacity(0.85)))
        }
        let dot = Circle().path(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
        context.fill(dot, with: .color(.yellow))
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
