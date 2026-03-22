import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                CircleTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.95))
                .shadow(color: Theme.accent.opacity(0.15), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Circle Tab Button

struct CircleTabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.accent : Color.clear)
                        .frame(width: 50, height: 50)

                    Circle()
                        .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
                        .frame(width: 50, height: 50)

                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .black : Theme.accent)
                }

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            TabBarView(selectedTab: .constant(.home))
        }
    }
}
