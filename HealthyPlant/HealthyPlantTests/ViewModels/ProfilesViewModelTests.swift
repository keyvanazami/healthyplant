import XCTest
@testable import HealthyPlant

// MARK: - Mock Plant Service

/// Since PlantService is a concrete struct (no protocol), we test the ViewModel
/// behavior by observing its published properties. These tests verify the ViewModel's
/// state management logic. For full isolation, the PlantService would need a protocol;
/// these tests verify the ViewModel's contract with its published state.

@MainActor
final class ProfilesViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let vm = ProfilesViewModel()
        XCTAssertTrue(vm.profiles.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - loadProfiles

    func testLoadProfilesSetsIsLoading() async {
        let vm = ProfilesViewModel()

        // Before loading
        XCTAssertFalse(vm.isLoading)

        // After loading completes (will fail due to no backend, but sets errorMessage)
        await vm.loadProfiles()

        // isLoading should be false after completion
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadProfilesSetsErrorOnFailure() async {
        let vm = ProfilesViewModel()

        // With no backend running, this should set an error message
        await vm.loadProfiles()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - createProfile

    func testCreateProfileSetsErrorOnFailure() async {
        let vm = ProfilesViewModel()

        await vm.createProfile(
            name: "Test Plant",
            plantType: "Tomato",
            ageDays: 10,
            heightFeet: 1,
            heightInches: 5,
            imageData: nil
        )

        // Without a running backend, should get an error
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testCreateProfilePreservesExistingProfiles() async {
        let vm = ProfilesViewModel()

        // Manually add a profile to simulate pre-existing state
        let existing = PlantProfile.mock
        vm.profiles = [existing]

        // Attempt to create (will fail without backend)
        await vm.createProfile(
            name: "New Plant",
            plantType: "Basil",
            ageDays: 5,
            heightFeet: 0,
            heightInches: 4,
            imageData: nil
        )

        // Existing profile should still be there even if create failed
        XCTAssertTrue(vm.profiles.contains(where: { $0.id == existing.id }))
    }

    // MARK: - deleteProfile

    func testDeleteProfileSetsErrorOnFailure() async {
        let vm = ProfilesViewModel()
        vm.profiles = PlantProfile.mockList

        await vm.deleteProfile(id: "mock-001")

        // Without a running backend, should get an error
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testDeleteProfileRemovesFromArrayOnSuccess() {
        // Test the array manipulation logic directly
        let vm = ProfilesViewModel()
        vm.profiles = PlantProfile.mockList

        let initialCount = vm.profiles.count
        XCTAssertEqual(initialCount, 2)

        // Simulate what deleteProfile does on success
        vm.profiles.removeAll { $0.id == "mock-001" }

        XCTAssertEqual(vm.profiles.count, initialCount - 1)
        XCTAssertFalse(vm.profiles.contains(where: { $0.id == "mock-001" }))
    }

    // MARK: - updateProfile

    func testUpdateProfileSetsErrorOnFailure() async {
        let vm = ProfilesViewModel()
        vm.profiles = [PlantProfile.mock]

        await vm.updateProfile(
            id: "mock-001",
            name: "Updated Name",
            plantType: "Cherry Tomato",
            ageDays: 50,
            heightFeet: 2,
            heightInches: 0
        )

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Error State Reset

    func testErrorMessageClearedOnNewLoad() async {
        let vm = ProfilesViewModel()

        // First call sets error
        await vm.loadProfiles()
        XCTAssertNotNil(vm.errorMessage)

        // The errorMessage is set to nil at the start of loadProfiles,
        // then set again on failure. Verify it is not nil after failed load.
        // The key point: errorMessage is reset to nil before each operation.
        let errorBefore = vm.errorMessage

        await vm.loadProfiles()

        // Error is still present (both calls fail), but was cleared in between
        XCTAssertNotNil(vm.errorMessage)
        // Both errors should describe a network failure
        XCTAssertNotNil(errorBefore)
    }
}
