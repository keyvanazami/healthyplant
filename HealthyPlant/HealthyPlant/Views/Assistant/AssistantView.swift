import SwiftUI

struct AssistantView: View {
    @StateObject private var viewModel = AssistantViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    ChatBubbleView(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .id("loading")
                                }
                            }
                            .padding()
                            .padding(.bottom, 8)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: viewModel.isLoading) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                    }

                    Divider().background(Theme.accent.opacity(0.3))

                    // Input bar
                    inputBar
                }
                .padding(.bottom, 80) // Tab bar space
            }
            .navigationTitle("Assistant Gardener")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.loadHistory()
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about your plants...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(20)
                .lineLimit(1...4)
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(canSend ? Theme.accent : Theme.textSecondary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.background)
    }

    private var canSend: Bool {
        !messageText.isBlank && !viewModel.isLoading
    }

    private func sendMessage() {
        guard canSend else { return }
        let text = messageText.trimmed
        messageText = ""
        isInputFocused = false

        Task {
            await viewModel.sendMessage(text)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isLoading {
                proxy.scrollTo("loading", anchor: .bottom)
            } else if let lastId = viewModel.messages.last?.id {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var dotIndex = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.accent.opacity(index == dotIndex ? 1.0 : 0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bubbleAssistant)
        .cornerRadius(16)
        .onReceive(timer) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

#Preview {
    AssistantView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
