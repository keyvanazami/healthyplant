import SwiftUI

// MARK: - Plant Animation Host

/// Randomly picks one of 22 plant illustrations each time the view is created (i.e. each app launch).
struct PlantAnimationView: View {
    @State private var breathing = false
    @State private var swaying = false
    @State private var glowPulse = false
    @State private var plantIndex = Int.random(in: 0..<22)

    var body: some View {
        VStack(spacing: 0) {
            plantShape
                .scaleEffect(breathing ? 1.02 : 0.98)
                .rotationEffect(.degrees(swaying ? 2.5 : -2.5), anchor: .bottom)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathing)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: swaying)
                .frame(width: 140, height: 200)

            ZStack {
                PotShape()
                    .fill(LinearGradient(
                        colors: [Theme.accent.opacity(0.4), Theme.accent.opacity(0.15)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 110, height: 65)
                    .overlay(PotShape().strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth))
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
            swaying = true
            glowPulse = true
        }
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: glowPulse)
    }

    @ViewBuilder
    private var plantShape: some View {
        switch plantIndex {
        case 0:  CactusShape()
        case 1:  MonsteraShape()
        case 2:  SunflowerShape()
        case 3:  FernShape()
        case 4:  TulipShape()
        case 5:  BambooShape()
        case 6:  BonsaiShape()
        case 7:  SucculentShape()
        case 8:  LavenderShape()
        case 9:  SnakePlantShape()
        case 10: FiddleLeafShape()
        case 11: AloeShape()
        case 12: RoseShape()
        case 13: DaisyShape()
        case 14: CherryBlossomShape()
        case 15: PalmShape()
        case 16: PineShape()
        case 17: OrchidShape()
        case 18: BasilShape()
        case 19: LilyShape()
        case 20: DandelionShape()
        default: OakShape()
        }
    }
}

// MARK: - Shared colour palette

private let leafGreen      = Color(red: 0.20, green: 0.65, blue: 0.30)
private let midGreen       = Color(red: 0.14, green: 0.50, blue: 0.22)
private let darkGreen      = Color(red: 0.07, green: 0.36, blue: 0.14)
private let stemBrown      = Color(red: 0.45, green: 0.28, blue: 0.10)
private let trunkBrown     = Color(red: 0.38, green: 0.23, blue: 0.08)

// MARK: - 1. Monstera

struct MonsteraShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height

            // Stem
            var stem = Path()
            stem.move(to: CGPoint(x: mx, y: base))
            stem.addCurve(to: CGPoint(x: mx - 4, y: base * 0.30),
                          control1: CGPoint(x: mx + 12, y: base * 0.65),
                          control2: CGPoint(x: mx - 14, y: base * 0.48))
            ctx.stroke(stem, with: .color(midGreen), lineWidth: 4)

            // Small side leaf (right)
            let sl = CGPoint(x: mx + 10, y: base * 0.58)
            var sLeaf = Path()
            sLeaf.move(to: sl)
            sLeaf.addCurve(to: CGPoint(x: sl.x + 38, y: sl.y - 18),
                           control1: CGPoint(x: sl.x + 10, y: sl.y + 8),
                           control2: CGPoint(x: sl.x + 32, y: sl.y - 5))
            sLeaf.addCurve(to: CGPoint(x: sl.x + 18, y: sl.y - 42),
                           control1: CGPoint(x: sl.x + 44, y: sl.y - 32),
                           control2: CGPoint(x: sl.x + 32, y: sl.y - 40))
            sLeaf.addCurve(to: sl, control1: CGPoint(x: sl.x + 5, y: sl.y - 44),
                           control2: CGPoint(x: sl.x - 5, y: sl.y - 25))
            ctx.fill(sLeaf, with: .color(darkGreen))

            // Main leaf
            let cy = base * 0.28
            var leaf = Path()
            leaf.move(to: CGPoint(x: mx - 4, y: base * 0.35))
            leaf.addCurve(to: CGPoint(x: mx - 58, y: cy + 12),
                          control1: CGPoint(x: mx - 28, y: base * 0.40),
                          control2: CGPoint(x: mx - 62, y: cy + 28))
            leaf.addCurve(to: CGPoint(x: mx - 10, y: base * 0.06),
                          control1: CGPoint(x: mx - 54, y: cy - 28),
                          control2: CGPoint(x: mx - 40, y: base * 0.06))
            leaf.addCurve(to: CGPoint(x: mx + 14, y: base * 0.04),
                          control1: CGPoint(x: mx, y: base * 0.03),
                          control2: CGPoint(x: mx + 6, y: base * 0.03))
            leaf.addCurve(to: CGPoint(x: mx + 52, y: cy + 8),
                          control1: CGPoint(x: mx + 42, y: base * 0.06),
                          control2: CGPoint(x: mx + 55, y: cy - 18))
            leaf.addCurve(to: CGPoint(x: mx - 4, y: base * 0.35),
                          control1: CGPoint(x: mx + 58, y: cy + 28),
                          control2: CGPoint(x: mx + 22, y: base * 0.38))
            ctx.fill(leaf, with: .color(leafGreen))

            // Holes (filled black to simulate splits)
            func hole(_ p: Path) { ctx.fill(p, with: .color(.black)) }

            var h1 = Path()
            h1.move(to: CGPoint(x: mx - 18, y: cy + 8))
            h1.addCurve(to: CGPoint(x: mx - 48, y: cy - 2),
                        control1: CGPoint(x: mx - 24, y: cy - 8),
                        control2: CGPoint(x: mx - 46, y: cy - 12))
            h1.addCurve(to: CGPoint(x: mx - 18, y: cy + 18),
                        control1: CGPoint(x: mx - 50, y: cy + 6),
                        control2: CGPoint(x: mx - 26, y: cy + 18))
            h1.closeSubpath()
            hole(h1)

            var h2 = Path()
            h2.move(to: CGPoint(x: mx + 8, y: cy - 8))
            h2.addCurve(to: CGPoint(x: mx + 44, y: cy + 2),
                        control1: CGPoint(x: mx + 14, y: cy - 18),
                        control2: CGPoint(x: mx + 42, y: cy - 12))
            h2.addCurve(to: CGPoint(x: mx + 8, y: cy + 8),
                        control1: CGPoint(x: mx + 46, y: cy + 10),
                        control2: CGPoint(x: mx + 16, y: cy + 8))
            h2.closeSubpath()
            hole(h2)

            // Midrib
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx - 4, y: base * 0.35))
                p.addCurve(to: CGPoint(x: mx + 12, y: base * 0.05),
                           control1: CGPoint(x: mx - 10, y: base * 0.22),
                           control2: CGPoint(x: mx + 8, y: base * 0.12))
            }, with: .color(darkGreen.opacity(0.55)), lineWidth: 1.5)
        }
    }
}

// MARK: - 2. Sunflower

