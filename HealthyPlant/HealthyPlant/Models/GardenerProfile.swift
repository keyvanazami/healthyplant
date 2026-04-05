import Foundation
import SwiftUI

// MARK: - Gardening Rank

struct GardeningRank {
    let name: String
    let icon: String      // SF Symbol
    let color: Color
    let minScore: Int

    static func compute(profiles: [PlantProfile]) -> GardeningRank {
        let score = profiles.reduce(0) { $0 + $1.ageDays } + profiles.count * 30
        return all.last(where: { score >= $0.minScore }) ?? all[0]
    }

    static let all: [GardeningRank] = [
        GardeningRank(name: "Seedling",        icon: "leaf",               color: .green,  minScore: 0),
        GardeningRank(name: "Sprout",          icon: "leaf.fill",          color: .green,  minScore: 50),
        GardeningRank(name: "Grower",          icon: "tree",               color: .teal,   minScore: 200),
        GardeningRank(name: "Gardener",        icon: "tree.fill",          color: .teal,   minScore: 500),
        GardeningRank(name: "Green Thumb",     icon: "hand.thumbsup.fill", color: .yellow, minScore: 1000),
        GardeningRank(name: "Expert",          icon: "star.fill",          color: .orange, minScore: 2000),
        GardeningRank(name: "Master Gardener", icon: "trophy.fill",        color: Color(red: 1, green: 0.84, blue: 0), minScore: 4000),
    ]
}

enum GardeningExperience: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case expert

    var id: String { rawValue }

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .expert: return "Expert"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "seedling"
        case .intermediate: return "leaf.fill"
        case .expert: return "tree.fill"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Just starting out"
        case .intermediate: return "A few seasons in"
        case .expert: return "Seasoned grower"
        }
    }
}

struct GardenerProfile: Codable, Equatable {
    let userId: String
    var displayName: String?
    var bio: String?
    var experienceLevel: GardeningExperience?
    var avatarURL: String?
    var isPublic: Bool
    var followerCount: Int
    var followingCount: Int
    var isFollowing: Bool

    static let empty = GardenerProfile(
        userId: "",
        displayName: nil,
        bio: nil,
        experienceLevel: nil,
        avatarURL: nil,
        isPublic: true,
        followerCount: 0,
        followingCount: 0,
        isFollowing: false
    )
}

struct FollowResponse: Codable {
    let isFollowing: Bool
    let followerCount: Int
}
