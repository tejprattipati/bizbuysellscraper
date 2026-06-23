import Foundation

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String  // "user" or "assistant"
    var content: String
    var isStreaming: Bool = false
}

// MARK: - Claude API Client

enum ClaudeAPIError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Claude API."
        case .apiError(let msg): return "API error: \(msg)"
        case .noContent: return "No content returned."
        }
    }
}

struct ClaudeAPIClient {

    // MARK: - Chat

    static func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        apiKey: String
    ) async throws -> String {
        let apiMessages = messages.map { msg in
            ["role": msg.role, "content": msg.content]
        }

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 512,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAPIError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let first = contentArray.first,
              let text = first["text"] as? String else {
            throw ClaudeAPIError.noContent
        }

        return text
    }

    // MARK: - Day Analysis

    static func analyzeDayData(
        calories: Int,
        protein: Int,
        water: Double,
        lifted: Bool,
        liftType: String,
        movementMinutes: Int,
        ibMinutes: Int,
        morningDone: Bool,
        showered: Bool,
        sunscreen: Bool,
        nightDone: Bool,
        pornAvoided: Bool,
        masturbationAvoided: Bool,
        phoneInBedAvoided: Bool,
        score: Int,
        mood: Int,
        energy: Int,
        apiKey: String
    ) async throws -> String {
        let prompt = """
        You are a direct, no-nonsense personal coach for a college student cutting weight while maintaining muscle and recruiting for investment banking.

        Today's data:
        - Calories: \(calories) (target: 1600-1800)
        - Protein: \(protein)g (target: 140g)
        - Water: \(String(format: "%.1f", water))L (target: 3L)
        - Trained: \(lifted ? "Yes — \(liftType.isEmpty ? "session logged" : liftType)" : "No")
        - Movement minutes: \(movementMinutes)
        - IB study minutes: \(ibMinutes)
        - Morning routine done: \(morningDone ? "Yes" : "No")
        - Shower: \(showered ? "Yes" : "No")
        - Sunscreen: \(sunscreen ? "Yes" : "No")
        - Night routine done: \(nightDone ? "Yes" : "No")
        - Discipline: porn avoided \(pornAvoided ? "yes" : "no"), masturbation avoided \(masturbationAvoided ? "yes" : "no"), phone in bed avoided \(phoneInBedAvoided ? "yes" : "no")
        - Mood: \(mood)/5, Energy: \(energy)/5
        - Day score: \(score)/100

        Give a blunt, specific analysis covering:
        1. Nutrition: is the protein:calorie ratio good? What's missing? What to prioritize tomorrow?
        2. Training: was today's training appropriate? Recovery notes?
        3. Overall: what's the most important thing to lock in tomorrow?
        4. One specific meal or food recommendation based on current numbers.

        Keep it under 250 words. Be direct. No fluff. Talk like a knowledgeable friend, not a wellness app.
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 600,
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAPIError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let first = contentArray.first,
              let text = first["text"] as? String else {
            throw ClaudeAPIError.noContent
        }

        return text
    }
}
