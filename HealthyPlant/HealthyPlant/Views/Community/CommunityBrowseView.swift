import SwiftUI

struct CommunityBrowseView: View {
    @ObservedObject var viewModel: CommunityViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.communityPlants.isEmpty && viewModel.plantTypes.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Theme.accent)
                Spacer()
            } else if !viewModel.isLoading && viewModel.communityPlants.isEmpty && viewModel.plantTypes.isEmpty {
                emptyState
            } else {
                // Filter chips — outside vertical scroll to avoid nested scroll tap issues
                filterChips
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                // Plant grid
                ScrollView(.vertical, showsIndicators: false) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if viewModel.communityPlants.isEmpty {
                        Text("No plants shared for this type yet")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.communityPlants) { plant in
                                NavigationLink(value: plant) {
                                    CommunityPlantCard(plant: plant)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await viewModel.loadCommunity()
                }
            }
        }
        .task {
            await viewModel.loadCommunity()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent.opacity(0.4))

            Text("No Shared Plants Yet")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)

            Text("Share your plants from the Profiles tab to get started!")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(label: "All", isSelected: viewModel.selectedPlantType == nil) {
                    Task { await viewModel.filterByType(nil) }
                }

                ForEach(viewModel.plantTypes, id: \.self) { type in
                    filterChip(label: type, isSelected: viewModel.selectedPlantType == type) {
                        Task { await viewModel.filterByType(type) }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Text(label)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isSelected ? .black : Theme.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.accent : Color.clear)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
    }
}

// MARK: - Community Plant Card

struct CommunityPlantCard: View {
    let plant: CommunityPlant

    var body: some View {
        VStack(spacing: 8) {
            // Photo
            if let photoURL = plant.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    plantPlaceholder
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
            } else {
                plantPlaceholder
                    .frame(height: 120)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text("by \(plant.displayName)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.accent)
                    Text("\(plant.commentCount)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Text(plant.plantType)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.accent)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .greenOutline(cornerRadius: 16)
    }

    private var plantPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.05)
            Image(systemName: "leaf.fill")
                .font(.system(size: 30))
                .foregroundColor(Theme.accent.opacity(0.3))
        }
    }
}