struct SunflowerShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let headY = base * 0.22

            // Stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx + 4, y: headY + 30),
                           control1: CGPoint(x: mx - 8, y: base * 0.65),
                           control2: CGPoint(x: mx - 4, y: base * 0.42))
            }, with: .color(midGreen), lineWidth: 5)

            // Leaves
            func drawLeaf(ox: CGFloat, oy: CGFloat, flip: Bool) {
                let dir: CGFloat = flip ? -1 : 1
                var lf = Path()
                lf.move(to: CGPoint(x: mx, y: oy))
                lf.addCurve(to: CGPoint(x: mx + dir * 38, y: oy - 12),
                            control1: CGPoint(x: mx + dir * 12, y: oy + 10),
                            control2: CGPoint(x: mx + dir * 32, y: oy + 2))
                lf.addCurve(to: CGPoint(x: mx, y: oy - 28),
                            control1: CGPoint(x: mx + dir * 44, y: oy - 24),
                            control2: CGPoint(x: mx + dir * 18, y: oy - 28))
                lf.closeSubpath()
                ctx.fill(lf, with: .color(leafGreen))
            }
            drawLeaf(ox: mx, oy: base * 0.62, flip: false)
            drawLeaf(ox: mx, oy: base * 0.44, flip: true)

            // Petals
            let petalCount = 14
            let petalLen: CGFloat = 22
            let petalW: CGFloat = 9
            let petalColor = Color(red: 1.0, green: 0.82, blue: 0.08)
            let cx = mx + 4
            let cy = headY
            for i in 0..<petalCount {
                let angle = Double(i) * (2.0 * .pi / Double(petalCount))
                let px = cx + cos(angle) * (petalLen + 8)
                let py = cy + sin(angle) * (petalLen + 8)
                var petal = Path()
                petal.move(to: CGPoint(x: cx + cos(angle) * 10, y: cy + sin(angle) * 10))
                let perp = angle + .pi / 2
                petal.addCurve(
                    to: CGPoint(x: px, y: py),
                    control1: CGPoint(x: cx + cos(angle) * 16 + cos(perp) * petalW * 0.7,
                                      y: cy + sin(angle) * 16 + sin(perp) * petalW * 0.7),
                    control2: CGPoint(x: px + cos(perp) * petalW * 0.4,
                                      y: py + sin(perp) * petalW * 0.4)
                )
                petal.addCurve(
                    to: CGPoint(x: cx + cos(angle) * 10, y: cy + sin(angle) * 10),
                    control1: CGPoint(x: px - cos(perp) * petalW * 0.4,
                                      y: py - sin(perp) * petalW * 0.4),
                    control2: CGPoint(x: cx + cos(angle) * 16 - cos(perp) * petalW * 0.7,
                                      y: cy + sin(angle) * 16 - sin(perp) * petalW * 0.7)
                )
                ctx.fill(petal, with: .color(petalColor))
            }

            // Seed disc
            ctx.fill(Circle().path(in: CGRect(x: cx - 16, y: cy - 16, width: 32, height: 32)),
                     with: .color(Color(red: 0.28, green: 0.14, blue: 0.04)))
            // Seed dots
            for i in 0..<6 {
                let a = Double(i) * .pi / 3
                let dx = cx + cos(a) * 6
                let dy = cy + sin(a) * 6
                ctx.fill(Circle().path(in: CGRect(x: dx - 2, y: dy - 2, width: 4, height: 4)),
                         with: .color(Color(red: 0.45, green: 0.25, blue: 0.08)))
            }
        }
    }
}

// MARK: - 3. Fern

struct FernShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height

            // Central stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx - 2, y: base * 0.05),
                           control1: CGPoint(x: mx + 6, y: base * 0.65),
                           control2: CGPoint(x: mx - 6, y: base * 0.32))
            }, with: .color(midGreen), lineWidth: 3)

            // Fronds – pairs of leaflets along the stem
            let fronds: [(CGFloat, Bool)] = [
                (base * 0.82, false), (base * 0.82, true),
                (base * 0.68, false), (base * 0.68, true),
                (base * 0.54, false), (base * 0.54, true),
                (base * 0.40, false), (base * 0.40, true),
                (base * 0.27, false), (base * 0.27, true),
                (base * 0.15, false), (base * 0.15, true),
            ]
            for (y, flip) in fronds {
                let stemX = mx - 2 + (y < base * 0.5 ? 2 : 0)
                let dir: CGFloat = flip ? -1 : 1
                let spread = (base - y) * 0.32 + 18
                var frond = Path()
                frond.move(to: CGPoint(x: stemX, y: y))
                frond.addCurve(
                    to: CGPoint(x: stemX + dir * spread, y: y - 8),
                    control1: CGPoint(x: stemX + dir * spread * 0.4, y: y + 6),
                    control2: CGPoint(x: stemX + dir * spread * 0.8, y: y)
                )
                frond.addCurve(
                    to: CGPoint(x: stemX + dir * spread * 0.5, y: y - 20),
                    control1: CGPoint(x: stemX + dir * spread * 1.05, y: y - 16),
                    control2: CGPoint(x: stemX + dir * spread * 0.8, y: y - 20)
                )
                frond.addCurve(
                    to: CGPoint(x: stemX, y: y),
                    control1: CGPoint(x: stemX + dir * spread * 0.3, y: y - 18),
                    control2: CGPoint(x: stemX + dir * 6, y: y - 8)
                )
                let alpha = 0.7 + Double(base - y) / Double(base) * 0.3
                ctx.fill(frond, with: .color(leafGreen.opacity(alpha)))
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: stemX, y: y))
                    p.addLine(to: CGPoint(x: stemX + dir * spread, y: y - 8))
                }, with: .color(darkGreen.opacity(0.4)), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - 4. Tulip

struct TulipShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let headY = base * 0.15

            // Stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addLine(to: CGPoint(x: mx, y: headY + 48))
            }, with: .color(midGreen), lineWidth: 5)

            // Two blade leaves
            func bladLeaf(side: CGFloat) {
                var leaf = Path()
                leaf.move(to: CGPoint(x: mx, y: base * 0.58))
                leaf.addCurve(to: CGPoint(x: mx + side * 42, y: base * 0.38),
                              control1: CGPoint(x: mx + side * 8, y: base * 0.60),
                              control2: CGPoint(x: mx + side * 38, y: base * 0.50))
                leaf.addCurve(to: CGPoint(x: mx, y: base * 0.42),
                              control1: CGPoint(x: mx + side * 46, y: base * 0.28),
                              control2: CGPoint(x: mx + side * 12, y: base * 0.40))
                leaf.closeSubpath()
                ctx.fill(leaf, with: .color(leafGreen))
            }
            bladLeaf(side: 1)
            bladLeaf(side: -1)

            // Tulip petals – 3 outer + 2 inner
            let petalColor = Color(red: 0.96, green: 0.28, blue: 0.38)
            let darkPetal  = Color(red: 0.78, green: 0.10, blue: 0.22)
            let cy = headY + 48

            // Outer petals
            for side: CGFloat in [-1, 0, 1] {
                var p = Path()
                let px = mx + side * 18
                p.move(to: CGPoint(x: mx, y: cy))
                p.addCurve(to: CGPoint(x: px - 10, y: cy - 55),
                           control1: CGPoint(x: px - 18, y: cy - 10),
                           control2: CGPoint(x: px - 22, y: cy - 40))
                p.addCurve(to: CGPoint(x: px + 10, y: cy - 55),
                           control1: CGPoint(x: px - 2, y: cy - 65),
                           control2: CGPoint(x: px + 2, y: cy - 65))
                p.addCurve(to: CGPoint(x: mx, y: cy),
                           control1: CGPoint(x: px + 22, y: cy - 40),
                           control2: CGPoint(x: px + 18, y: cy - 10))
                ctx.fill(p, with: .color(petalColor))
                ctx.stroke(p, with: .color(darkPetal.opacity(0.4)), lineWidth: 0.8)
            }
            // Inner petals (smaller, darker)
            for side: CGFloat in [-0.5, 0.5] {
                var p = Path()
                let px = mx + side * 12
                p.move(to: CGPoint(x: mx, y: cy))
                p.addCurve(to: CGPoint(x: px - 7, y: cy - 45),
                           control1: CGPoint(x: px - 12, y: cy - 8),
                           control2: CGPoint(x: px - 16, y: cy - 32))
                p.addCurve(to: CGPoint(x: px + 7, y: cy - 45),
                           control1: CGPoint(x: px, y: cy - 55),
                           control2: CGPoint(x: px + 2, y: cy - 55))
                p.addCurve(to: CGPoint(x: mx, y: cy),
                           control1: CGPoint(x: px + 16, y: cy - 32),
                           control2: CGPoint(x: px + 12, y: cy - 8))
                ctx.fill(p, with: .color(darkPetal))
            }
        }
    }
}

// MARK: - 5. Bamboo

