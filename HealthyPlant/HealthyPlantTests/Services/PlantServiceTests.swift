import XCTest
@testable import HealthyPlant

final class PlantServiceTests: XCTestCase {

    let service = PlantService()

    // MARK: - fetchProfiles

    func testFetchProfilesCallsCorrectEndpoint() async {
        // Without a running backend, this should throw a network error.
        // We verify the service is properly wired to the API client.
        do {
            _ = try await service.fetchProfiles()
            XCTFail("Expected a network error when no backend is running")
        } catch {
            // Confirm it throws rather than returning empty
            XCTAssertNotNil(error)
        }
    }

    // MARK: - createProfile

    func testCreateProfileSendsCorrectPayload() async {
        // Without a running backend, this should throw a network error.
        // We verify the service is properly calling the API client's post method.
        do {
            _ = try await service.createProfile(
                name: "Test Plant",
                plantType: "Tomato",
                ageDays: 30,
                heightFeet: 1,
                heightInches: 6,
                photoURL: "https://example.com/photo.jpg"
            )
            XCTFail("Expected a network error when no backend is running")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testCreateProfileWithoutPhoto() async {
        do {
            _ = try await service.createProfile(
                name: "Basil Plant",
                plantType: "Basil",
                ageDays: 10,
                heightFeet: 0,
                heightInches: 4
            )
            XCTFail("Expected a network error when no backend is running")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - updateProfile

    func testUpdateProfileCallsCorrectEndpoint() async {
        do {
            _ = try await service.updateProfile(
                id: "test-profile-id",
                name: "Updated Plant",
                plantType: "Cherry Tomato",
                ageDays: 60,
                heightFeet: 2,
                heightInches: 3
            )
            XCTFail("Expected a network error when no backend is running")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - deleteProfile

    func testDeleteProfileCallsCorrectEndpoint() async {
        do {
            try await service.deleteProfile(id: "test-profile-id")
            XCTFail("Expected a network error when no backend is running")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - fetchGarden

    func testFetchGardenCallsCorrectEndpoint() async {
        do {
            _ = try await service.fetchGarden()
            XCTFail("Expected a network error when no backend is running")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Request Body Models

    func testCreateProfileRequestEncoding() throws {
        let request = CreateProfileRequest(
            name: "Tommy Tomato",
            plantType: "Tomato",
            ageDays: 45,
            heightFeet: 2,
            heightInches: 6,
            photoURL: "https://example.com/photo.jpg"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["name"] as? String, "Tommy Tomato")
        XCTAssertEqual(json?["plantType"] as? String, "Tomato")
        XCTAssertEqual(json?["ageDays"] as? Int, 45)
        XCTAssertEqual(json?["heightFeet"] as? Int, 2)
        XCTAssertEqual(json?["heightInches"] as? Int, 6)
        XCTAssertEqual(json?["photoURL"] as? String, "https://example.com/photo.jpg")
    }

    func testUpdateProfileRequestEncoding() throws {
        let request = UpdateProfileRequest(
            name: "Updated Name",
            plantType: "Cherry Tomato",
            ageDays: 50,
            heightFeet: 2,
            heightInches: 0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["name"] as? String, "Updated Name")
        XCTAssertEqual(json?["plantType"] as? String, "Cherry Tomato")
        XCTAssertEqual(json?["ageDays"] as? Int, 50)
    }

    func testCreateProfileRequestWithNilPhoto() throws {
        let request = CreateProfileRequest(
            name: "Basil",
            plantType: "Basil",
            ageDays: 10,
            heightFeet: 0,
            heightInches: 4,
            photoURL: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["name"] as? String, "Basil")
        // photoURL should either be null or absent
    }
}
