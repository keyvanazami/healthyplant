import Foundation

struct ImageUploadService {
    private let baseURL = "https://healthyplant-api-prod-680872497777.us-central1.run.app"

    /// Uploads image data directly to the backend. Returns the public URL.
    func uploadImage(_ data: Data) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/v1/photos/upload") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let userId = UserDefaults.standard.string(forKey: "hp_user_id") ?? "unknown"
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")

        // Build multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"plant.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let result = try JSONDecoder().decode(PhotoUploadResponse.self, from: responseData)
        return result.url
    }
}

private struct PhotoUploadResponse: Decodable {
    let url: String
}