struct BambooShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let bambooGreen = Color(red: 0.35, green: 0.72, blue: 0.30)
            let darkBamboo  = Color(red: 0.20, green: 0.52, blue: 0.18)
            let segW: CGFloat = 16
            let segH: CGFloat = 32

            func stalk(x: CGFloat, startY: CGFloat, segments: Int) {
                var sy = startY
                for i in 0..<segments {
                    let rect = CGRect(x: x - segW/2, y: sy - segH, width: segW, height: segH)
                    let alpha = 1.0 - Double(i) * 0.04
                    ctx.fill(RoundedRectangle(cornerRadius: segW/2).path(in: rect),
                             with: .color(bambooGreen.opacity(alpha)))
                    // Node ring
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: x - segW/2, y: sy - 2))
                        p.addLine(to: CGPoint(x: x + segW/2, y: sy - 2))
                    }, with: .color(darkBamboo), lineWidth: 2)
                    sy -= segH
                }
            }
            stalk(x: mx - 20, startY: base, segments: 5)
            stalk(x: mx + 2,  startY: base, segments: 6)
            stalk(x: mx + 24, startY: base, segments: 4)

            // Leaves at top of each stalk
            func leaf(ax: CGFloat, ay: CGFloat, angle: Double) {
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: ax, y: ay)
                    lCtx.rotate(by: .radians(angle))
                    var lf = Path()
                    lf.move(to: .zero)
                    lf.addCurve(to: CGPoint(x: 30, y: -10),
                                control1: CGPoint(x: 8, y: 8),
                                control2: CGPoint(x: 24, y: -4))
                    lf.addCurve(to: .zero,
                                control1: CGPoint(x: 34, y: -18),
                                control2: CGPoint(x: 12, y: -16))
                    lCtx.fill(lf, with: .color(bambooGreen))
                }
            }
            let topL = base - CGFloat(5) * segH
            let topM = base - CGFloat(6) * segH
            let topR = base - CGFloat(4) * segH
            leaf(ax: mx - 20, ay: topL,     angle: -.pi / 6)
            leaf(ax: mx - 20, ay: topL,     angle: -.pi / 2.2)
            leaf(ax: mx + 2,  ay: topM,     angle: -.pi / 5)
            leaf(ax: mx + 2,  ay: topM,     angle: -.pi / 1.8)
            leaf(ax: mx + 24, ay: topR,     angle: -.pi / 4)
            leaf(ax: mx + 24, ay: topR + 4, angle: -.pi / 1.6)
        }
    }
}

// MARK: - 6. Bonsai

struct BonsaiShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height

            // Trunk – S-curve
            let trunkPath = Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx - 10, y: base * 0.55),
                           control1: CGPoint(x: mx + 14, y: base * 0.80),
                           control2: CGPoint(x: mx + 10, y: base * 0.65))
                p.addCurve(to: CGPoint(x: mx + 8, y: base * 0.32),
                           control1: CGPoint(x: mx - 28, y: base * 0.46),
                           control2: CGPoint(x: mx - 4, y: base * 0.38))
                p.addCurve(to: CGPoint(x: mx - 6, y: base * 0.18),
                           control1: CGPoint(x: mx + 18, y: base * 0.28),
                           control2: CGPoint(x: mx + 4, y: base * 0.22))
            }
            ctx.stroke(trunkPath, with: .color(trunkBrown), lineWidth: 14)
            ctx.stroke(trunkPath, with: .color(stemBrown.opacity(0.4)), lineWidth: 10)

            // Branch left
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx - 10, y: base * 0.55))
                p.addCurve(to: CGPoint(x: mx - 45, y: base * 0.38),
                           control1: CGPoint(x: mx - 20, y: base * 0.54),
                           control2: CGPoint(x: mx - 38, y: base * 0.46))
            }, with: .color(trunkBrown), lineWidth: 7)

            // Branch right
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx + 8, y: base * 0.32))
                p.addCurve(to: CGPoint(x: mx + 42, y: base * 0.22),
                           control1: CGPoint(x: mx + 22, y: base * 0.30),
                           control2: CGPoint(x: mx + 38, y: base * 0.26))
            }, with: .color(trunkBrown), lineWidth: 5)

            // Foliage clouds
            func cloud(center: CGPoint, radius: CGFloat, color: Color) {
                for (dx, dy, r): (CGFloat, CGFloat, CGFloat) in [
                    (0, 0, radius), (-radius*0.5, radius*0.3, radius*0.75),
                    (radius*0.5, radius*0.3, radius*0.75),
                    (-radius*0.65, -radius*0.1, radius*0.6),
                    (radius*0.65, -radius*0.1, radius*0.6),
                    (0, -radius*0.5, radius*0.65),
                ] {
                    ctx.fill(Circle().path(in: CGRect(x: center.x + dx - r,
                                                       y: center.y + dy - r,
                                                       width: r*2, height: r*2)),
                             with: .color(color))
                }
            }
            cloud(center: CGPoint(x: mx - 6, y: base * 0.12), radius: 28, color: leafGreen)
            cloud(center: CGPoint(x: mx - 42, y: base * 0.32), radius: 20, color: midGreen)
            cloud(center: CGPoint(x: mx + 40, y: base * 0.16), radius: 18, color: leafGreen.opacity(0.85))

            // Tiny pink blossoms
            for (bx, by): (CGFloat, CGFloat) in [
                (mx - 10, base * 0.06), (mx + 14, base * 0.08), (mx - 28, base * 0.26),
                (mx + 32, base * 0.12), (mx - 55, base * 0.30),
            ] {
                ctx.fill(Circle().path(in: CGRect(x: bx - 4, y: by - 4, width: 8, height: 8)),
                         with: .color(Color.pink.opacity(0.8)))
            }
        }
    }
}

// MARK: - 7. Succulent (Echeveria rosette)

struct SucculentShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let cy = base * 0.45

            let colors: [Color] = [
                Color(red: 0.38, green: 0.75, blue: 0.42),
                Color(red: 0.28, green: 0.62, blue: 0.35),
                Color(red: 0.18, green: 0.52, blue: 0.28),
                Color(red: 0.42, green: 0.78, blue: 0.48),
            ]

            // Outer petals (8)
            for i in 0..<8 {
                let angle = Double(i) * (.pi / 4)
                let petalLen: CGFloat = 48
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: mx, y: cy)
                    lCtx.rotate(by: .radians(angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addCurve(to: CGPoint(x: 0, y: -petalLen),
                               control1: CGPoint(x: -14, y: -petalLen * 0.4),
                               control2: CGPoint(x: -10, y: -petalLen * 0.8))
                    p.addCurve(to: .zero,
                               control1: CGPoint(x: 10, y: -petalLen * 0.8),
                               control2: CGPoint(x: 14, y: -petalLen * 0.4))
                    lCtx.fill(p, with: .color(colors[i % colors.count]))
                    lCtx.stroke(p, with: .color(darkGreen.opacity(0.3)), lineWidth: 0.8)
                }
            }

            // Middle petals (5)
            for i in 0..<5 {
                let angle = Double(i) * (.pi * 2 / 5) + .pi / 10
                let petalLen: CGFloat = 28
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: mx, y: cy)
                    lCtx.rotate(by: .radians(angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addCurve(to: CGPoint(x: 0, y: -petalLen),
                               control1: CGPoint(x: -10, y: -petalLen * 0.4),
                               control2: CGPoint(x: -7, y: -petalLen * 0.8))
                    p.addCurve(to: .zero,
                               control1: CGPoint(x: 7, y: -petalLen * 0.8),
                               control2: CGPoint(x: 10, y: -petalLen * 0.4))
                    lCtx.fill(p, with: .color(colors[(i + 2) % colors.count]))
                }
            }

            // Center
            ctx.fill(Circle().path(in: CGRect(x: mx - 10, y: cy - 10, width: 20, height: 20)),
                     with: .color(Color(red: 0.55, green: 0.88, blue: 0.55)))
            ctx.fill(Circle().path(in: CGRect(x: mx - 5, y: cy - 5, width: 10, height: 10)),
                     with: .color(Color(red: 0.72, green: 0.95, blue: 0.62)))

            // Short stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: cy + 5))
                p.addLine(to: CGPoint(x: mx, y: base))
            }, with: .color(midGreen), lineWidth: 6)
        }
    }
}

// MARK: - 8. Lavender

