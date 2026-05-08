import SwiftUI

// MARK: - Model
struct RoutineItem: Identifiable {
    let id = UUID()
    let title: String
    let emoji: String
    let notionKey: String
    var isCompleted: Bool = false
}

// MARK: - ViewModel
@MainActor
class MorningRoutineViewModel: ObservableObject {

    // MARK: - Local Persistence
    private var todayKey: String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]
        return f.string(from: Date())
    }

    func saveLocally() {
        let ud = UserDefaults.standard
        let today = todayKey
        ud.set(today, forKey: "lifeos.morning.date")
        // Save each item's completion state by its notionKey
        for item in items {
            ud.set(item.isCompleted, forKey: "lifeos.morning.\(item.notionKey)")
        }
        ud.set(reflectionText, forKey: "lifeos.morning.reflection")
    }

    func loadLocally() {
        let ud = UserDefaults.standard
        let today = todayKey
        let stored = ud.string(forKey: "lifeos.morning.date") ?? ""
        if stored == today {
            for i in 0..<items.count {
                let key = "lifeos.morning.\(items[i].notionKey)"
                if ud.object(forKey: key) != nil {
                    items[i].isCompleted = ud.bool(forKey: key)
                }
            }
            reflectionText = ud.string(forKey: "lifeos.morning.reflection") ?? ""
        } else {
            // New day — reset all items
            for i in 0..<items.count { items[i].isCompleted = false }
            reflectionText = ""
            saveLocally()
        }
    }
    @Published var items: [RoutineItem] = [
        RoutineItem(title: "Get out of bed",           emoji: "🛏️", notionKey: "Get Out of Bed"),
        RoutineItem(title: "Make my bed",              emoji: "🪴", notionKey: "Make Bed"),
        RoutineItem(title: "Brush my teeth",           emoji: "🦷", notionKey: "Brush Teeth"),
        RoutineItem(title: "High-five in the mirror",  emoji: "🪞", notionKey: "High-Five Mirror"),
        RoutineItem(title: "Drink a full cup of water",emoji: "💧", notionKey: "Drink Water"),
        RoutineItem(title: "Walk outside for 10 min",  emoji: "🌿", notionKey: "Walk Outside 10 Min"),
        RoutineItem(title: "Make that shake",          emoji: "🥤", notionKey: "Make Shake"),
        RoutineItem(title: "Drink the shake",          emoji: "💪", notionKey: "Drink Shake"),
        RoutineItem(title: "One reading",              emoji: "📖", notionKey: "One Reading"),
        RoutineItem(title: "Go work out",              emoji: "🏋️", notionKey: "Go Work Out"),
        RoutineItem(title: "Home and shower",          emoji: "🚿", notionKey: "Home and Shower")
    ]
    
    @Published var reflectionText: String = ""
    @Published var isSyncing: Bool = false
    @Published var syncMessage: String = ""
    @Published var todayPageId: String? = nil
    
    var progress: Double {
        let completed = items.filter { $0.isCompleted }.count
        guard items.count > 0 else { return 0 }
        return Double(completed) / Double(items.count)
    }
    
    var completedCount: Int { items.filter { $0.isCompleted }.count }
    
    func toggleItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        saveLocally()
        Task { await syncToNotion() }
    }
    
    func loadFromNotion() async {
        isSyncing = true
        do {
            let pageId = try await NotionService.shared.fetchOrCreateTodayEntry(
                databaseId: NotionService.DatabaseIDs.morningRoutineTracker
            )
            todayPageId = pageId
            
            if let pageId = pageId {
                let results = try await NotionService.shared.queryDatabase(
                    databaseId: NotionService.DatabaseIDs.morningRoutineTracker,
                    filter: nil
                )
                if let page = results.first(where: { ($0["id"] as? String) == pageId }),
                   let properties = page["properties"] as? [String: Any] {
                    for i in 0..<items.count {
                        let key = items[i].notionKey
                        if let prop = properties[key] as? [String: Any],
                           let checkbox = prop["checkbox"] as? Bool {
                            items[i].isCompleted = checkbox
                        }
                    }
                    if let reflectionProp = properties["Reflection Notes"] as? [String: Any],
                       let richText = reflectionProp["rich_text"] as? [[String: Any]],
                       let firstText = richText.first,
                       let textContent = firstText["text"] as? [String: Any],
                       let content = textContent["content"] as? String {
                        reflectionText = content
                    }
                }
            }
        } catch {
            syncMessage = "Could not load from Notion"
        }
        isSyncing = false
    }
    
    func syncToNotion() async {
        guard let pageId = todayPageId else { return }
        isSyncing = true
        
        var properties: [String: Any] = [:]
        for item in items {
            properties[item.notionKey] = ["checkbox": item.isCompleted]
        }
        
        do {
            try await NotionService.shared.updatePage(pageId: pageId, properties: properties)
            syncMessage = "Synced ✓"
        } catch {
            syncMessage = "Sync failed"
        }
        
        isSyncing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.syncMessage = ""
        }
    }
    
    func saveReflection() async {
        guard let pageId = todayPageId else { return }
        let properties: [String: Any] = [
            "Reflection Notes": ["rich_text": [["text": ["content": reflectionText]]]]
        ]
        try? await NotionService.shared.updatePage(pageId: pageId, properties: properties)
    }
}

