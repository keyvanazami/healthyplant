import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentIcon: Bool
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        icon: "leaf.fill",
        title: "Welcome to HealthyPlant",
        description: "Your AI-powered companion for growing healthier plants. Let's walk through what you can do.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "leaf.fill",
        title: "Plant Profiles",
        description: "Add your plants with photos, age, and height. Our AI analyzes each one and recommends sun, water, and harvest care automatically.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "house.fill",
        title: "Home Dashboard",
        description: "See all your plants at a glance with quick stats and care reminders so nothing gets missed.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "tree.fill",
        title: "Community Garden",
        description: "Share your plants with other growers, browse what others are growing, and follow public gardeners to see their latest plants.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "calendar",
        title: "Care Calendar",
        description: "AI generates a weekly care schedule based on all your plants. Watering, sunlight, harvesting — all in one place.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "message.fill",
        title: "AI Assistant",
        description: "Ask anything about your plants. The assistant knows your profiles and gives personalized advice in real time.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "camera.viewfinder",
        title: "Plant Scanner",
        description: "Point your camera at any plant and AI will identify it instantly — including origin, history, care tips, and difficulty. Add it to your garden in one tap.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "sensor.tag.radiowaves.forward.fill",
        title: "IoT Sensors",
        description: "Connect an ESP32 soil sensor to monitor moisture, temperature, humidity, and light in real time. Pair it to a plant profile from Settings.",
        accentIcon: true
    ),
    OnboardingPage(
        icon: "trophy.fill",
        title: "Gardening Rank",
        description: "Earn points for every plant you add and keep alive. Level up from Seedling to Master Gardener — tap your rank on the Profiles tab to see the ladder.",
        accentIcon: true
    ),
]

struct OnboardingView: View {
    @Binding var isComplete: Bool
    var isRevisit: Bool = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Theme.accent : Theme.textSecondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        if !isRevisit {
                            UserDefaults.standard.set(true, forKey: "hp_onboarding_complete")
                        }
                        isComplete.toggle()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)

                if currentPage < pages.count - 1 {
                    Button {
                        if !isRevisit {
                            UserDefaults.standard.set(true, forKey: "hp_onboarding_complete")
                        }
                        isComplete.toggle()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(Theme.accent)
            }

            Text(page.title)
                .font(.title2.weight(.bold))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
