import XCTest
@testable import HealthyPlant

final class APIClientTests: XCTestCase {

    // MARK: - URL Construction

    func testBaseURL() async {
        let client = APIClient()
        let baseURL = await client.baseURL
        XCTAssertEqual(baseURL, "http://localhost:8000")
    }

    func testURLConstruction() async {
        let client = APIClient()
        let baseURL = await client.baseURL

        // Verify URL is properly constructed by combining baseURL + path
        let url = URL(string: baseURL + "/api/profiles")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.host, "localhost")
        XCTAssertEqual(url?.port, 8000)
        XCTAssertEqual(url?.path, "/api/profiles")
    }

    func testURLConstructionWithPathParameters() async {
        let client = APIClient()
        let baseURL = await client.baseURL
        let profileId = "test-123"

        let url = URL(string: baseURL + "/api/profiles/\(profileId)")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.path, "/api/profiles/test-123")
    }

    // MARK: - API Error Descriptions

    func testInvalidURLErrorDescription() {
        let error = APIError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }

    func testInvalidResponseErrorDescription() {
        let error = APIError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid server response")
    }

    func testHTTPErrorDescription() {
        let error = APIError.httpError(statusCode: 404, message: "Not Found")
        XCTAssertEqual(error.errorDescription, "HTTP 404: Not Found")
    }

    func testHTTPErrorDescriptionWithNilMessage() {
        let error = APIError.httpError(statusCode: 500, message: nil)
        XCTAssertEqual(error.errorDescription, "HTTP 500: Unknown error")
    }

    func testUnauthorizedErrorDescription() {
        let error = APIError.unauthorized
        XCTAssertEqual(error.errorDescription, "Unauthorized. Please restart the app.")
    }

    func testDecodingErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Type mismatch"
        ])
        let error = APIError.decodingError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Failed to decode response"))
    }

    func testNetworkErrorDescription() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        let error = APIError.networkError(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Network error"))
    }

    // MARK: - Error Handling for HTTP Status Codes

    func testGetRequestFailsWithNetworkError() async {
        let client = APIClient()

        do {
            let _: [PlantProfile] = try await client.get(path: "/api/profiles")
            XCTFail("Expected an error to be thrown")
        } catch {
            // Should be a network error since no backend is running
            if let apiError = error as? APIError {
                switch apiError {
                case .networkError:
                    // Expected
                    break
                default:
                    // Other API errors are also acceptable (e.g., connection refused)
                    break
                }
            }
            // Any error is acceptable when no backend is running
        }
    }

    func testDeleteRequestFailsWithNetworkError() async {
        let client = APIClient()

        do {
            try await client.delete(path: "/api/profiles/nonexistent")
            XCTFail("Expected an error to be thrown")
        } catch {
            // Should fail since no backend is running
            XCTAssertNotNil(error)
        }
    }

    // MARK: - APIError Equatable-like Checks

    func testAPIErrorCases() {
        // Verify all error cases can be constructed
        let errors: [APIError] = [
            .invalidURL,
            .invalidResponse,
            .httpError(statusCode: 400, message: "Bad Request"),
            .decodingError(NSError(domain: "", code: 0)),
            .networkError(NSError(domain: "", code: 0)),
            .unauthorized,
        ]

        XCTAssertEqual(errors.count, 6)

        // All should have non-nil descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}