// MARK: - View
struct MorningRoutineView: View {
    @StateObject private var viewModel = MorningRoutineViewModel()
    @State private var showReflection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.4), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: Progress Card
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Today's Morning")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("\(viewModel.completedCount) of \(viewModel.items.count) done")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                                        .frame(width: 64, height: 64)
                                    Circle()
                                        .trim(from: 0, to: viewModel.progress)
                                        .stroke(
                                            LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                        )
                                        .frame(width: 64, height: 64)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut, value: viewModel.progress)
                                    
                                    Text("\(Int(viewModel.progress * 100))%")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                            
                            if viewModel.progress == 1.0 {
                                Text("Morning Conquered! 🚀 Keep the momentum going.")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 24)
                        .padding(.horizontal)
                        
                        // MARK: Routine Items
                        VStack(spacing: 10) {
                            ForEach(viewModel.items) { item in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.toggleItem(id: item.id)
                                    }
                                }) {
                                    HStack(spacing: 14) {
                                        Text(item.emoji)
                                            .font(.title2)
                                        
                                        Text(item.title)
                                            .font(.body)
                                            .foregroundColor(item.isCompleted ? .white.opacity(0.45) : .white)
                                            .strikethrough(item.isCompleted, color: .white.opacity(0.4))
                                        
                                        Spacer()
                                        
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isCompleted ? .green : .white.opacity(0.4))
                                            .font(.title2)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        ZStack {
                                            if #available(iOS 15.0, macOS 12.0, *) {
                                                Rectangle().fill(.ultraThinMaterial)
                                            } else {
                                                Color.white.opacity(0.08)
                                            }
                                            if item.isCompleted {
                                                Color.green.opacity(0.08)
                                            }
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    item.isCompleted
                                                        ? Color.green.opacity(0.4)
                                                        : Color.white.opacity(0.12),
                                                    lineWidth: 1
                                                )
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Reflection Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Evening Reflection")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { showReflection.toggle() }) {
                                    Image(systemName: showReflection ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            if showReflection {
                                TextEditor(text: $viewModel.reflectionText)
                                    .frame(minHeight: 100)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .overlay(
                                        Group {
                                            if viewModel.reflectionText.isEmpty {
                                                Text("How did your morning go? What would you do differently?")
                                                    .foregroundColor(.white.opacity(0.3))
                                                    .padding(.top, 8)
                                                    .padding(.leading, 4)
                                                    .allowsHitTesting(false)
                                            }
                                        },
                                        alignment: .topLeading
                                    )
                                
                                Button("Save Reflection") {
                                    Task { await viewModel.saveReflection() }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 24)
                        .padding(.horizontal)
                        
                        // Sync status
                        if !viewModel.syncMessage.isEmpty {
                            Text(viewModel.syncMessage)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Morning Routine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSyncing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Button(action: {
                            Task { await viewModel.loadFromNotion() }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .task {
                viewModel.loadLocally()           // instant local restore
                await viewModel.loadFromNotion()  // then sync with Notion
            }
        }
    }
}

#Preview {
    MorningRoutineView()
}
