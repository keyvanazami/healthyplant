import Foundation

struct ChatService {
    private let baseURL = "https://healthyplant-api-prod-680872497777.us-central1.run.app"
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
                    guard let url = URL(string: "\(baseURL)/api/v1/chat") else {
                        continuation.finish(throwing: APIError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(userId, forHTTPHeaderField: "X-User-ID")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let body = ChatRequest(content: text)
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
                            let jsonString = String(line.dropFirst(6))
                            if let jsonData = jsonString.data(using: .utf8),
                               let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                if let type = parsed["type"] as? String {
                                    if type == "chunk", let content = parsed["content"] as? String {
                                        continuation.yield(content)
                                    } else if type == "done" {
                                        break
                                    }
                                }
                            }
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
        guard let url = URL(string: "\(baseURL)/api/v1/chat/history") else {
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

        let historyResponse = try decoder.decode(ChatHistoryResponse.self, from: data)
        return historyResponse.messages
    }

    // MARK: - Clear Chat History

    func clearHistory(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/chat/history") else {
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

// MARK: - Request / Response Bodies

private struct ChatRequest: Encodable {
    let content: String
}

private struct ChatHistoryResponse: Decodable {
    let messages: [ChatMessage]
}
