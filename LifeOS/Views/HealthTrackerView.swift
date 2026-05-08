import SwiftUI
import UserNotifications

// MARK: - UserDefaults Keys
private enum UDKey {
    // Health
    static let invisalignOn          = "lifeos.invisalign.isOn"
    static let invisalignHours       = "lifeos.invisalign.hoursWorn"
    static let invisalignSessionStart = "lifeos.invisalign.sessionStart"
    static let invisalignOffStart    = "lifeos.invisalign.offStart"
    static let invisalignDate        = "lifeos.invisalign.date"   // ISO date string — reset daily
    static let accutaneTaken         = "lifeos.accutane.taken"
    static let accutaneTime          = "lifeos.accutane.time"
    static let accutaneDate          = "lifeos.accutane.date"
}

// MARK: - ViewModel

@MainActor
class HealthTrackerViewModel: ObservableObject {

    // MARK: Invisalign State
    @Published var isInvisalignOn: Bool = true
    @Published var hoursWornToday: Double = 0.0
    @Published var currentSessionStart: Date? = nil   // when it was last put ON
    @Published var currentOffStart: Date? = nil       // when it was last taken OFF

    // Live elapsed display
    @Published var liveElapsedSeconds: Int = 0        // seconds worn so far today (updates every second)
    private var liveTimer: Timer? = nil

    let dailyTarget: Double = 22.0

    // MARK: Accutane State
    @Published var accutaneTaken: Bool = false
    @Published var accutaneTime: String = ""

    // MARK: Sync State
    @Published var isSyncing: Bool = false
    @Published var syncMessage: String = ""
    @Published var todayPageId: String? = nil
    @Published var notionConnected: Bool = true

    // MARK: - Local Persistence (UserDefaults)

