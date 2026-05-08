import SwiftUI
import UserNotifications

// MARK: - Invisalign Session Model
struct InvisalignSession: Identifiable {
    let id = UUID()
    var offTime: Date?
    var onTime: Date?
    
    var duration: TimeInterval? {
        guard let off = offTime, let on = onTime else { return nil }
        return on.timeIntervalSince(off)
    }
}

// MARK: - ViewModel
@MainActor
class HealthTrackerViewModel: ObservableObject {
    
    // MARK: Invisalign State
    @Published var isInvisalignOn: Bool = true
    @Published var lastToggleTime: Date = Date()
    @Published var hoursWornToday: Double = 0.0
    @Published var sessions: [InvisalignSession] = []
    private var currentOffTime: Date? = nil
    
    let dailyTarget: Double = 22.0
    
    // MARK: Accutane State
    @Published var accutaneTaken: Bool = false
    @Published var accutaneTime: String = ""
    
    // MARK: Sync State
    @Published var isSyncing: Bool = false
    @Published var syncMessage: String = ""
    @Published var todayPageId: String? = nil
    
    // MARK: Notification Timer
    private var notificationTimer: Timer? = nil
    
    // MARK: Computed
    var hoursRemaining: Double { max(0, dailyTarget - hoursWornToday) }
    var isTargetMet: Bool { hoursWornToday >= dailyTarget }
    
    var progressColor: Color {
        if hoursWornToday >= dailyTarget { return .green }
        if hoursWornToday >= dailyTarget * 0.75 { return .yellow }
        return .orange
    }
    
    // MARK: Toggle Invisalign
    func toggleInvisalign() {
        let now = Date()
        
        if isInvisalignOn {
            // Taking out
            isInvisalignOn = false
            currentOffTime = now
            lastToggleTime = now
            scheduleOffNotification()
        } else {
            // Putting back in
            isInvisalignOn = true
            if let offTime = currentOffTime {
                let offDuration = now.timeIntervalSince(offTime) / 3600
                hoursWornToday = max(0, hoursWornToday - offDuration)
                // Actually, worn hours = 24 - total off hours
                // Simplified: add back the time it was off
            }
            currentOffTime = nil
            lastToggleTime = now
            cancelOffNotification()
        }
        
        Task { await syncToNotion() }
    }
    
