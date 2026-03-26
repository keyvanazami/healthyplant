import Foundation

struct PlantProfile: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    var name: String
    var plantType: String
    var photoURL: String?
    var ageDays: Int
    var plantedDate: String
    var heightFeet: Int
    var heightInches: Int
    var sunNeeds: String?
    var waterNeeds: String?
    var harvestTime: String?
    var wateringFrequencyDays: Int?
    var sunHoursMin: Int?
    var sunHoursMax: Int?
    var aiLastUpdated: String?
    let createdAt: String
    var updatedAt: String

    /// Formatted height string, e.g. "2ft 6in"
    var formattedHeight: String {
        Int.formatHeight(feet: heightFeet, inches: heightInches)
    }

    /// Formatted age string, e.g. "1yr 3mo 5d"
    var formattedAge: String {
        let years = ageDays / 365
        let months = (ageDays % 365) / 30
        let days = ageDays % 30
        var parts: [String] = []
        if years > 0 { parts.append("\(years)yr") }
        if months > 0 { parts.append("\(months)mo") }
        if days > 0 || parts.isEmpty { parts.append("\(days)d") }
        return parts.joined(separator: " ")
    }

    // MARK: - Preview Mock

    static let mock = PlantProfile(
        id: "mock-001",
        userId: "user-001",
        name: "Tommy Tomato",
        plantType: "Tomato",
        photoURL: nil,
        ageDays: 45,
        plantedDate: "2026-02-05",
        heightFeet: 1,
        heightInches: 8,
        sunNeeds: "Full sun (6-8 hours)",
        waterNeeds: "Water every 2-3 days",
        harvestTime: "60-80 days from transplant",
        wateringFrequencyDays: 3,
        sunHoursMin: 6,
        sunHoursMax: 8,
        aiLastUpdated: "2026-03-22T00:00:00+00:00",
        createdAt: "2026-02-05T00:00:00+00:00",
        updatedAt: "2026-03-22T00:00:00+00:00"
    )

    static let mockList: [PlantProfile] = [
        mock,
        PlantProfile(
            id: "mock-002",
            userId: "user-001",
            name: "Basil Buddy",
            plantType: "Basil",
            photoURL: nil,
            ageDays: 20,
            plantedDate: "2026-03-02",
            heightFeet: 0,
            heightInches: 10,
            sunNeeds: "Partial to full sun",
            waterNeeds: "Keep soil moist",
            harvestTime: "3-4 weeks for first harvest",
            wateringFrequencyDays: nil,
            sunHoursMin: nil,
            sunHoursMax: nil,
            aiLastUpdated: "2026-03-22T00:00:00+00:00",
            createdAt: "2026-03-02T00:00:00+00:00",
            updatedAt: "2026-03-22T00:00:00+00:00"
        ),
    ]
}