    private var todayKey: String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]
        return f.string(from: Date())
    }

    func saveLocally() {
        let ud = UserDefaults.standard
        let today = todayKey

        // Reset if it's a new day
        if ud.string(forKey: UDKey.invisalignDate) != today {
            ud.set(today, forKey: UDKey.invisalignDate)
            ud.set(22.0, forKey: UDKey.invisalignHours)   // start fresh — assume full day
            ud.removeObject(forKey: UDKey.invisalignSessionStart)
            ud.removeObject(forKey: UDKey.invisalignOffStart)
        }
        if ud.string(forKey: UDKey.accutaneDate) != today {
            ud.set(today, forKey: UDKey.accutaneDate)
            ud.set(false, forKey: UDKey.accutaneTaken)
            ud.set("", forKey: UDKey.accutaneTime)
        }

        ud.set(isInvisalignOn, forKey: UDKey.invisalignOn)
        ud.set(hoursWornToday, forKey: UDKey.invisalignHours)
        ud.set(currentSessionStart, forKey: UDKey.invisalignSessionStart)
        ud.set(currentOffStart, forKey: UDKey.invisalignOffStart)
        ud.set(accutaneTaken, forKey: UDKey.accutaneTaken)
        ud.set(accutaneTime, forKey: UDKey.accutaneTime)
    }

    func loadLocally() {
        let ud = UserDefaults.standard
        let today = todayKey

        // If stored data is from a previous day, start fresh
        let storedDate = ud.string(forKey: UDKey.invisalignDate) ?? ""
        if storedDate == today {
            isInvisalignOn      = ud.bool(forKey: UDKey.invisalignOn)
            hoursWornToday      = ud.double(forKey: UDKey.invisalignHours)
            currentSessionStart = ud.object(forKey: UDKey.invisalignSessionStart) as? Date
            currentOffStart     = ud.object(forKey: UDKey.invisalignOffStart) as? Date
        } else {
            // New day — reset
            isInvisalignOn = true
            hoursWornToday = 0.0
            currentSessionStart = Date()   // assume it's been on since app open
            currentOffStart = nil
            saveLocally()
        }

        let storedAccutaneDate = ud.string(forKey: UDKey.accutaneDate) ?? ""
        if storedAccutaneDate == today {
            accutaneTaken = ud.bool(forKey: UDKey.accutaneTaken)
            accutaneTime  = ud.string(forKey: UDKey.accutaneTime) ?? ""
        } else {
            accutaneTaken = false
            accutaneTime  = ""
        }
    }

    // MARK: Computed

    var progressFraction: Double {
        min(hoursWornToday / dailyTarget, 1.0)
    }

    var isTargetMet: Bool { hoursWornToday >= dailyTarget }

    var progressColor: Color {
        if hoursWornToday >= dailyTarget { return .green }
        if hoursWornToday >= dailyTarget * 0.75 { return .yellow }
        return .orange
    }

    /// Returns "Xh Ym" string for the live worn counter
    var liveWornDisplay: String {
        let totalSeconds = liveElapsedSeconds
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else if m > 0 {
            return "\(m)m \(s)s"
        } else {
            return "\(s)s"
        }
    }

    /// Returns "Xh Ym" for how long it's currently been OFF (if off)
    var liveOffDisplay: String? {
        guard !isInvisalignOn, let offStart = currentOffStart else { return nil }
        let secs = Int(Date().timeIntervalSince(offStart))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return "\(h)h \(m)m off" }
        if m > 0 { return "\(m)m \(s)s off" }
        return "\(s)s off"
    }

    var hoursRemainingDisplay: String {
        let remaining = max(0, dailyTarget - hoursWornToday)
        let h = Int(remaining)
        let m = Int((remaining - Double(h)) * 60)
        return "\(h)h \(m)m left"
    }

    // MARK: - Timer

    func startLiveTimer() {
        liveTimer?.invalidate()
        liveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickTimer()
            }
        }
    }

    func stopLiveTimer() {
        liveTimer?.invalidate()
        liveTimer = nil
    }

    private func tickTimer() {
        // Base seconds from already-completed worn time
        var base = Int(hoursWornToday * 3600)

        // If currently ON, add seconds since it was put on
        if isInvisalignOn, let start = currentSessionStart {
            base += Int(Date().timeIntervalSince(start))
        }

        liveElapsedSeconds = base
    }

    // MARK: - Toggle Invisalign

    func toggleInvisalign() {
        let now = Date()

        if isInvisalignOn {
            // Taking OUT — record how long it was on in this session
            if let start = currentSessionStart {
                let sessionHours = now.timeIntervalSince(start) / 3600
                hoursWornToday += sessionHours
            }
            isInvisalignOn = false
            currentSessionStart = nil
            currentOffStart = now
            scheduleOffNotification()
        } else {
            // Putting BACK IN
            isInvisalignOn = true
            currentSessionStart = now
            currentOffStart = nil
            cancelOffNotification()
        }

        saveLocally()
        Task { await syncToNotion() }
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleOffNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Invisalign Reminder 🦷"
        content.body = "Your Invisalign has been off for 1 hour. Time to put it back in!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "invisalign-off-1h", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelOffNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["invisalign-off-1h"])
    }

    // MARK: - Accutane

    func markAccutaneTaken() {
        accutaneTaken = true
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        accutaneTime = formatter.string(from: Date())
        saveLocally()
        Task { await syncToNotion() }
    }

    // MARK: - Notion Sync

    func loadFromNotion() async {
        isSyncing = true
        do {
            guard let pageId = try await NotionService.shared.fetchOrCreateTodayEntry(
                databaseId: NotionService.DatabaseIDs.dailyHealthTracker
            ) else {
                syncMessage = "Could not get today's page"
                isSyncing = false
                return
            }
            todayPageId = pageId

            // Re-query to get properties of today's page
            let results = try await NotionService.shared.queryDatabase(
                databaseId: NotionService.DatabaseIDs.dailyHealthTracker,
                filter: ["property": "Date", "date": ["equals": NotionService.shared.todayISO()]]
            )

            if let page = results.first,
               let props = page["properties"] as? [String: Any] {

                func checkbox(_ key: String) -> Bool {
                    (props[key] as? [String: Any])?["checkbox"] as? Bool ?? false
                }
                func richText(_ key: String) -> String {
                    guard let prop = props[key] as? [String: Any],
                          let rt = prop["rich_text"] as? [[String: Any]],
                          let first = rt.first,
                          let t = first["text"] as? [String: Any],
                          let c = t["content"] as? String else { return "" }
                    return c
                }
                func number(_ key: String) -> Double {
                    (props[key] as? [String: Any])?["number"] as? Double ?? 0
                }

                accutaneTaken  = checkbox("Accutane Taken")
                isInvisalignOn = checkbox("Invisalign On")
                hoursWornToday = number("Hours Worn Today")

                let at = richText("Accutane Time")
                if !at.isEmpty { accutaneTime = at }

                // If invisalign is ON, start counting from now
                if isInvisalignOn { currentSessionStart = Date() }
            }

            notionConnected = true
            syncMessage = "Loaded ✓"
        } catch {
            notionConnected = false
            syncMessage = "Notion error: \(error.localizedDescription)"
            print("[HealthTracker] loadFromNotion error: \(error)")
        }
        isSyncing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.syncMessage = "" }
    }

    func syncToNotion() async {
        guard let pageId = todayPageId else {
            syncMessage = "No page ID — try refreshing"
            return
        }
        isSyncing = true

        let properties: [String: Any] = [
            "Invisalign On":          ["checkbox": isInvisalignOn],
            "Hours Worn Today":       ["number": hoursWornToday],
            "Daily Target Met (22h)": ["checkbox": isTargetMet],
            "Accutane Taken":         ["checkbox": accutaneTaken],
            "Accutane Time":          ["rich_text": [["text": ["content": accutaneTime]]]]
        ]

        do {
            try await NotionService.shared.updatePage(pageId: pageId, properties: properties)
            notionConnected = true
            syncMessage = "Synced ✓"
        } catch {
            notionConnected = false
            syncMessage = "Sync failed — check Notion connection"
            print("[HealthTracker] syncToNotion error: \(error)")
        }

        isSyncing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.syncMessage = "" }
    }
}

