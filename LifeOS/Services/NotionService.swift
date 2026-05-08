import Foundation

// MARK: - Notion API Service
// Handles all communication with the Notion API v1
// Uses the official Notion Integration Token stored in Config.swift

class NotionService {
    static let shared = NotionService()
    
    private let baseURL = "https://api.notion.com/v1"
    private let notionVersion = "2022-06-28"
    
    // MARK: - Database IDs
    struct DatabaseIDs {
        static let morningRoutineTracker = "c141976a-169a-4803-bf24-df02fb7b66b3"
        static let dailyHealthTracker    = "5b0d0827-1365-44ac-93d0-0c60e9694e38"
        static let recipesAndShakes      = "a50b83e8-944c-405e-98e9-6719416ba66b"
        static let sleepTracker          = "8842f9a0-aa03-453e-a5b4-1d8451ce5544"
    }
    
    // MARK: - Request Builder
    private func makeRequest(path: String, method: String = "GET", body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(NotionConfig.integrationToken)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return request
    }
    
    // MARK: - Query Database
    func queryDatabase(databaseId: String, filter: [String: Any]? = nil) async throws -> [[String: Any]] {
        guard var request = makeRequest(path: "/databases/\(databaseId)/query", method: "POST") else {
            throw NSError(domain: "NotionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var body: [String: Any] = [:]
        if let filter = filter {
            body["filter"] = filter
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }
        return results
    }
    
    // MARK: - Create Page (new entry in database)
    func createPage(databaseId: String, properties: [String: Any]) async throws -> String? {
        guard let request = makeRequest(path: "/pages", method: "POST", body: [
            "parent": ["database_id": databaseId],
            "properties": properties
        ]) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["id"] as? String
    }
    
    // MARK: - Update Page
    func updatePage(pageId: String, properties: [String: Any]) async throws {
        guard let request = makeRequest(path: "/pages/\(pageId)", method: "PATCH", body: [
            "properties": properties
        ]) else { return }
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - Fetch Today's Entry or Create It
    func fetchOrCreateTodayEntry(databaseId: String, titleProperty: String = "Day") async throws -> String? {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        
        let filter: [String: Any] = [
            "property": "Date",
            "date": ["equals": String(today)]
        ]
        
        let results = try await queryDatabase(databaseId: databaseId, filter: filter)
        
        if let existing = results.first, let id = existing["id"] as? String {
            return id
        }
        
        // Create new entry for today
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        let dayLabel = formatter.string(from: Date())
        
        let properties: [String: Any] = [
            titleProperty: ["title": [["text": ["content": dayLabel]]]],
            "Date": ["date": ["start": String(today)]]
        ]
        
        return try await createPage(databaseId: databaseId, properties: properties)
    }
}

// MARK: - Notion Config
// Replace with your actual Notion Integration Token
struct NotionConfig {
    // TODO: Replace with your actual Notion Integration Token
    // Get it from: https://www.notion.so/profile/integrations
    static let integrationToken = "YOUR_NOTION_INTEGRATION_TOKEN"
}
