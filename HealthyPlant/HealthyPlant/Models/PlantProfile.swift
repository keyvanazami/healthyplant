import Foundation

struct PlantProfile: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    var name: String
    var plantType: String
    var photoURL: String?
    var ageDays: Int
    var plantedDate: Date
    var heightFeet: Int
    var heightInches: Int
    var sunNeeds: String
    var waterNeeds: String
    var harvestTime: String?
    var wateringFrequencyDays: Int?
    var sunHoursMin: Int?
    var sunHoursMax: Int?
    var aiLastUpdated: Date?
    let createdAt: Date
    var updatedAt: Date

    /// Formatted height string, e.g. "2ft 6in"
    var formattedHeight: String {
        Int.formatHeight(feet: heightFeet, inches: heightInches)
    }

    // MARK: - Preview Mock

    static let mock = PlantProfile(
        id: "mock-001",
        userId: "user-001",
        name: "Tommy Tomato",
        plantType: "Tomato",
        photoURL: nil,
        ageDays: 45,
        plantedDate: Calendar.current.date(byAdding: .day, value: -45, to: .now) ?? .now,
        heightFeet: 1,
        heightInches: 8,
        sunNeeds: "Full sun (6-8 hours)",
        waterNeeds: "Water every 2-3 days",
        harvestTime: "60-80 days from transplant",
        wateringFrequencyDays: 3,
        sunHoursMin: 6,
        sunHoursMax: 8,
        aiLastUpdated: .now,
        createdAt: Calendar.current.date(byAdding: .day, value: -45, to: .now) ?? .now,
        updatedAt: .now
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
            plantedDate: Calendar.current.date(byAdding: .day, value: -20, to: .now) ?? .now,
            heightFeet: 0,
            heightInches: 10,
            sunNeeds: "Partial to full sun",
            waterNeeds: "Keep soil moist",
            harvestTime: "3-4 weeks for first harvest",
            wateringFrequencyDays: nil,
            sunHoursMin: nil,
            sunHoursMax: nil,
            aiLastUpdated: .now,
            createdAt: Calendar.current.date(byAdding: .day, value: -20, to: .now) ?? .now,
            updatedAt: .now
        ),
    ]
}
