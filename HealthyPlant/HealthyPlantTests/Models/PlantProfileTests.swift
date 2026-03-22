import XCTest
@testable import HealthyPlant

final class PlantProfileTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = PlantProfile(
            id: "test-001",
            userId: "user-001",
            name: "Tommy Tomato",
            plantType: "Tomato",
            photoURL: "https://example.com/photo.jpg",
            ageDays: 45,
            plantedDate: Date(timeIntervalSince1970: 1_700_000_000),
            heightFeet: 2,
            heightInches: 6,
            sunNeeds: "Full sun",
            waterNeeds: "Every 2-3 days",
            harvestTime: "60-80 days",
            aiLastUpdated: Date(timeIntervalSince1970: 1_700_100_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_100_000)
        )

        let data = try encoder.encode(profile)
        let decoded = try decoder.decode(PlantProfile.self, from: data)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.userId, profile.userId)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.plantType, profile.plantType)
        XCTAssertEqual(decoded.photoURL, profile.photoURL)
        XCTAssertEqual(decoded.ageDays, profile.ageDays)
        XCTAssertEqual(decoded.heightFeet, profile.heightFeet)
        XCTAssertEqual(decoded.heightInches, profile.heightInches)
        XCTAssertEqual(decoded.sunNeeds, profile.sunNeeds)
        XCTAssertEqual(decoded.waterNeeds, profile.waterNeeds)
        XCTAssertEqual(decoded.harvestTime, profile.harvestTime)
    }

    func testCodableRoundTripWithNilOptionals() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = PlantProfile(
            id: "test-002",
            userId: "user-001",
            name: "Basil",
            plantType: "Basil",
            photoURL: nil,
            ageDays: 10,
            plantedDate: Date(timeIntervalSince1970: 1_700_000_000),
            heightFeet: 0,
            heightInches: 4,
            sunNeeds: "Partial sun",
            waterNeeds: "Keep moist",
            harvestTime: nil,
            aiLastUpdated: nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try encoder.encode(profile)
        let decoded = try decoder.decode(PlantProfile.self, from: data)

        XCTAssertNil(decoded.photoURL)
        XCTAssertNil(decoded.harvestTime)
        XCTAssertNil(decoded.aiLastUpdated)
        XCTAssertEqual(decoded.name, "Basil")
    }

    // MARK: - formattedHeight

    func testFormattedHeight() {
        let profile = PlantProfile(
            id: "test-003",
            userId: "user-001",
            name: "Test",
            plantType: "Test",
            photoURL: nil,
            ageDays: 1,
            plantedDate: .now,
            heightFeet: 2,
            heightInches: 6,
            sunNeeds: "",
            waterNeeds: "",
            harvestTime: nil,
            aiLastUpdated: nil,
            createdAt: .now,
            updatedAt: .now
        )

        XCTAssertEqual(profile.formattedHeight, "2ft 6in")
    }

    func testFormattedHeightZero() {
        let profile = PlantProfile(
            id: "test-004",
            userId: "user-001",
            name: "Seedling",
            plantType: "Tomato",
            photoURL: nil,
            ageDays: 1,
            plantedDate: .now,
            heightFeet: 0,
            heightInches: 3,
            sunNeeds: "",
            waterNeeds: "",
            harvestTime: nil,
            aiLastUpdated: nil,
            createdAt: .now,
            updatedAt: .now
        )

        XCTAssertEqual(profile.formattedHeight, "0ft 3in")
    }

    // MARK: - Date Handling

    func testDatePreservation() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let plantedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_700_100_000)

        let profile = PlantProfile(
            id: "test-005",
            userId: "user-001",
            name: "Date Test",
            plantType: "Rose",
            photoURL: nil,
            ageDays: 30,
            plantedDate: plantedDate,
            heightFeet: 1,
            heightInches: 0,
            sunNeeds: "Full sun",
            waterNeeds: "Weekly",
            harvestTime: nil,
            aiLastUpdated: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let data = try encoder.encode(profile)
        let decoded = try decoder.decode(PlantProfile.self, from: data)

        // ISO8601 rounds to seconds, so compare with tolerance
        XCTAssertEqual(
            decoded.plantedDate.timeIntervalSince1970,
            plantedDate.timeIntervalSince1970,
            accuracy: 1.0
        )
        XCTAssertEqual(
            decoded.createdAt.timeIntervalSince1970,
            createdAt.timeIntervalSince1970,
            accuracy: 1.0
        )
        XCTAssertEqual(
            decoded.updatedAt.timeIntervalSince1970,
            updatedAt.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    // MARK: - Equatable

    func testEquatable() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let profile1 = PlantProfile(
            id: "same-id", userId: "user-001", name: "Plant",
            plantType: "Tomato", photoURL: nil, ageDays: 10,
            plantedDate: date, heightFeet: 1, heightInches: 0,
            sunNeeds: "Full", waterNeeds: "Daily", harvestTime: nil,
            aiLastUpdated: nil, createdAt: date, updatedAt: date
        )
        let profile2 = profile1

        XCTAssertEqual(profile1, profile2)
    }

    // MARK: - Mock

    func testMockIsValid() {
        let mock = PlantProfile.mock
        XCTAssertEqual(mock.id, "mock-001")
        XCTAssertEqual(mock.name, "Tommy Tomato")
        XCTAssertEqual(mock.plantType, "Tomato")
        XCTAssertFalse(mock.formattedHeight.isEmpty)
    }

    func testMockListIsNotEmpty() {
        XCTAssertFalse(PlantProfile.mockList.isEmpty)
        XCTAssertEqual(PlantProfile.mockList.count, 2)
    }
}