struct LavenderShape: View {
    var body: some View {
        Canvas { ctx, size in
            let base = size.height
            let purple = Color(red: 0.58, green: 0.30, blue: 0.78)
            let deepPurple = Color(red: 0.40, green: 0.15, blue: 0.60)

            let stems: [(CGFloat, CGFloat)] = [
                (size.width * 0.30, base * 0.12),
                (size.width * 0.45, base * 0.06),
                (size.width * 0.60, base * 0.10),
                (size.width * 0.72, base * 0.16),
            ]
            for (sx, topY) in stems {
                // Stem
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: sx, y: base))
                    p.addCurve(to: CGPoint(x: sx + 2, y: topY + 40),
                               control1: CGPoint(x: sx - 4, y: base * 0.65),
                               control2: CGPoint(x: sx + 6, y: base * 0.42))
                }, with: .color(midGreen), lineWidth: 2.5)

                // Tiny leaf pairs
                for ly in stride(from: base * 0.75, through: topY + 50, by: -22) {
                    for side: CGFloat in [-1, 1] {
                        var lf = Path()
                        lf.move(to: CGPoint(x: sx, y: ly))
                        lf.addCurve(to: CGPoint(x: sx + side * 14, y: ly - 8),
                                    control1: CGPoint(x: sx + side * 4, y: ly + 2),
                                    control2: CGPoint(x: sx + side * 12, y: ly - 2))
                        lf.addCurve(to: CGPoint(x: sx, y: ly - 12),
                                    control1: CGPoint(x: sx + side * 16, y: ly - 14),
                                    control2: CGPoint(x: sx + side * 6, y: ly - 12))
                        ctx.fill(lf, with: .color(leafGreen.opacity(0.7)))
                    }
                }

                // Flower spike – vertical column of oval florets
                var floretY = topY + 38
                while floretY >= topY {
                    for dx: CGFloat in [-5, 0, 5] {
                        let fr = CGRect(x: sx + dx - 4, y: floretY - 4, width: 8, height: 10)
                        ctx.fill(Ellipse().path(in: fr), with: .color(purple))
                        ctx.stroke(Ellipse().path(in: fr), with: .color(deepPurple.opacity(0.5)), lineWidth: 0.5)
                    }
                    floretY -= 8
                }
            }
        }
    }
}

// MARK: - 9. Snake Plant (Sansevieria)

struct SnakePlantShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let snakeGreen  = Color(red: 0.18, green: 0.52, blue: 0.24)
            let lightBand   = Color(red: 0.42, green: 0.72, blue: 0.38)
            let edgeYellow  = Color(red: 0.72, green: 0.82, blue: 0.22)

            let leaves: [(x: CGFloat, w: CGFloat, h: CGFloat, lean: CGFloat)] = [
                (mx - 36, 14, 155, -4),
                (mx - 18, 17, 180, -1),
                (mx + 2,  20, 195,  0),
                (mx + 22, 17, 172,  2),
                (mx + 40, 14, 148,  5),
            ]

            for leaf in leaves {
                let lx = leaf.x, lw = leaf.w, lh = leaf.h, lean = leaf.lean
                // Main body
                var body = Path()
                body.move(to: CGPoint(x: lx - lw/2, y: base))
                body.addCurve(to: CGPoint(x: lx - lw/2 + lean, y: base - lh),
                              control1: CGPoint(x: lx - lw/2 - 2, y: base - lh * 0.6),
                              control2: CGPoint(x: lx - lw/2 + lean - 2, y: base - lh * 0.85))
                body.addLine(to: CGPoint(x: lx + lw/2 + lean, y: base - lh + 12))
                body.addCurve(to: CGPoint(x: lx + lw/2, y: base),
                              control1: CGPoint(x: lx + lw/2 + lean + 2, y: base - lh * 0.85),
                              control2: CGPoint(x: lx + lw/2 + 2, y: base - lh * 0.6))
                body.closeSubpath()
                ctx.fill(body, with: .color(snakeGreen))

                // Horizontal bands
                var bandY = base - 20
                while bandY > base - lh + 20 {
                    let progress = (base - bandY) / lh
                    let bx = lx - lw/2 + lean * progress
                    let bw = lw * 0.9
                    let rect = CGRect(x: bx - bw/2 + lw/2, y: bandY, width: bw, height: 4)
                    ctx.fill(Rectangle().path(in: rect), with: .color(lightBand.opacity(0.5)))
                    bandY -= 18
                }

                // Yellow edge lines
                for ex: CGFloat in [-lw/2, lw/2] {
                    let progress: CGFloat = 0.5
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: lx + ex, y: base))
                        p.addLine(to: CGPoint(x: lx + ex + lean * progress, y: base - lh * progress))
                    }, with: .color(edgeYellow.opacity(0.6)), lineWidth: 1.5)
                }
            }
        }
    }
}

// MARK: - 10. Fiddle Leaf Fig

struct FiddleLeafShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let leafColor = Color(red: 0.15, green: 0.50, blue: 0.22)
            let gloss     = Color(red: 0.30, green: 0.68, blue: 0.35)

            // Trunk
            ctx.fill(Path { p in
                p.move(to: CGPoint(x: mx - 8, y: base))
                p.addCurve(to: CGPoint(x: mx - 6, y: base * 0.52),
                           control1: CGPoint(x: mx - 10, y: base * 0.75),
                           control2: CGPoint(x: mx - 8, y: base * 0.62))
                p.addLine(to: CGPoint(x: mx + 8, y: base * 0.52))
                p.addCurve(to: CGPoint(x: mx + 8, y: base),
                           control1: CGPoint(x: mx + 10, y: base * 0.62),
                           control2: CGPoint(x: mx + 10, y: base * 0.75))
            }, with: .color(trunkBrown))

            // Big violin-shaped leaves
            func fiddleLeaf(attach: CGPoint, tip: CGPoint, side: CGFloat) {
                var leaf = Path()
                leaf.move(to: attach)
                leaf.addCurve(to: CGPoint(x: attach.x + side * 36, y: (attach.y + tip.y) / 2 + 10),
                              control1: CGPoint(x: attach.x + side * 8, y: attach.y - 10),
                              control2: CGPoint(x: attach.x + side * 40, y: (attach.y + tip.y) / 2 - 10))
                leaf.addCurve(to: tip,
                              control1: CGPoint(x: attach.x + side * 30, y: tip.y + 30),
                              control2: CGPoint(x: tip.x + side * 10, y: tip.y + 8))
                leaf.addCurve(to: attach,
                              control1: CGPoint(x: tip.x - side * 10, y: tip.y + 8),
                              control2: CGPoint(x: attach.x - side * 8, y: attach.y - 10))
                ctx.fill(leaf, with: .color(leafColor))
                // Midrib
                ctx.stroke(Path { p in
                    p.move(to: attach)
                    p.addCurve(to: tip,
                               control1: CGPoint(x: attach.x + side * 6, y: (attach.y + tip.y) / 2 + 5),
                               control2: CGPoint(x: tip.x + side * 4, y: tip.y + 15))
                }, with: .color(gloss.opacity(0.6)), lineWidth: 1.5)
            }
            fiddleLeaf(attach: CGPoint(x: mx, y: base * 0.52),
                       tip: CGPoint(x: mx - 32, y: base * 0.20), side: -1)
            fiddleLeaf(attach: CGPoint(x: mx, y: base * 0.38),
                       tip: CGPoint(x: mx + 38, y: base * 0.08), side: 1)
            fiddleLeaf(attach: CGPoint(x: mx - 4, y: base * 0.60),
                       tip: CGPoint(x: mx - 20, y: base * 0.75), side: -1)
        }
    }
}

// MARK: - 11. Aloe Vera

