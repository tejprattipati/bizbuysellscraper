import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String   // "user" or "assistant"
    var content: String
    var isStreaming: Bool = false
}

struct NutritionAnalysis: Codable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var water: Double
    var meals: [AnalyzedMeal]
    var rawText: String
}

struct AnalyzedMeal: Codable {
    var name: String
    var calories: Int
    var protein: Int
}

class ClaudeAPIClient {
    static func analyzeNutritionScreenshot(
        imageData: Data,
        apiKey: String
    ) async throws -> NutritionAnalysis {
        let base64Image = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1024,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64Image
                        ]
                    ],
                    [
                        "type": "text",
                        "text": """
                        Analyze this MyFitnessPal nutrition diary screenshot.
                        Extract and return ONLY valid JSON with this exact structure:
                        {
                          "calories": <total calories as integer>,
                          "protein": <total protein grams as integer>,
                          "carbs": <total carbs grams as integer>,
                          "fat": <total fat grams as integer>,
                          "water": <water in liters as decimal, 0 if not shown>,
                          "meals": [
                            {"name": "<meal name>", "calories": <int>, "protein": <int>}
                          ],
                          "rawText": "<brief summary of what you see>"
                        }
                        Return only the JSON, no other text.
                        """
                    ]
                ]
            ]]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (responseJSON?["content"] as? [[String: Any]])?.first
        let text = content?["text"] as? String ?? ""

        // Parse the JSON from Claude's response
        guard let jsonData = text.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(NutritionAnalysis.self, from: jsonData) else {
            return NutritionAnalysis(calories: 0, protein: 0, carbs: 0, fat: 0, water: 0, meals: [], rawText: text)
        }

        return analysis
    }

    // MARK: - Chat

    static func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        apiKey: String
    ) async throws -> String {
        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }

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

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first
        return content?["text"] as? String ?? ""
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
        nightDone: Bool,
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
        - Trained: \(lifted ? "Yes — \(liftType)" : "No")
        - Movement minutes: \(movementMinutes)
        - IB study minutes: \(ibMinutes)
        - Morning routine done: \(morningDone ? "Yes" : "No")
        - Night routine done: \(nightDone ? "Yes" : "No")
        - Mood: \(mood)/5, Energy: \(energy)/5
        - Day score: \(score)/100

        Give a blunt, specific analysis covering:
        1. Nutrition: protein:calorie ratio, what's missing, what to prioritize tomorrow
        2. Training: was today appropriate? Recovery notes?
        3. Overall: most important thing to lock in tomorrow
        4. One specific meal recommendation based on current numbers

        Under 250 words. Direct. No fluff. Talk like a knowledgeable friend, not a wellness app.
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

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first
        return content?["text"] as? String ?? "Analysis unavailable."
    }
}
