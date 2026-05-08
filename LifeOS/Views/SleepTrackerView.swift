import SwiftUI

// MARK: - ViewModel
@MainActor
class SleepTrackerViewModel: ObservableObject {
    @Published var targetWakeTime: String = "8:15 AM"
    @Published var targetBedtime: String = "1:15 AM"
    @Published var actualWakeTime: String = ""
    @Published var actualBedtime: String = ""
    @Published var phase: String = "Phase 1: Easing In"
    
    @Published var wokeUpOnTime: Bool = false
    @Published var morningLight: Bool = false
    @Published var noCaffeine: Bool = false
    @Published var windDown: Bool = false
    @Published var inBedOnTime: Bool = false
    @Published var noScreens: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    @Published var syncMessage: String = ""
    @Published var todayPageId: String? = nil
    
    // 30-Day Plan schedule
    private let schedule: [(days: ClosedRange<Int>, wake: String, bed: String, phase: String)] = [
        (1...3,   "8:15 AM", "1:15 AM", "Phase 1: Easing In"),
        (4...6,   "8:00 AM", "1:00 AM", "Phase 1: Easing In"),
        (7...9,   "7:45 AM", "12:45 AM", "Phase 1: Easing In"),
        (10...12, "7:30 AM", "12:30 AM", "Phase 2: Building Momentum"),
        (13...15, "7:15 AM", "12:15 AM", "Phase 2: Building Momentum"),
        (16...18, "7:00 AM", "12:00 AM", "Phase 2: Building Momentum"),
        (19...21, "6:45 AM", "11:45 PM", "Phase 3: Final Push"),
        (22...24, "6:30 AM", "11:30 PM", "Phase 3: Final Push"),
        (25...27, "6:15 AM", "11:15 PM", "Phase 3: Final Push"),
        (28...30, "6:00 AM", "11:00 PM", "Phase 3: Final Push")
    ]
    
    var completedCount: Int {
        [wokeUpOnTime, morningLight, noCaffeine, windDown, inBedOnTime, noScreens].filter { $0 }.count
    }
    
    var totalHabits: Int { 6 }
    
    var phaseColor: Color {
        switch phase {
        case "Phase 1: Easing In": return .blue
        case "Phase 2: Building Momentum": return .yellow
        case "Phase 3: Final Push": return .green
        default: return .purple
        }
    }
    
    func computeTodayTargets() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 7))!
        let today = Calendar.current.startOfDay(for: Date())
        let dayNumber = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        let dayNum = max(1, min(30, dayNumber + 1))
        
        for entry in schedule {
            if entry.days.contains(dayNum) {
                targetWakeTime = entry.wake
                targetBedtime = entry.bed
                phase = entry.phase
                break
            }
        }
    }
    
    func loadFromNotion() async {
        isLoading = true
        computeTodayTargets()
        
        do {
            let pageId = try await NotionService.shared.fetchOrCreateTodayEntry(
                databaseId: NotionService.DatabaseIDs.sleepTracker
            )
            todayPageId = pageId
            
            if let pageId = pageId {
                let results = try await NotionService.shared.queryDatabase(
                    databaseId: NotionService.DatabaseIDs.sleepTracker
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
                    
                    wokeUpOnTime = checkbox("Woke Up On Time")
                    morningLight = checkbox("Morning Light")
                    noCaffeine = checkbox("No Late Caffeine")
                    windDown = checkbox("Wind-Down Routine")
                    inBedOnTime = checkbox("In Bed On Time")
                    noScreens = checkbox("No Screens Before Bed")
                    
                    let aw = text("Actual Wake Time")
                    let ab = text("Actual Bedtime")
                    let tw = text("Target Wake Time")
                    let tb = text("Target Bedtime")
                    
                    if !aw.isEmpty { actualWakeTime = aw }
                    if !ab.isEmpty { actualBedtime = ab }
                    if !tw.isEmpty { targetWakeTime = tw }
                    if !tb.isEmpty { targetBedtime = tb }
                }
            }
        } catch {
            syncMessage = "Could not load from Notion"
        }
        isLoading = false
    }
    
    func syncToNotion() async {
        guard let pageId = todayPageId else { return }
        isSyncing = true
        
        let properties: [String: Any] = [
            "Woke Up On Time": ["checkbox": wokeUpOnTime],
            "Morning Light": ["checkbox": morningLight],
            "No Late Caffeine": ["checkbox": noCaffeine],
            "Wind-Down Routine": ["checkbox": windDown],
            "In Bed On Time": ["checkbox": inBedOnTime],
            "No Screens Before Bed": ["checkbox": noScreens],
            "Target Wake Time": ["rich_text": [["text": ["content": targetWakeTime]]]],
            "Target Bedtime": ["rich_text": [["text": ["content": targetBedtime]]]],
            "Actual Wake Time": ["rich_text": [["text": ["content": actualWakeTime]]]],
            "Actual Bedtime": ["rich_text": [["text": ["content": actualBedtime]]]],
            "Phase": ["select": ["name": phase]]
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

// MARK: - Sleep Habit Toggle Row
struct SleepHabitRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    var onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isOn ? .purple : .white.opacity(0.5))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .onChange(of: isOn) { _ in onChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 18)
    }
}