    // MARK: Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func scheduleOffNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Invisalign Reminder"
        content.body = "Your Invisalign has been off for 1 hour. Time to put it back in!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "invisalign-off-1h", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelOffNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["invisalign-off-1h"])
    }
    
    // MARK: Accutane
    func markAccutaneTaken() {
        accutaneTaken = true
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        accutaneTime = formatter.string(from: Date())
        Task { await syncToNotion() }
    }
    
    // MARK: Notion Sync
    func loadFromNotion() async {
        do {
            let pageId = try await NotionService.shared.fetchOrCreateTodayEntry(
                databaseId: NotionService.DatabaseIDs.dailyHealthTracker
            )
            todayPageId = pageId
            
            if let pageId = pageId {
                let results = try await NotionService.shared.queryDatabase(
                    databaseId: NotionService.DatabaseIDs.dailyHealthTracker
                )
                if let page = results.first(where: { ($0["id"] as? String) == pageId }),
                   let props = page["properties"] as? [String: Any] {
                    
                    func checkbox(_ key: String) -> Bool {
                        (props[key] as? [String: Any])?["checkbox"] as? Bool ?? false
                    }
                    func text(_ key: String) -> String {
                        if let prop = props[key] as? [String: Any],
                           let rt = prop["rich_text"] as? [[String: Any]],
                           let first = rt.first,
                           let t = first["text"] as? [String: Any],
                           let c = t["content"] as? String { return c }
                        return ""
                    }
                    func number(_ key: String) -> Double {
                        if let prop = props[key] as? [String: Any],
                           let num = prop["number"] as? Double { return num }
                        return 0
                    }
                    
                    accutaneTaken = checkbox("Accutane Taken")
                    isInvisalignOn = checkbox("Invisalign On")
                    hoursWornToday = number("Hours Worn Today")
                    
                    let at = text("Accutane Time")
                    if !at.isEmpty { accutaneTime = at }
                }
            }
        } catch {
            syncMessage = "Could not load from Notion"
        }
    }
    
    func syncToNotion() async {
        guard let pageId = todayPageId else { return }
        isSyncing = true
        
        let properties: [String: Any] = [
            "Invisalign On": ["checkbox": isInvisalignOn],
            "Hours Worn Today": ["number": hoursWornToday],
            "Daily Target Met (22h)": ["checkbox": isTargetMet],
            "Accutane Taken": ["checkbox": accutaneTaken],
            "Accutane Time": ["rich_text": [["text": ["content": accutaneTime]]]]
        ]
        
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
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let label: String
    let sublabel: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            VStack(spacing: 2) {
                Text(label)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text(sublabel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - Main View
struct HealthTrackerView: View {
    @StateObject private var viewModel = HealthTrackerViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.8, green: 0.3, blue: 0.1).opacity(0.4), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: Invisalign Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Invisalign Tracker")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                Spacer()
                                if viewModel.isTargetMet {
                                    Label("Target Met", systemImage: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            // Circular Progress
                            HStack(spacing: 30) {
                                CircularProgressView(
                                    progress: viewModel.hoursWornToday / viewModel.dailyTarget,
                                    color: viewModel.progressColor,
                                    label: String(format: "%.1f", viewModel.hoursWornToday),
                                    sublabel: "hrs worn"
                                )
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Daily Target")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Text("\(Int(viewModel.dailyTarget)) hours")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Remaining")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Text(String(format: "%.1f hrs", viewModel.hoursRemaining))
                                            .font(.headline)
                                            .foregroundColor(viewModel.progressColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Status")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(viewModel.isInvisalignOn ? Color.green : Color.red)
                                                .frame(width: 8, height: 8)
                                            Text(viewModel.isInvisalignOn ? "Wearing" : "Off")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            
                            // Toggle Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleInvisalign()
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: viewModel.isInvisalignOn ? "minus.circle.fill" : "plus.circle.fill")
                                        .font(.title3)
                                    Text(viewModel.isInvisalignOn ? "Take Out Invisalign" : "Put In Invisalign")
                                        .font(.headline)
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    viewModel.isInvisalignOn
                                        ? Color.red.opacity(0.75)
                                        : Color.green.opacity(0.75)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(18)
                                .shadow(color: (viewModel.isInvisalignOn ? Color.red : Color.green).opacity(0.4), radius: 10, x: 0, y: 4)
                            }
                            
                            Text("Notification will fire if off for 1+ hour")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 24)
                        .padding(.horizontal)
                        
                        // MARK: Accutane Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Accutane")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Daily Dose")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("2 pills at once")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    if viewModel.accutaneTaken && !viewModel.accutaneTime.isEmpty {
                                        Text("Taken at \(viewModel.accutaneTime)")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        if !viewModel.accutaneTaken {
                                            viewModel.markAccutaneTaken()
                                        } else {
                                            viewModel.accutaneTaken = false
                                            viewModel.accutaneTime = ""
                                            Task { await viewModel.syncToNotion() }
                                        }
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(viewModel.accutaneTaken ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                                            .frame(width: 70, height: 70)
                                        
                                        Image(systemName: viewModel.accutaneTaken ? "checkmark.circle.fill" : "pills.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(viewModel.accutaneTaken ? .green : .orange)
                                    }
                                }
                            }
                            
                            if !viewModel.accutaneTaken {
                                Text("Tap the pill icon to mark today's dose as taken")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("Done for today! Great job staying consistent.")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 24)
                        .padding(.horizontal)
                        
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
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSyncing {
                        ProgressView().tint(.white)
                    } else {
                        Button(action: { Task { await viewModel.loadFromNotion() } }) {
                            Image(systemName: "arrow.clockwise").foregroundColor(.white)
                        }
                    }
                }
            }
            .task {
                viewModel.requestNotificationPermission()
                await viewModel.loadFromNotion()
            }
        }
    }
}

#Preview {
    HealthTrackerView()
}
