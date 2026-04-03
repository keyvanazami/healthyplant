import Foundation

struct ImageUploadService {
    private var baseURL: String { AppEnvironment.current.baseURL }

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

    /// Identifies the plant in an image using AI vision. Returns the identified type.
    func identifyPlant(_ data: Data) async throws -> PlantIdentifyResult {
        guard let url = URL(string: "\(baseURL)/api/v1/photos/identify") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let userId = UserDefaults.standard.string(forKey: "hp_user_id") ?? "unknown"
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")

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

        return try JSONDecoder().decode(PlantIdentifyResult.self, from: responseData)
    }
    /// Identifies the plant and returns detailed info: history, origin, care, fun facts.
    func lookupPlant(_ data: Data) async throws -> PlantLookupResult {
        guard let url = URL(string: "\(baseURL)/api/v1/photos/lookup") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        let userId = UserDefaults.standard.string(forKey: "hp_user_id") ?? "unknown"
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")

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

        return try JSONDecoder().decode(PlantLookupResult.self, from: responseData)
    }
}

private struct PhotoUploadResponse: Decodable {
    let url: String
}

struct PlantIdentifyResult: Decodable {
    let plantType: String
    let confidence: String
    let description: String
}

struct PlantLookupResult: Decodable {
    let plantType: String
    let confidence: String
    let description: String
    let origin: String
    let history: String
    let funFacts: [String]
    let careSummary: String
    let sunNeeds: String
    let waterNeeds: String
    let difficulty: String
}
