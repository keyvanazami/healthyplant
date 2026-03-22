import Foundation

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let chatService = ChatService()
    private let authService = AuthService()

    // MARK: - Send Message

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            userId: authService.userId,
            role: .user,
            content: text,
            timestamp: .now
        )
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        // Prepare assistant message that will be streamed into
        let assistantId = UUID().uuidString
        var assistantContent = ""

        do {
            let stream = chatService.sendMessage(text, userId: authService.userId)

            for try await chunk in stream {
                assistantContent += chunk

                // Update or append the assistant message
                if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[index].content = assistantContent
                } else {
                    let msg = ChatMessage(
                        id: assistantId,
                        userId: authService.userId,
                        role: .assistant,
                        content: assistantContent,
                        timestamp: .now
                    )
                    messages.append(msg)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[AssistantVM] Stream error: \(error)")

            // Add error message if no content was streamed
            if assistantContent.isEmpty {
                let errorMsg = ChatMessage(
                    id: assistantId,
                    userId: authService.userId,
                    role: .assistant,
                    content: "Sorry, I'm having trouble connecting right now. Please try again.",
                    timestamp: .now
                )
                if !messages.contains(where: { $0.id == assistantId }) {
                    messages.append(errorMsg)
                }
            }
        }

        isLoading = false
    }

    // MARK: - Load History

    func loadHistory() async {
        do {
            messages = try await chatService.fetchHistory(userId: authService.userId)
        } catch {
            print("[AssistantVM] Failed to load history: \(error)")
        }
    }

    // MARK: - Clear History

    func clearHistory() async {
        do {
            try await chatService.clearHistory(userId: authService.userId)
            messages.removeAll()
        } catch {
            print("[AssistantVM] Failed to clear history: \(error)")
        }
    }
}
