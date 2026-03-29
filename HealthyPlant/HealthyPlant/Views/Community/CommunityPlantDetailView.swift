import SwiftUI

struct CommunityPlantDetailView: View {
    let plant: CommunityPlant
    @ObservedObject var viewModel: CommunityViewModel
    @State private var commentText = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Photo
                    photoSection

                    // Plant info
                    infoSection

                    // Care info
                    careSection

                    // Comments
                    commentsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }

            // Comment input pinned to bottom
            VStack {
                Spacer()
                commentInput
            }
        }
        .navigationTitle(plant.name)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadComments(communityId: plant.id)
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        Group {
            if let photoURL = plant.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.white.opacity(0.05)
                        ProgressView().tint(Theme.accent)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipped()
                .cornerRadius(16)
                .greenOutline(cornerRadius: 16)
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(plant.plantType)
                    .font(.headline)
                    .foregroundColor(Theme.accent)

                Spacer()

                Text("by \(plant.displayName)")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: 20) {
                infoItem(label: "Height", value: plant.formattedHeight)
                infoItem(label: "Age", value: "\(plant.ageDays)d")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .greenOutline(cornerRadius: 12)
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - Care

    private var careSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Care Info", systemImage: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.accent)

            if let sun = plant.sunNeeds {
                careRow(icon: "sun.max.fill", color: .yellow, text: sun)
            }
            if let water = plant.waterNeeds {
                careRow(icon: "drop.fill", color: .blue, text: water)
            }
            if let harvest = plant.harvestTime {
                careRow(icon: "clock.fill", color: .orange, text: harvest)
            }

            if plant.sunNeeds == nil && plant.waterNeeds == nil && plant.harvestTime == nil {
                Text("No care data available yet")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .greenOutline(cornerRadius: 12)
    }

    private func careRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments (\(viewModel.comments.count))")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if viewModel.isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView().tint(Theme.accent)
                    Spacer()
                }
            } else if viewModel.comments.isEmpty {
                Text("No comments yet. Be the first to ask a question!")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.comments) { comment in
                    commentRow(comment)
                }
            }
        }
    }

    private func commentRow(_ comment: CommunityComment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)

                Spacer()

                Text(formatDate(comment.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }

            Text(comment.content)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }

    private func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let relative = DateFormatter()
        relative.dateStyle = .short
        relative.timeStyle = .none
        return relative.string(from: date)
    }

    // MARK: - Comment Input

    private var commentInput: some View {
        HStack(spacing: 10) {
            TextField("Ask a question...", text: $commentText)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(20)

            Button {
                let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                commentText = ""
                Task {
                    await viewModel.postComment(communityId: plant.id, content: text)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.textSecondary : Theme.accent)
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background.opacity(0.95))
    }
}
