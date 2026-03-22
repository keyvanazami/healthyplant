import Foundation

struct ImageUploadService {
    private let api = APIClient.shared
    private let baseURL = "http://localhost:8000"

    /// Uploads image data and returns the public URL of the uploaded image.
    func uploadImage(_ data: Data) async throws -> String {
        // Step 1: Get a signed upload URL from the backend
        let signedResponse: SignedUploadResponse = try await api.get(
            path: "/api/uploads/signed-url"
        )

        // Step 2: Upload image data directly to GCS using the signed URL
        guard let uploadURL = URL(string: signedResponse.uploadURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        // Step 3: Return the public URL
        return signedResponse.publicURL
    }
}

// MARK: - Response Model

private struct SignedUploadResponse: Decodable {
    let uploadURL: String
    let publicURL: String

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case publicURL = "public_url"
    }
}