struct AloeShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let aloeGreen  = Color(red: 0.30, green: 0.65, blue: 0.35)
            let aloeLight  = Color(red: 0.50, green: 0.80, blue: 0.45)
            let aloeTip    = Color(red: 0.70, green: 0.88, blue: 0.45)

            let leaves: [(angle: Double, len: CGFloat, w: CGFloat)] = [
                (-.pi/2, 145, 14),          // straight up
                (-.pi/2 - 0.5, 120, 12),
                (-.pi/2 + 0.5, 118, 12),
                (-.pi/2 - 1.0, 90, 10),
                (-.pi/2 + 1.0, 88, 10),
                (-.pi/2 - 1.5, 65, 8),
                (-.pi/2 + 1.5, 62, 8),
            ]
            let root = CGPoint(x: mx, y: base)

            for (angle, len, w) in leaves {
                let tipX = root.x + cos(angle) * len
                let tipY = root.y + sin(angle) * len
                let perp = angle + .pi / 2
                let ctrl = CGPoint(x: root.x + cos(angle) * len * 0.5,
                                   y: root.y + sin(angle) * len * 0.5)

                var lf = Path()
                lf.move(to: CGPoint(x: root.x + cos(perp) * w/2,
                                    y: root.y + sin(perp) * w/2))
                lf.addCurve(to: CGPoint(x: tipX, y: tipY),
                            control1: CGPoint(x: ctrl.x + cos(perp) * w * 0.5,
                                             y: ctrl.y + sin(perp) * w * 0.5),
                            control2: CGPoint(x: tipX + cos(perp) * 3,
                                             y: tipY + sin(perp) * 3))
                lf.addLine(to: CGPoint(x: tipX, y: tipY))
                lf.addCurve(to: CGPoint(x: root.x - cos(perp) * w/2,
                                        y: root.y - sin(perp) * w/2),
                            control1: CGPoint(x: tipX - cos(perp) * 3,
                                             y: tipY - sin(perp) * 3),
                            control2: CGPoint(x: ctrl.x - cos(perp) * w * 0.5,
                                             y: ctrl.y - sin(perp) * w * 0.5))
                lf.closeSubpath()
                ctx.fill(lf, with: .color(aloeGreen))

                // Light stripe
                ctx.stroke(Path { p in
                    p.move(to: root)
                    p.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: ctrl)
                }, with: .color(aloeLight.opacity(0.55)), lineWidth: 2)

                // Tiny tip spines
                ctx.fill(Circle().path(in: CGRect(x: tipX - 2.5, y: tipY - 2.5, width: 5, height: 5)),
                         with: .color(aloeTip))
            }
        }
    }
}

// MARK: - 12. Rose

struct RoseShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let roseRed  = Color(red: 0.88, green: 0.12, blue: 0.22)
            let roseDark = Color(red: 0.60, green: 0.06, blue: 0.14)
            let headY    = base * 0.18

            // Stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx - 2, y: headY + 38),
                           control1: CGPoint(x: mx + 10, y: base * 0.68),
                           control2: CGPoint(x: mx - 8, y: base * 0.45))
            }, with: .color(midGreen), lineWidth: 4)

            // Thorns
            for (tx, ty, flip): (CGFloat, CGFloat, Bool) in [
                (mx + 4, base * 0.65, false), (mx - 2, base * 0.50, true)
            ] {
                let d: CGFloat = flip ? -1 : 1
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: tx, y: ty))
                    p.addLine(to: CGPoint(x: tx + d * 8, y: ty - 6))
                }, with: .color(darkGreen), lineWidth: 2)
            }

            // Leaves
            for (lx, ly, d): (CGFloat, CGFloat, CGFloat) in [
                (mx + 6, base * 0.58, 1), (mx - 4, base * 0.44, -1)
            ] {
                var lf = Path()
                lf.move(to: CGPoint(x: lx, y: ly))
                lf.addCurve(to: CGPoint(x: lx + d * 30, y: ly - 10),
                            control1: CGPoint(x: lx + d * 8, y: ly + 6),
                            control2: CGPoint(x: lx + d * 26, y: ly))
                lf.addCurve(to: CGPoint(x: lx, y: ly - 20),
                            control1: CGPoint(x: lx + d * 34, y: ly - 20),
                            control2: CGPoint(x: lx + d * 12, y: ly - 20))
                lf.closeSubpath()
                ctx.fill(lf, with: .color(leafGreen))
            }

            // Rose bloom – concentric spiraling petals
            let cx = mx - 2
            let cy = headY + 18

            // Outer guard petals
            for i in 0..<5 {
                let angle = Double(i) * (.pi * 2 / 5)
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: cx, y: cy)
                    lCtx.rotate(by: .radians(angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addCurve(to: CGPoint(x: -12, y: -32),
                               control1: CGPoint(x: -18, y: -8),
                               control2: CGPoint(x: -20, y: -22))
                    p.addCurve(to: CGPoint(x: 12, y: -32),
                               control1: CGPoint(x: -2, y: -42),
                               control2: CGPoint(x: 2, y: -42))
                    p.addCurve(to: .zero,
                               control1: CGPoint(x: 20, y: -22),
                               control2: CGPoint(x: 18, y: -8))
                    lCtx.fill(p, with: .color(roseDark))
                }
            }
            // Inner petals
            for i in 0..<4 {
                let angle = Double(i) * (.pi / 2) + .pi / 4
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: cx, y: cy)
                    lCtx.rotate(by: .radians(angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addCurve(to: CGPoint(x: -8, y: -20),
                               control1: CGPoint(x: -12, y: -6),
                               control2: CGPoint(x: -14, y: -14))
                    p.addCurve(to: CGPoint(x: 8, y: -20),
                               control1: CGPoint(x: -2, y: -28),
                               control2: CGPoint(x: 2, y: -28))
                    p.addCurve(to: .zero,
                               control1: CGPoint(x: 14, y: -14),
                               control2: CGPoint(x: 12, y: -6))
                    lCtx.fill(p, with: .color(roseRed))
                }
            }
            // Center
            ctx.fill(Circle().path(in: CGRect(x: cx - 7, y: cy - 9, width: 14, height: 14)),
                     with: .color(roseRed))
            ctx.fill(Circle().path(in: CGRect(x: cx - 4, y: cy - 5, width: 8, height: 8)),
                     with: .color(Color(red: 1.0, green: 0.75, blue: 0.35)))
        }
    }
}

// MARK: - 13. Daisy

struct DaisyShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let headY = base * 0.20

            // Stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addLine(to: CGPoint(x: mx, y: headY + 28))
            }, with: .color(midGreen), lineWidth: 4)

            // Leaves
            for (d): CGFloat in [-1, 1] {
                var lf = Path()
                lf.move(to: CGPoint(x: mx, y: base * 0.55))
                lf.addCurve(to: CGPoint(x: mx + d * 36, y: base * 0.44),
                            control1: CGPoint(x: mx + d * 10, y: base * 0.58),
                            control2: CGPoint(x: mx + d * 30, y: base * 0.52))
                lf.addCurve(to: CGPoint(x: mx, y: base * 0.48),
                            control1: CGPoint(x: mx + d * 42, y: base * 0.36),
                            control2: CGPoint(x: mx + d * 12, y: base * 0.46))
                ctx.fill(lf, with: .color(leafGreen))
            }

            // White petals
            let cx = mx, cy = headY + 14
            for i in 0..<12 {
                let angle = Double(i) * (.pi / 6)
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: cx, y: cy)
                    lCtx.rotate(by: .radians(angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addCurve(to: CGPoint(x: -7, y: -28),
                               control1: CGPoint(x: -10, y: -6),
                               control2: CGPoint(x: -10, y: -20))
                    p.addCurve(to: CGPoint(x: 7, y: -28),
                               control1: CGPoint(x: -2, y: -34),
                               control2: CGPoint(x: 2, y: -34))
                    p.addCurve(to: .zero,
                               control1: CGPoint(x: 10, y: -20),
                               control2: CGPoint(x: 10, y: -6))
                    lCtx.fill(p, with: .color(Color.white.opacity(0.92)))
                    lCtx.stroke(p, with: .color(Color.gray.opacity(0.2)), lineWidth: 0.5)
                }
            }

            // Yellow center
            ctx.fill(Circle().path(in: CGRect(x: cx - 13, y: cy - 13, width: 26, height: 26)),
                     with: .color(Color(red: 1.0, green: 0.85, blue: 0.10)))
            ctx.fill(Circle().path(in: CGRect(x: cx - 7, y: cy - 7, width: 14, height: 14)),
                     with: .color(Color(red: 0.85, green: 0.60, blue: 0.05)))
        }
    }
}

