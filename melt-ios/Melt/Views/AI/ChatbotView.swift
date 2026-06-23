import SwiftUI

private let meltSystemPrompt = """
You are Melt Coach — the AI assistant built into the Melt summer OS app for Tej, a college student at University of Michigan who is:
- Cutting to lose fat while keeping muscle (1600-1800 cal/day, 140g protein)
- Lifting 4x/week (upper-focused, reintroducing legs carefully due to cramping)
- Recruiting for investment banking (needs daily IB technical study)
- Avoiding porn and masturbation
- Trying to fix sleep (wake 8am, sleep 11:30pm)
- Playing basketball evenings, volleyball Sundays
- Working on skincare/acne

You give direct, practical, non-judgmental advice. You know the user's goals deeply. You can help with:
- Meal planning and macro advice
- Workout programming and cramp prevention
- IB technical study tips
- Discipline and urge management
- Sleep optimization
- Scheduling and prioritization
- Motivation when behind

Keep responses concise (under 150 words unless asked for more). Be like a smart, blunt friend — not a generic chatbot. Reference his specific situation when relevant.
"""

private let quickSuggestions = [
    "What should I eat now?",
    "I'm behind today",
    "IB study tips",
    "Cramp prevention",
    "I had an urge"
]

struct ChatbotView: View {
    @AppStorage("claudeAPIKey") private var apiKey: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick suggestion chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(quickSuggestions, id: \.self) { suggestion in
                            Button(action: { sendMessage(suggestion) }) {
                                Text(suggestion)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.indigo.opacity(0.12))
                                    .foregroundStyle(Color.indigo)
                                    .cornerRadius(20)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemGroupedBackground))

                Divider()

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                WelcomePromptView()
                                    .padding(.top, 40)
                            }
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isLoading) { _, loading in
                        if loading { scrollToBottom(proxy: proxy) }
                    }
                    .onAppear { scrollProxy = proxy }
                }

                Divider()

                // Input bar
                HStack(spacing: 10) {
                    TextField("Ask Melt Coach...", text: $inputText, axis: .vertical)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .lineLimit(1...5)
                        .onSubmit { handleSend() }

                    Button(action: handleSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? Color.indigo : Color.gray)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Melt Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: clearChat) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(messages.isEmpty)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !apiKey.isEmpty
    }

    private func handleSend() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        sendMessage(text)
    }

    private func sendMessage(_ text: String) {
        guard !isLoading else { return }
        guard !apiKey.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        // Keep last 20 messages in context
        let contextMessages = Array(messages.suffix(20))

        Task {
            do {
                let reply = try await ClaudeAPIClient.chat(
                    messages: contextMessages,
                    systemPrompt: meltSystemPrompt,
                    apiKey: apiKey
                )
                await MainActor.run {
                    messages.append(ChatMessage(role: "assistant", content: reply))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(
                        role: "assistant",
                        content: "Something went wrong: \(error.localizedDescription)"
                    ))
                    isLoading = false
                }
            }
        }
    }

    private func clearChat() {
        messages = []
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }

            if !isUser {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }

            Text(message.content)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.indigo : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .cornerRadius(18, corners: isUser
                    ? [.topLeft, .topRight, .bottomLeft]
                    : [.topLeft, .topRight, .bottomRight]
                )
                .textSelection(.enabled)

            if !isUser { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(.systemGray5))
            .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])

            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation { phase = 1 }
        }
    }
}

// MARK: - Welcome View

struct WelcomePromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(spacing: 4) {
                Text("Melt Coach")
                    .font(.title2.bold())
                Text("Your personal AI coach. Ask me anything about your cut, training, IB prep, or discipline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatbotView()
}
