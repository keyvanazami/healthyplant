import SwiftUI

struct CactusAnimationView: View {
    @State private var bouncing = false

    var body: some View {
        VStack(spacing: 0) {
            // Cactus emoji with gentle bounce
            Text("🌵")
                .font(.system(size: 120))
                .scaleEffect(bouncing ? 1.05 : 0.95)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: bouncing
                )
                .offset(y: bouncing ? -6 : 6)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: bouncing
                )

            // Vase / pot shape
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.accent.opacity(0.3),
                                Theme.accent.opacity(0.15),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 100, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                    )

                Text("Healthy Plant")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .offset(y: -8)
        }
        .onAppear {
            bouncing = true
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CactusAnimationView()
    }
}