// MARK: - 14. Cherry Blossom

struct CherryBlossomShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let wood  = Color(red: 0.42, green: 0.22, blue: 0.10)
            let pink  = Color(red: 0.98, green: 0.62, blue: 0.72)
            let deepPink = Color(red: 0.90, green: 0.38, blue: 0.52)

            // Trunk
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx - 5, y: base * 0.48),
                           control1: CGPoint(x: mx + 8, y: base * 0.75),
                           control2: CGPoint(x: mx - 4, y: base * 0.60))
            }, with: .color(wood), lineWidth: 12)

            // Main branches
            let branches: [(from: CGPoint, to: CGPoint, w: CGFloat)] = [
                (CGPoint(x: mx - 5, y: base * 0.48), CGPoint(x: mx - 50, y: base * 0.24), 6),
                (CGPoint(x: mx - 5, y: base * 0.48), CGPoint(x: mx + 42, y: base * 0.18), 5),
                (CGPoint(x: mx - 28, y: base * 0.35), CGPoint(x: mx - 55, y: base * 0.42), 4),
                (CGPoint(x: mx + 18, y: base * 0.32), CGPoint(x: mx + 58, y: base * 0.38), 3.5),
                (CGPoint(x: mx - 50, y: base * 0.24), CGPoint(x: mx - 42, y: base * 0.08), 3),
                (CGPoint(x: mx + 42, y: base * 0.18), CGPoint(x: mx + 36, y: base * 0.06), 2.5),
            ]
            for b in branches {
                ctx.stroke(Path { p in
                    p.move(to: b.from)
                    p.addCurve(to: b.to,
                               control1: CGPoint(x: (b.from.x + b.to.x)/2 - 5,
                                                 y: (b.from.y + b.to.y)/2 + 5),
                               control2: CGPoint(x: (b.from.x + b.to.x)/2 + 5,
                                                 y: (b.from.y + b.to.y)/2 - 5))
                }, with: .color(wood), lineWidth: b.w)
            }

            // Blossom clusters at branch tips
            let blossomPoints: [CGPoint] = [
                CGPoint(x: mx - 50, y: base * 0.24),
                CGPoint(x: mx + 42, y: base * 0.18),
                CGPoint(x: mx - 55, y: base * 0.42),
                CGPoint(x: mx + 58, y: base * 0.38),
                CGPoint(x: mx - 42, y: base * 0.08),
                CGPoint(x: mx + 36, y: base * 0.06),
                CGPoint(x: mx - 20, y: base * 0.16),
                CGPoint(x: mx + 10, y: base * 0.12),
                CGPoint(x: mx - 5,  y: base * 0.48),
            ]

            for center in blossomPoints {
                // 5-petal flower
                for i in 0..<5 {
                    let angle = Double(i) * (.pi * 2 / 5)
                    ctx.drawLayer { lCtx in
                        lCtx.translateBy(x: center.x, y: center.y)
                        lCtx.rotate(by: .radians(angle))
                        let p = Ellipse().path(in: CGRect(x: -4, y: -14, width: 8, height: 12))
                        lCtx.fill(p, with: .color(pink))
                        lCtx.stroke(p, with: .color(deepPink.opacity(0.4)), lineWidth: 0.5)
                    }
                }
                ctx.fill(Circle().path(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
                         with: .color(Color.yellow.opacity(0.8)))
            }
        }
    }
}

// MARK: - 15. Palm Tree

struct PalmShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let trunkColor = Color(red: 0.60, green: 0.44, blue: 0.22)
            let frondColor = Color(red: 0.20, green: 0.65, blue: 0.28)

            // Trunk – slightly curved
            let trunkPath = Path { p in
                p.move(to: CGPoint(x: mx - 8, y: base))
                p.addCurve(to: CGPoint(x: mx + 6, y: base * 0.22),
                           control1: CGPoint(x: mx - 12, y: base * 0.65),
                           control2: CGPoint(x: mx + 8, y: base * 0.45))
                p.addLine(to: CGPoint(x: mx + 14, y: base * 0.22))
                p.addCurve(to: CGPoint(x: mx + 2, y: base),
                           control1: CGPoint(x: mx + 16, y: base * 0.45),
                           control2: CGPoint(x: mx + 4, y: base * 0.65))
                p.closeSubpath()
            }
            ctx.fill(trunkPath, with: .color(trunkColor))
            // Ring marks
            for y in stride(from: base * 0.30, through: base * 0.88, by: 18) {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: mx - 8 + (base - y) / base * 2, y: y))
                    p.addLine(to: CGPoint(x: mx + 14 - (base - y) / base * 2, y: y))
                }, with: .color(Color(red: 0.48, green: 0.32, blue: 0.12)), lineWidth: 1.5)
            }

            // Fronds
            let crown = CGPoint(x: mx + 8, y: base * 0.22)
            let fronds: [(Double, CGFloat)] = [
                (-.pi/2, 65), (-.pi/2 - 0.6, 58), (-.pi/2 + 0.6, 58),
                (-.pi/2 - 1.1, 50), (-.pi/2 + 1.1, 50),
                (-.pi/2 - 1.6, 40), (-.pi/2 + 1.6, 40),
            ]
            for (angle, len) in fronds {
                let tipX = crown.x + cos(angle) * len
                let tipY = crown.y + sin(angle) * len
                let perp = angle + .pi/2

                // Stem
                ctx.stroke(Path { p in
                    p.move(to: crown)
                    p.addCurve(to: CGPoint(x: tipX, y: tipY),
                               control1: CGPoint(x: crown.x + cos(angle) * len * 0.3,
                                                 y: crown.y + sin(angle) * len * 0.3 + 8),
                               control2: CGPoint(x: tipX + cos(angle) * 5,
                                                 y: tipY + 10))
                }, with: .color(frondColor), lineWidth: 2)

                // Leaflets along frond
                for t: CGFloat in [0.3, 0.5, 0.7, 0.9] {
                    let lx = crown.x + cos(angle) * len * t
                    let ly = crown.y + sin(angle) * len * t + (1 - t) * 6
                    let lLen = len * 0.25 * (1 - t * 0.3)
                    for side: CGFloat in [-1, 1] {
                        var lf = Path()
                        lf.move(to: CGPoint(x: lx, y: ly))
                        lf.addCurve(to: CGPoint(x: lx + cos(perp) * side * lLen,
                                                y: ly + sin(perp) * side * lLen),
                                    control1: CGPoint(x: lx + cos(perp) * side * lLen * 0.3,
                                                      y: ly + sin(perp) * side * lLen * 0.3 + 3),
                                    control2: CGPoint(x: lx + cos(perp) * side * lLen * 0.7,
                                                      y: ly + sin(perp) * side * lLen * 0.7 + 2))
                        ctx.stroke(lf, with: .color(frondColor.opacity(0.9)), lineWidth: 1.5)
                    }
                }
            }
        }
    }
}

// MARK: - 16. Pine Tree

struct PineShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let pineGreen = Color(red: 0.10, green: 0.45, blue: 0.18)
            let lightPine = Color(red: 0.20, green: 0.60, blue: 0.28)

            // Trunk
            ctx.fill(Path { p in
                p.move(to: CGPoint(x: mx - 7, y: base))
                p.addLine(to: CGPoint(x: mx - 5, y: base * 0.72))
                p.addLine(to: CGPoint(x: mx + 5, y: base * 0.72))
                p.addLine(to: CGPoint(x: mx + 7, y: base))
            }, with: .color(trunkBrown))

            // Three tiers – bottom to top, each wider at base
            let tiers: [(y: CGFloat, w: CGFloat, h: CGFloat)] = [
                (base * 0.74, 70, 42),
                (base * 0.46, 54, 38),
                (base * 0.22, 38, 34),
                (base * 0.02, 24, 28),
            ]
            for (i, tier) in tiers.enumerated() {
                let alpha = 1.0 - Double(i) * 0.06
                var tri = Path()
                tri.move(to: CGPoint(x: mx, y: tier.y - tier.h))
                tri.addLine(to: CGPoint(x: mx - tier.w/2, y: tier.y + 4))
                tri.addLine(to: CGPoint(x: mx + tier.w/2, y: tier.y + 4))
                tri.closeSubpath()
                ctx.fill(tri, with: .color(pineGreen.opacity(alpha)))
                ctx.stroke(tri, with: .color(lightPine.opacity(0.4)), lineWidth: 1)
                // Snow tips
                if i == tiers.count - 1 {
                    ctx.fill(Circle().path(in: CGRect(x: mx - 5, y: tier.y - tier.h - 2, width: 10, height: 10)),
                             with: .color(Color.white.opacity(0.85)))
                }
            }
        }
    }
}

