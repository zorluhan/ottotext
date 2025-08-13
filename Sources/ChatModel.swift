import Foundation
import SwiftUI

struct ChatEntry: Identifiable {
    let id = UUID().uuidString
    let time = Date()
    let role: String // user or assistant or system
    let text: String

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: time)
    }
}

final class ChatModel: ObservableObject {
    @Published var messages: [ChatEntry] = []
    #if DEBUG
    private let embeddedDefaultKey = "AIzaSyAgszoSNpjrLAYj4E0z51WB_K-A0lJUJ0s"
    #else
    private let embeddedDefaultKey = ""
    #endif
    @Published var apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""

    init() {
        if apiKey.isEmpty { apiKey = embeddedDefaultKey }
    }

    // Load simple KB text bundled
    var kbText: String {
        if let url = Bundle.main.url(forResource: "ottoman", withExtension: "txt"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            return String(s.prefix(120_000))
        }
        return ""
    }

    func addUser(_ text: String) {
        messages.append(.init(role: "user", text: text))
    }

    func addAssistant(_ text: String) {
        messages.append(.init(role: "assistant", text: text))
    }

    func addSystem(_ text: String) {
        messages.append(.init(role: "system", text: text))
    }

    func convert(text: String) async {
        guard !apiKey.isEmpty else {
            addAssistant("Please set your Google Gemini API key (key icon).")
            return
        }
        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=\(apiKey)")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Construct JSON per REST API
        let sys = "You are an expert Ottoman Turkish scribe. Convert modern Turkish into Ottoman Arabic script. Return only the Ottoman text."
        let kb = kbText
        let parts: [[String: Any]] = [
            ["text": sys + (kb.isEmpty ? "" : "\n\nReference:\n" + kb)],
            ["text": text]
        ]
        let payload: [String: Any] = [
            "contents": [["role": "user", "parts": parts]],
            "generationConfig": ["temperature": 0.0]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode != 200 { throw NSError(domain: "gemini", code: http.statusCode, userInfo: ["body": String(data: data, encoding: .utf8) ?? ""]) }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                await MainActor.run { self.addAssistant(text.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } else {
                await MainActor.run { self.addAssistant("No text returned.") }
            }
        } catch {
            await MainActor.run {
                self.addAssistant("The system is not available right now. Please try again later.")
                print("Gemini error:", error)
            }
        }
    }
}
