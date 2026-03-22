import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isUser ? .black : Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Theme.bubbleUser : Theme.bubbleAssistant)
                    .cornerRadius(18)

                Text(message.timestamp.timeFormatted)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            ChatBubbleView(message: ChatMessage.mockConversation[0])
            ChatBubbleView(message: ChatMessage.mockConversation[1])
        }
        .padding()
    }
}