// MARK: - 17. Orchid

struct OrchidShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let orchidPink  = Color(red: 0.88, green: 0.45, blue: 0.82)
            let orchidDark  = Color(red: 0.65, green: 0.18, blue: 0.62)
            let orchidWhite = Color(red: 0.98, green: 0.88, blue: 0.96)

            // Basal leaves
            for (d): CGFloat in [-1, 1] {
                var lf = Path()
                lf.move(to: CGPoint(x: mx, y: base))
                lf.addCurve(to: CGPoint(x: mx + d * 50, y: base * 0.72),
                            control1: CGPoint(x: mx + d * 14, y: base + 8),
                            control2: CGPoint(x: mx + d * 44, y: base * 0.78))
                lf.addCurve(to: CGPoint(x: mx + d * 20, y: base * 0.86),
                            control1: CGPoint(x: mx + d * 56, y: base * 0.62),
                            control2: CGPoint(x: mx + d * 32, y: base * 0.80))
                lf.closeSubpath()
                ctx.fill(lf, with: .color(leafGreen))
            }

            // Flower spike
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx + 8, y: base * 0.78))
                p.addCurve(to: CGPoint(x: mx + 18, y: base * 0.06),
                           control1: CGPoint(x: mx + 22, y: base * 0.55),
                           control2: CGPoint(x: mx + 28, y: base * 0.28))
            }, with: .color(midGreen), lineWidth: 2.5)

            // Flowers
            let flowerPos: [(CGFloat, CGFloat)] = [
                (mx + 26, base * 0.16),
                (mx + 22, base * 0.32),
                (mx + 14, base * 0.48),
            ]
            for (fx, fy) in flowerPos {
                // 5 petals
                for i in 0..<5 {
                    let angle = Double(i) * (.pi * 2 / 5)
                    ctx.drawLayer { lCtx in
                        lCtx.translateBy(x: fx, y: fy)
                        lCtx.rotate(by: .radians(angle))
                        let p = Ellipse().path(in: CGRect(x: -6, y: -16, width: 12, height: 14))
                        lCtx.fill(p, with: .color(orchidWhite))
                        lCtx.stroke(p, with: .color(orchidPink.opacity(0.5)), lineWidth: 0.8)
                    }
                }
                // Lip petal
                var lip = Path()
                lip.move(to: CGPoint(x: fx, y: fy + 4))
                lip.addCurve(to: CGPoint(x: fx - 10, y: fy + 18),
                             control1: CGPoint(x: fx - 12, y: fy + 8),
                             control2: CGPoint(x: fx - 14, y: fy + 14))
                lip.addCurve(to: CGPoint(x: fx + 10, y: fy + 18),
                             control1: CGPoint(x: fx - 4, y: fy + 24),
                             control2: CGPoint(x: fx + 4, y: fy + 24))
                lip.addCurve(to: CGPoint(x: fx, y: fy + 4),
                             control1: CGPoint(x: fx + 14, y: fy + 14),
                             control2: CGPoint(x: fx + 12, y: fy + 8))
                ctx.fill(lip, with: .color(orchidPink))

                // Center column
                ctx.fill(Circle().path(in: CGRect(x: fx - 4, y: fy - 4, width: 8, height: 8)),
                         with: .color(orchidDark))
                ctx.fill(Circle().path(in: CGRect(x: fx - 2.5, y: fy - 2.5, width: 5, height: 5)),
                         with: .color(Color.yellow.opacity(0.9)))
            }
        }
    }
}

// MARK: - 18. Basil

struct BasilShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let basilGreen = Color(red: 0.16, green: 0.58, blue: 0.24)
            let lightBasil = Color(red: 0.30, green: 0.72, blue: 0.36)

            // Main stems
            for (sx, sh): (CGFloat, CGFloat) in [
                (mx - 20, base * 0.52), (mx, base * 0.42), (mx + 20, base * 0.55)
            ] {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: mx, y: base))
                    p.addCurve(to: CGPoint(x: sx, y: sh),
                               control1: CGPoint(x: mx + (sx - mx) * 0.3, y: base * 0.80),
                               control2: CGPoint(x: sx + (mx - sx) * 0.2, y: sh + 20))
                }, with: .color(midGreen), lineWidth: 3)
            }

            // Dense leaf clusters
            let clusters: [(CGFloat, CGFloat, CGFloat)] = [
                (mx - 36, base * 0.48, 0.85),
                (mx - 14, base * 0.34, 1.0),
                (mx + 4,  base * 0.28, 1.0),
                (mx + 22, base * 0.36, 0.9),
                (mx + 44, base * 0.52, 0.8),
                (mx - 48, base * 0.58, 0.75),
                (mx - 22, base * 0.52, 0.9),
                (mx + 8,  base * 0.46, 0.85),
                (mx + 36, base * 0.50, 0.8),
                (mx - 4,  base * 0.16, 0.95),
                (mx - 28, base * 0.22, 0.88),
                (mx + 26, base * 0.20, 0.90),
            ]
            for (cx, cy, alpha) in clusters {
                var lf = Path()
                lf.move(to: CGPoint(x: cx, y: cy + 12))
                lf.addCurve(to: CGPoint(x: cx - 16, y: cy),
                            control1: CGPoint(x: cx - 12, y: cy + 14),
                            control2: CGPoint(x: cx - 18, y: cy + 6))
                lf.addCurve(to: CGPoint(x: cx, y: cy - 18),
                            control1: CGPoint(x: cx - 14, y: cy - 12),
                            control2: CGPoint(x: cx - 6, y: cy - 18))
                lf.addCurve(to: CGPoint(x: cx + 16, y: cy),
                            control1: CGPoint(x: cx + 6, y: cy - 18),
                            control2: CGPoint(x: cx + 14, y: cy - 12))
                lf.addCurve(to: CGPoint(x: cx, y: cy + 12),
                            control1: CGPoint(x: cx + 18, y: cy + 6),
                            control2: CGPoint(x: cx + 12, y: cy + 14))
                ctx.fill(lf, with: .color(basilGreen.opacity(alpha)))
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: cx, y: cy + 12))
                    p.addLine(to: CGPoint(x: cx, y: cy - 18))
                }, with: .color(lightBasil.opacity(0.4)), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - 19. Lily

