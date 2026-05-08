import Foundation

// MARK: - Notion API Service
// Handles all communication with the Notion API v1
// Replace YOUR_NOTION_INTEGRATION_TOKEN in NotionConfig below.

class NotionService {
    static let shared = NotionService()

    private let baseURL = "https://api.notion.com/v1"
    private let notionVersion = "2022-06-28"

    // MARK: - Database IDs
    // These are the databases created in your Notion AI WORKSPACE
    struct DatabaseIDs {
        // Notion database PAGE IDs (not collection/data-source IDs)
        // These match the actual database pages under AI WORKSPACE
        static let morningRoutineTracker = "e8320b3b-c3d0-4221-8de9-01c8ecffab57"
        static let dailyHealthTracker    = "871a178c-db27-4d2f-9ac9-ab87fc368da7"
        static let recipesAndShakes      = "4aa371f3-86a6-48f7-bd8e-49b379d4946a"
        static let sleepTracker          = "a846b573-e33d-4f73-98a7-114afee8b7e1"
    }

    // MARK: - Request Builder
    private func makeRequest(path: String, method: String = "GET", body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(NotionConfig.integrationToken)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    // MARK: - Connection Test
    /// Call this on app launch to verify the token is valid.
    func testConnection() async -> Bool {
        guard let request = makeRequest(path: "/users/me") else { return false }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    print("[NotionService] ✅ Connected successfully")
                    return true
                } else {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    print("[NotionService] ❌ Connection failed (\(http.statusCode)): \(body)")
                    return false
                }
            }
        } catch {
            print("[NotionService] ❌ Network error: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Query Database
    func queryDatabase(databaseId: String, filter: [String: Any]? = nil) async throws -> [[String: Any]] {
        guard var request = makeRequest(path: "/databases/\(databaseId)/query", method: "POST") else {
            throw NSError(domain: "NotionService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var bodyDict: [String: Any] = [:]
        if let filter = filter { bodyDict["filter"] = filter }
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[NotionService] queryDatabase error \(http.statusCode): \(body)")
            throw NSError(domain: "NotionService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: body])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }
        return results
    }

    // MARK: - Create Page
    func createPage(databaseId: String, properties: [String: Any]) async throws -> String? {
        guard let request = makeRequest(path: "/pages", method: "POST", body: [
            "parent": ["database_id": databaseId],
            "properties": properties
        ]) else { return nil }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[NotionService] createPage error \(http.statusCode): \(body)")
            throw NSError(domain: "NotionService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: body])
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let pageId = json?["id"] as? String
        print("[NotionService] ✅ Created page: \(pageId ?? "unknown")")
        return pageId
    }

    // MARK: - Update Page
    func updatePage(pageId: String, properties: [String: Any]) async throws {
        guard let request = makeRequest(path: "/pages/\(pageId)", method: "PATCH", body: [
            "properties": properties
        ]) else { return }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[NotionService] updatePage error \(http.statusCode): \(body)")
            throw NSError(domain: "NotionService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: body])
        }
        print("[NotionService] ✅ Updated page: \(pageId)")
    }

    // MARK: - Fetch or Create Today's Entry
    /// Looks for a database row where the "Date" property equals today.
    /// If none exists, creates a new row for today.
    func fetchOrCreateTodayEntry(databaseId: String, titleProperty: String = "Day") async throws -> String? {
        let today = todayISO()

        let filter: [String: Any] = [
            "property": "Date",
            "date": ["equals": today]
        ]

        let results = try await queryDatabase(databaseId: databaseId, filter: filter)

        if let existing = results.first, let id = existing["id"] as? String {
            print("[NotionService] Found existing entry for \(today): \(id)")
            return id
        }

        // Create new entry for today
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        let dayLabel = formatter.string(from: Date())

        let properties: [String: Any] = [
            titleProperty: ["title": [["text": ["content": dayLabel]]]],
            "Date": ["date": ["start": today]]
        ]

        print("[NotionService] Creating new entry for \(today)...")
        return try await createPage(databaseId: databaseId, properties: properties)
    }

    // MARK: - Helpers
    func todayISO() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: Date())
    }
}

// MARK: - Notion Config
// ⚠️  IMPORTANT: Replace the placeholder below with your real Notion Integration Token.
// Get it from: https://www.notion.so/profile/integrations
// The token starts with "ntn_" or "secret_"
struct NotionConfig {
    static let integrationToken = "YOUR_NOTION_INTEGRATION_TOKEN"
}