// MARK: - Main View

struct HealthTrackerView: View {
    @StateObject private var viewModel = HealthTrackerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Notion status banner
                    if !viewModel.notionConnected {
                        NotionSyncBanner()
                    }

                    // ── Invisalign Card ──────────────────────────────────────
                    InvisalignCard(viewModel: viewModel)

                    // ── Accutane Card ────────────────────────────────────────
                    AccutaneCard(viewModel: viewModel)

                    // Sync message
                    if !viewModel.syncMessage.isEmpty {
                        HStack(spacing: 6) {
                            if viewModel.isSyncing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: viewModel.syncMessage.contains("✓") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(viewModel.syncMessage.contains("✓") ? .green : .yellow)
                            }
                            Text(viewModel.syncMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.loadFromNotion() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                viewModel.loadLocally()          // instant local restore
                viewModel.startLiveTimer()
                viewModel.requestNotificationPermission()
                await viewModel.loadFromNotion()  // then sync with Notion in background
            }
            .onDisappear {
                viewModel.stopLiveTimer()
            }
        }
    }
}

// MARK: - Invisalign Card

struct InvisalignCard: View {
    @ObservedObject var viewModel: HealthTrackerViewModel

    var body: some View {
        VStack(spacing: 20) {

            // Header
            HStack {
                Label("Invisalign", systemImage: "mouth.fill")
                    .font(.title3.bold())
                Spacer()
                // Live off-timer badge
                if let offDisplay = viewModel.liveOffDisplay {
                    Text(offDisplay)
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.15), in: Capsule())
                }
            }

            // Circular progress + live timer
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: viewModel.progressFraction)
                    .stroke(
                        AngularGradient(
                            colors: [viewModel.progressColor.opacity(0.4), viewModel.progressColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: viewModel.progressFraction)
                    .frame(width: 160, height: 160)

                VStack(spacing: 4) {
                    Text(viewModel.liveWornDisplay)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.progressColor)
                        .contentTransition(.numericText())
                        .animation(.default, value: viewModel.liveElapsedSeconds)

                    Text("worn today")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(viewModel.hoursRemainingDisplay)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Target progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Daily Target: 22h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.isTargetMet ? "Target Met!" : "\(String(format: "%.1f", viewModel.hoursWornToday))h / 22h")
                        .font(.caption.bold())
                        .foregroundColor(viewModel.isTargetMet ? .green : .primary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.progressColor)
                            .frame(width: geo.size.width * viewModel.progressFraction, height: 8)
                            .animation(.easeInOut(duration: 0.6), value: viewModel.progressFraction)
                    }
                }
                .frame(height: 8)
            }

            // Toggle Button — full width
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.toggleInvisalign()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isInvisalignOn ? "mouth.fill" : "mouth")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.isInvisalignOn ? "Invisalign is ON" : "Invisalign is OFF")
                            .font(.headline)
                        Text(viewModel.isInvisalignOn ? "Tap to take out" : "Tap to put back in")
                            .font(.caption)
                            .opacity(0.75)
                    }
                    Spacer()
                    Image(systemName: viewModel.isInvisalignOn ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                }
                .foregroundColor(viewModel.isInvisalignOn ? .green : .red)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    (viewModel.isInvisalignOn ? Color.green : Color.red).opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Accutane Card

struct AccutaneCard: View {
    @ObservedObject var viewModel: HealthTrackerViewModel

    var body: some View {
        VStack(spacing: 16) {

            // Header
            HStack {
                Label("Accutane", systemImage: "pills.fill")
                    .font(.title3.bold())
                Spacer()
                if viewModel.accutaneTaken {
                    Label("Done today", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }

            // Info row
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text("2 pills")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("daily dose")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 36)

                VStack(spacing: 3) {
                    Text(viewModel.accutaneTaken ? viewModel.accutaneTime : "--:--")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.accutaneTaken ? .green : .secondary)
                    Text("taken at")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            // Full-width button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if !viewModel.accutaneTaken {
                        viewModel.markAccutaneTaken()
                    } else {
                        viewModel.accutaneTaken = false
                        viewModel.accutaneTime = ""
                        Task { await viewModel.syncToNotion() }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.accutaneTaken ? "pills.fill" : "pills")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.accutaneTaken ? "Taken today" : "Mark as taken")
                            .font(.headline)
                        Text(viewModel.accutaneTaken ? "Tap to undo" : "2 pills · once daily")
                            .font(.caption)
                            .opacity(0.75)
                    }
                    Spacer()
                    Image(systemName: viewModel.accutaneTaken ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                }
                .foregroundColor(viewModel.accutaneTaken ? .green : .orange)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    (viewModel.accutaneTaken ? Color.green : Color.orange).opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Notion Sync Banner

struct NotionSyncBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Notion Sync Issue")
                    .font(.caption.bold())
                Text("Make sure your integration is connected to this database in Notion → ··· → Connections")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HealthTrackerView()
}
