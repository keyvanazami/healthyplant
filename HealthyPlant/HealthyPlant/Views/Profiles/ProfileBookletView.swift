import SwiftUI

struct ProfileBookletView: View {
    let profiles: [PlantProfile]
    @ObservedObject var viewModel: ProfilesViewModel
    @State private var currentPage = 0
    @State private var selectedProfile: PlantProfile?

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                    bookletPage(profile: profile, pageNumber: index + 1)
                        .onTapGesture {
                            selectedProfile = profile
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationDestination(item: $selectedProfile) { profile in
                ProfileDetailView(profile: profile, viewModel: viewModel)
            }

            // Page indicator
            if profiles.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<profiles.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Theme.accent : Theme.textSecondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
    }

    private func bookletPage(profile: PlantProfile, pageNumber: Int) -> some View {
        VStack(spacing: 0) {
            // Photo area
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let urlString = profile.photoURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            photoPlaceholder
                        }
                    } else {
                        photoPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()

                // Page number badge
                Text("\(pageNumber) / \(profiles.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(12)
            }

            // Info area
            VStack(spacing: 16) {
                // Name and type
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(profile.plantType)
                        .font(.subheadline)
                        .foregroundColor(Theme.accent)
                }
                .padding(.top, 20)

                // Stats row
                HStack(spacing: 0) {
                    statItem(icon: "ruler", label: "Height", value: profile.formattedHeight)
                    Divider()
                        .frame(height: 36)
                        .background(Theme.textSecondary.opacity(0.3))
                    statItem(icon: "clock", label: "Age", value: profile.formattedAge)
                    Divider()
                        .frame(height: 36)
                        .background(Theme.textSecondary.opacity(0.3))
                    statItem(icon: "calendar", label: "Planted", value: shortDate(profile.plantedDate))
                }
                .padding(.horizontal, 8)

                Divider().background(Theme.accent.opacity(0.2))

                // Care info
                VStack(spacing: 10) {
                    if let sun = profile.sunNeeds {
                        careRow(icon: "sun.max.fill", color: .yellow, text: sun)
                    }
                    if let water = profile.waterNeeds {
                        careRow(icon: "drop.fill", color: .blue, text: water)
                    }
                    if let harvest = profile.harvestTime {
                        careRow(icon: "leaf.fill", color: Theme.accent, text: harvest)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
        .greenOutline(cornerRadius: 24)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.05)
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent.opacity(0.2))
        }
    }

    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.accent)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func careRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
            Spacer()
        }
    }

    private func shortDate(_ dateString: String) -> String {
        let parts = dateString.prefix(10).split(separator: "-")
        guard parts.count == 3 else { return dateString }
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let month = Int(parts[1]) ?? 0
        let day = Int(parts[2]) ?? 0
        guard month > 0, month <= 12 else { return dateString }
        return "\(months[month]) \(day)"
    }
}

#Preview {
    NavigationStack {
        ProfileBookletView(
            profiles: PlantProfile.mockList,
            viewModel: ProfilesViewModel()
        )
        .background(Theme.background)
    }
}
