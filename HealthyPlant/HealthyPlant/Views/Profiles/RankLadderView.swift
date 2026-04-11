import SwiftUI

struct RankLadderView: View {
    let currentRank: GardeningRank
    let score: Int
    @Environment(\.dismiss) private var dismiss

    private var nextRank: GardeningRank? {
        let all = GardeningRank.all
        guard let idx = all.firstIndex(where: { $0.name == currentRank.name }),
              idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        // Current rank hero
                        VStack(spacing: 12) {
                            Image(systemName: currentRank.icon)
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(currentRank.color)
                                .shadow(color: currentRank.color.opacity(0.4), radius: 12)
                            Text(currentRank.name)
                                .font(.title.weight(.bold))
                                .foregroundColor(currentRank.color)
                            Text("Your score: \(score)")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            if let next = nextRank {
                                let needed = next.minScore - score
                                Text("\(needed) points to \(next.name)")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(8)
                            } else {
                                Text("Maximum rank achieved")
                                    .font(.caption)
                                    .foregroundColor(currentRank.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(currentRank.color.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 32)

                        // Rank ladder
                        VStack(spacing: 0) {
                            ForEach(Array(GardeningRank.all.reversed().enumerated()), id: \.element.name) { _, rank in
                                let isCurrent = rank.name == currentRank.name
                                let isUnlocked = score >= rank.minScore

                                HStack(spacing: 16) {
                                    // Icon
                                    ZStack {
                                        Circle()
                                            .fill(isUnlocked ? rank.color.opacity(0.15) : Color.white.opacity(0.04))
                                            .frame(width: 48, height: 48)
                                        if isCurrent {
                                            Circle()
                                                .stroke(rank.color, lineWidth: 2)
                                                .frame(width: 48, height: 48)
                                        }
                                        Image(systemName: isUnlocked ? rank.icon : "lock.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(isUnlocked ? rank.color : .gray.opacity(0.4))
                                    }

                                    // Name + score
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(rank.name)
                                                .font(.body.weight(isCurrent ? .bold : .regular))
                                                .foregroundColor(isUnlocked ? Theme.textPrimary : Theme.textSecondary.opacity(0.5))
                                            if isCurrent {
                                                Text("YOU")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(rank.color)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(rank.color.opacity(0.15))
                                                    .cornerRadius(4)
                                            }
                                        }
                                        Text("\(rank.minScore)+ points")
                                            .font(.caption)
                                            .foregroundColor(isUnlocked ? Theme.textSecondary : Theme.textSecondary.opacity(0.4))
                                    }

                                    Spacer()

                                    // Progress / checkmark
                                    if isCurrent && nextRank != nil {
                                        let next = nextRank!
                                        let progress = Double(score - rank.minScore) / Double(next.minScore - rank.minScore)
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                                                .frame(width: 28, height: 28)
                                            Circle()
                                                .trim(from: 0, to: progress)
                                                .stroke(rank.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                                .frame(width: 28, height: 28)
                                                .rotationEffect(.degrees(-90))
                                        }
                                    } else if isUnlocked {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(rank.color)
                                            .font(.title3)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(isCurrent ? rank.color.opacity(0.06) : Color.clear)

                                if rank.name != GardeningRank.all[0].name {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(height: 1)
                                        .padding(.leading, 88)
                                }
                            }
                        }

                        // Scoring explanation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How points work")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.textSecondary)
                            Text("• +30 points per plant added")
                            Text("• +1 point per day each plant is alive")
                        }
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Gardening Rank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
}