struct LilyShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let lilyOrange = Color(red: 0.98, green: 0.50, blue: 0.12)
            let lilyDark   = Color(red: 0.80, green: 0.28, blue: 0.04)

            // Stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx - 4, y: base * 0.25),
                           control1: CGPoint(x: mx + 6, y: base * 0.68),
                           control2: CGPoint(x: mx - 8, y: base * 0.46))
            }, with: .color(midGreen), lineWidth: 4)

            // Blade leaves along stem
            for (ly, d): (CGFloat, CGFloat) in [(base * 0.65, 1), (base * 0.50, -1), (base * 0.38, 1)] {
                var lf = Path()
                lf.move(to: CGPoint(x: mx, y: ly))
                lf.addCurve(to: CGPoint(x: mx + d * 38, y: ly - 14),
                            control1: CGPoint(x: mx + d * 10, y: ly + 4),
                            control2: CGPoint(x: mx + d * 32, y: ly))
                lf.addCurve(to: CGPoint(x: mx + d * 8, y: ly - 26),
                            control1: CGPoint(x: mx + d * 44, y: ly - 26),
                            control2: CGPoint(x: mx + d * 18, y: ly - 26))
                lf.closeSubpath()
                ctx.fill(lf, with: .color(leafGreen))
            }

            // Lily flower – 6 reflexed petals
            let cx = mx - 4, cy = base * 0.18
            for i in 0..<6 {
                let angle = Double(i) * (.pi / 3)
                ctx.drawLayer { lCtx in
                    lCtx.translateBy(x: cx, y: cy)
                    lCtx.rotate(by: .radians(angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addCurve(to: CGPoint(x: -8, y: -38),
                               control1: CGPoint(x: -16, y: -10),
                               control2: CGPoint(x: -14, y: -28))
                    p.addCurve(to: CGPoint(x: 0, y: -44),
                               control1: CGPoint(x: -4, y: -46),
                               control2: CGPoint(x: 0, y: -46))
                    p.addCurve(to: CGPoint(x: 8, y: -38),
                               control1: CGPoint(x: 0, y: -46),
                               control2: CGPoint(x: 4, y: -46))
                    p.addCurve(to: .zero,
                               control1: CGPoint(x: 14, y: -28),
                               control2: CGPoint(x: 16, y: -10))
                    lCtx.fill(p, with: .color(lilyOrange))
                    // Stripe
                    lCtx.stroke(Path { lp in
                        lp.move(to: .zero)
                        lp.addLine(to: CGPoint(x: 0, y: -40))
                    }, with: .color(lilyDark.opacity(0.5)), lineWidth: 1.5)
                }
                // Spots
                let sx = cx + cos(angle) * 18
                let sy = cy + sin(angle) * 18
                ctx.fill(Circle().path(in: CGRect(x: sx - 2, y: sy - 2, width: 4, height: 4)),
                         with: .color(Color(red: 0.55, green: 0.08, blue: 0.04).opacity(0.7)))
            }

            // Stamens
            for i in 0..<6 {
                let a = Double(i) * (.pi / 3) + .pi / 6
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx + cos(a) * 14, y: cy + sin(a) * 14))
                }, with: .color(Color(red: 0.85, green: 0.70, blue: 0.10)), lineWidth: 1.5)
                ctx.fill(Circle().path(in: CGRect(x: cx + cos(a) * 14 - 3,
                                                   y: cy + sin(a) * 14 - 3, width: 6, height: 6)),
                         with: .color(Color(red: 0.95, green: 0.65, blue: 0.05)))
            }
        }
    }
}

// MARK: - 20. Dandelion

struct DandelionShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let headY = base * 0.22

            // Stem
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: mx, y: base))
                p.addCurve(to: CGPoint(x: mx + 4, y: headY),
                           control1: CGPoint(x: mx - 8, y: base * 0.65),
                           control2: CGPoint(x: mx + 8, y: base * 0.42))
            }, with: .color(midGreen), lineWidth: 3)

            // Serrated leaves at base
            for (d): CGFloat in [-1, 1] {
                var lf = Path()
                let lx = mx + d * 6
                lf.move(to: CGPoint(x: lx, y: base * 0.72))
                for j in 0..<4 {
                    let t = CGFloat(j) / 3
                    let ex = lx + d * (20 + t * 22)
                    let ey = base * 0.72 - t * 35
                    let notchX = lx + d * (16 + t * 20)
                    lf.addLine(to: CGPoint(x: notchX, y: ey + 6))
                    lf.addLine(to: CGPoint(x: ex, y: ey))
                }
                lf.addCurve(to: CGPoint(x: lx, y: base * 0.65),
                            control1: CGPoint(x: lx + d * 50, y: base * 0.38),
                            control2: CGPoint(x: lx + d * 12, y: base * 0.60))
                lf.closeSubpath()
                ctx.fill(lf, with: .color(leafGreen))
            }

            // Seed head
            let cx = mx + 4, cy = headY
            // Small green receptacle
            ctx.fill(Circle().path(in: CGRect(x: cx - 6, y: cy - 6, width: 12, height: 12)),
                     with: .color(leafGreen))

            // Seeds radiating out
            let seedCount = 28
            for i in 0..<seedCount {
                let angle = Double(i) * (.pi * 2 / Double(seedCount))
                let seedLen: CGFloat = 32 + CGFloat.random(in: -4...4)
                let sx = cx + cos(angle) * seedLen
                let sy = cy + sin(angle) * seedLen
                // Fine stem
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: cx + cos(angle) * 7, y: cy + sin(angle) * 7))
                    p.addLine(to: CGPoint(x: sx, y: sy))
                }, with: .color(Color.white.opacity(0.70)), lineWidth: 0.8)
                // Fluffy tip (small circle)
                ctx.fill(Circle().path(in: CGRect(x: sx - 3, y: sy - 3, width: 6, height: 6)),
                         with: .color(Color.white.opacity(0.85)))
            }
        }
    }
}

// MARK: - 21. Oak Tree

struct OakShape: View {
    var body: some View {
        Canvas { ctx, size in
            let mx = size.width / 2
            let base = size.height
            let oakLeaf = Color(red: 0.22, green: 0.58, blue: 0.25)
            let oakDark = Color(red: 0.12, green: 0.40, blue: 0.16)

            // Trunk
            ctx.fill(Path { p in
                p.move(to: CGPoint(x: mx - 10, y: base))
                p.addCurve(to: CGPoint(x: mx - 8, y: base * 0.52),
                           control1: CGPoint(x: mx - 12, y: base * 0.78),
                           control2: CGPoint(x: mx - 10, y: base * 0.64))
                p.addLine(to: CGPoint(x: mx + 8, y: base * 0.52))
                p.addCurve(to: CGPoint(x: mx + 10, y: base),
                           control1: CGPoint(x: mx + 10, y: base * 0.64),
                           control2: CGPoint(x: mx + 12, y: base * 0.78))
            }, with: .color(trunkBrown))

            // Main branches
            for (from, to): (CGPoint, CGPoint) in [
                (CGPoint(x: mx, y: base * 0.52), CGPoint(x: mx - 28, y: base * 0.36)),
                (CGPoint(x: mx, y: base * 0.52), CGPoint(x: mx + 24, y: base * 0.32)),
                (CGPoint(x: mx - 14, y: base * 0.44), CGPoint(x: mx - 44, y: base * 0.50)),
                (CGPoint(x: mx + 10, y: base * 0.42), CGPoint(x: mx + 44, y: base * 0.46)),
            ] {
                ctx.stroke(Path { p in
                    p.move(to: from)
                    p.addLine(to: to)
                }, with: .color(trunkBrown), lineWidth: 5)
            }

            // Large rounded canopy — multiple overlapping circles
            let canopyCentre = CGPoint(x: mx, y: base * 0.28)
            let blobs: [(CGFloat, CGFloat, CGFloat)] = [
                (0, 0, 44), (-32, 10, 34), (30, 6, 34),
                (-16, -24, 32), (18, -20, 30), (-44, -4, 26),
                (42, -2, 26), (0, -38, 28), (-28, -36, 22),
                (28, -36, 22), (-52, 18, 20), (50, 16, 20),
            ]
            for (dx, dy, r) in blobs {
                let cx = canopyCentre.x + dx
                let cy = canopyCentre.y + dy
                let alpha = 0.80 + Double(r) / 200
                ctx.fill(Circle().path(in: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2)),
                         with: .color(oakLeaf.opacity(alpha)))
            }
            // Darker inner layer
            for (dx, dy, r): (CGFloat, CGFloat, CGFloat) in [
                (0, 0, 24), (-16, 10, 18), (16, 8, 18),
            ] {
                ctx.fill(Circle().path(in: CGRect(x: canopyCentre.x + dx - r,
                                                   y: canopyCentre.y + dy - r,
                                                   width: r*2, height: r*2)),
                         with: .color(oakDark.opacity(0.5)))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        // Show a random plant each time you refresh the preview
        PlantAnimationView()
    }
}
