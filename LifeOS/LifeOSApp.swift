import SwiftUI

@main
struct LifeOSApp: App {
    @State private var notionConnected: Bool? = nil

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .overlay(alignment: .top) {
                    if notionConnected == false {
                        NotionBanner()
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 50)
                    }
                }
                .task {
                    // Test Notion connection on launch
                    if NotionConfig.integrationToken == "YOUR_NOTION_INTEGRATION_TOKEN" {
                        notionConnected = false
                        return
                    }
                    notionConnected = await NotionService.shared.testConnection()
                }
        }
    }
}

// MARK: - Notion Connection Banner
struct NotionBanner: View {
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notion Not Connected")
                        .font(.caption.bold())
                    Text("Add your token in NotionService.swift to sync data")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    withAnimation { dismissed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .shadow(radius: 8)
        }
    }
}
