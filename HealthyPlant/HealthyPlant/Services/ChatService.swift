import Foundation

struct ChatService {
    private let baseURL = "http://localhost:8000"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Send Message (SSE Streaming)

    func sendMessage(_ text: String, userId: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/api/chat/stream") else {
                        continuation.finish(throwing: APIError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(userId, forHTTPHeaderField: "X-User-ID")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let body = ChatRequest(message: text, userId: userId)
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    // Parse SSE stream
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" {
                                break
                            }
                            continuation.yield(data)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Fetch Chat History

    func fetchHistory(userId: String) async throws -> [ChatMessage] {
        guard let url = URL(string: "\(baseURL)/api/chat/history") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode([ChatMessage].self, from: data)
    }

    // MARK: - Clear Chat History

    func clearHistory(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/chat/history") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }
}

// MARK: - Request Body

private struct ChatRequest: Encodable {
    let message: String
    let userId: String
}