// MARK: - Main View
struct SleepTrackerView: View {
    @StateObject private var viewModel = SleepTrackerViewModel()
    @State private var showActualTimes = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.1, blue: 0.6).opacity(0.6), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: Phase Badge
                        HStack {
                            Text(viewModel.phase)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.phaseColor)
                                .cornerRadius(20)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // MARK: Target Times Card
                        HStack(spacing: 16) {
                            VStack(spacing: 6) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("Bedtime")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(viewModel.targetBedtime)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .liquidGlass(cornerRadius: 20)
                            
                            VStack(spacing: 6) {
                                Image(systemName: "sun.max.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                Text("Wake Up")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(viewModel.targetWakeTime)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .liquidGlass(cornerRadius: 20)
                        }
                        .padding(.horizontal)
                        
                        // MARK: Habits Progress
                        VStack(spacing: 6) {
                            HStack {
                                Text("Today's Sleep Habits")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(viewModel.completedCount)/\(viewModel.totalHabits)")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.purple)
                            }
                            ProgressView(value: Double(viewModel.completedCount), total: Double(viewModel.totalHabits))
                                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                                .frame(height: 6)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                .clipShape(Capsule())
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 20)
                        .padding(.horizontal)
                        
                        // MARK: Habit Toggles
                        VStack(spacing: 10) {
                            SleepHabitRow(title: "Woke up on time", subtitle: "Target: \(viewModel.targetWakeTime)", icon: "alarm.fill", isOn: $viewModel.wokeUpOnTime) {
                                Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "Morning light", subtitle: "Within 30 min of waking", icon: "sun.horizon.fill", isOn: $viewModel.morningLight) {
                                Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "No caffeine after 2 PM", subtitle: "Protects melatonin onset", icon: "cup.and.saucer.fill", isOn: $viewModel.noCaffeine) {
                                Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "Wind-down routine", subtitle: "1 hour before bed", icon: "wind", isOn: $viewModel.windDown) {
                                Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "In bed on time", subtitle: "Target: \(viewModel.targetBedtime)", icon: "bed.double.fill", isOn: $viewModel.inBedOnTime) {
                                Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "No screens before bed", subtitle: "30 min before target bedtime", icon: "iphone.slash", isOn: $viewModel.noScreens) {
                                Task { await viewModel.syncToNotion() }
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Log Actual Times
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { showActualTimes.toggle() }) {
                                HStack {
                                    Text("Log Actual Times")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: showActualTimes ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            if showActualTimes {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Actual Wake:")
                                            .foregroundColor(.white.opacity(0.7))
                                        TextField("e.g. 7:45 AM", text: $viewModel.actualWakeTime)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    Divider().background(Color.white.opacity(0.2))
                                    HStack {
                                        Text("Actual Bedtime:")
                                            .foregroundColor(.white.opacity(0.7))
                                        TextField("e.g. 12:30 AM", text: $viewModel.actualBedtime)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    
                                    Button("Save Times") {
                                        Task { await viewModel.syncToNotion() }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.purple.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 20)
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
            .navigationTitle("Sleep Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading || viewModel.isSyncing {
                        ProgressView().tint(.white)
                    } else {
                        Button(action: { Task { await viewModel.loadFromNotion() } }) {
                            Image(systemName: "arrow.clockwise").foregroundColor(.white)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadFromNotion()
            }
        }
    }
}

#Preview {
    SleepTrackerView()
}
