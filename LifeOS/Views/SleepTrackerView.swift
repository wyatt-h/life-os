import SwiftUI

// MARK: - ViewModel
@MainActor
class SleepTrackerViewModel: ObservableObject {
    @Published var targetWakeTime: String = "8:15 AM"
    @Published var targetBedtime: String = "1:15 AM"
    @Published var actualWakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var actualBedtime: Date = Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: Date()) ?? Date()
    @Published var actualWakeTimeSet: Bool = false   // true once user has picked a time
    @Published var actualBedtimeSet: Bool = false
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
    
    // MARK: - Helpers
    func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Local Persistence
    func saveLocally() {
        let ud = UserDefaults.standard
        let today = DayKey.current
        ud.set(today,          forKey: "lifeos.sleep.date")
        ud.set(wokeUpOnTime,   forKey: "lifeos.sleep.wokeUpOnTime")
        ud.set(morningLight,   forKey: "lifeos.sleep.morningLight")
        ud.set(noCaffeine,     forKey: "lifeos.sleep.noCaffeine")
        ud.set(windDown,       forKey: "lifeos.sleep.windDown")
        ud.set(inBedOnTime,    forKey: "lifeos.sleep.inBedOnTime")
        ud.set(noScreens,      forKey: "lifeos.sleep.noScreens")
        if actualWakeTimeSet {
            ud.set(actualWakeTime, forKey: "lifeos.sleep.actualWakeTime")
        }
        if actualBedtimeSet {
            ud.set(actualBedtime,  forKey: "lifeos.sleep.actualBedtime")
        }
    }

    func loadLocally() {
        let ud = UserDefaults.standard
        let today = DayKey.current
        let stored = ud.string(forKey: "lifeos.sleep.date") ?? ""
        if stored == today {
            wokeUpOnTime = ud.bool(forKey: "lifeos.sleep.wokeUpOnTime")
            morningLight = ud.bool(forKey: "lifeos.sleep.morningLight")
            noCaffeine   = ud.bool(forKey: "lifeos.sleep.noCaffeine")
            windDown     = ud.bool(forKey: "lifeos.sleep.windDown")
            inBedOnTime  = ud.bool(forKey: "lifeos.sleep.inBedOnTime")
            noScreens    = ud.bool(forKey: "lifeos.sleep.noScreens")
            if let d = ud.object(forKey: "lifeos.sleep.actualWakeTime") as? Date {
                actualWakeTime = d; actualWakeTimeSet = true
            }
            if let d = ud.object(forKey: "lifeos.sleep.actualBedtime") as? Date {
                actualBedtime = d; actualBedtimeSet = true
            }
        } else {
            // New day — reset
            wokeUpOnTime = false; morningLight = false; noCaffeine = false
            windDown = false; inBedOnTime = false; noScreens = false
            actualWakeTimeSet = false; actualBedtimeSet = false
            saveLocally()
        }
    }

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
                    
                    let tw = text("Target Wake Time")
                    let tb = text("Target Bedtime")
                    if !tw.isEmpty { targetWakeTime = tw }
                    if !tb.isEmpty { targetBedtime = tb }

                    // Parse stored actual times back into Date
                    let tf = DateFormatter()
                    tf.dateFormat = "h:mm a"
                    let aw = text("Actual Wake Time")
                    let ab = text("Actual Bedtime")
                    if !aw.isEmpty, let d = tf.date(from: aw) {
                        actualWakeTime = d; actualWakeTimeSet = true
                    }
                    if !ab.isEmpty, let d = tf.date(from: ab) {
                        actualBedtime = d; actualBedtimeSet = true
                    }
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
            "Actual Wake Time": ["rich_text": [["text": ["content": actualWakeTimeSet ? timeString(actualWakeTime) : ""]]]],
            "Actual Bedtime": ["rich_text": [["text": ["content": actualBedtimeSet ? timeString(actualBedtime) : ""]]]],
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
                                viewModel.saveLocally(); Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "Morning light", subtitle: "Within 30 min of waking", icon: "sun.horizon.fill", isOn: $viewModel.morningLight) {
                                viewModel.saveLocally(); Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "No caffeine after 2 PM", subtitle: "Protects melatonin onset", icon: "cup.and.saucer.fill", isOn: $viewModel.noCaffeine) {
                                viewModel.saveLocally(); Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "Wind-down routine", subtitle: "1 hour before bed", icon: "wind", isOn: $viewModel.windDown) {
                                viewModel.saveLocally(); Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "In bed on time", subtitle: "Target: \(viewModel.targetBedtime)", icon: "bed.double.fill", isOn: $viewModel.inBedOnTime) {
                                viewModel.saveLocally(); Task { await viewModel.syncToNotion() }
                            }
                            SleepHabitRow(title: "No screens before bed", subtitle: "30 min before target bedtime", icon: "iphone.slash", isOn: $viewModel.noScreens) {
                                viewModel.saveLocally(); Task { await viewModel.syncToNotion() }
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Log Actual Times
                        VStack(alignment: .leading, spacing: 0) {

                            // Full-width expand button
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showActualTimes.toggle()
                                }
                            } label: {
                                HStack {
                                    Label("Log Actual Times", systemImage: "clock.badge.checkmark.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: showActualTimes ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if showActualTimes {
                                VStack(spacing: 0) {
                                    Divider().background(Color.white.opacity(0.15))

                                    // Wake-up time picker
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "sun.max.fill")
                                                .foregroundColor(.yellow)
                                            Text("Actual Wake-Up Time")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Spacer()
                                            if viewModel.actualWakeTimeSet {
                                                Text(viewModel.timeString(viewModel.actualWakeTime))
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.top, 12)

                                        DatePicker(
                                            "",
                                            selection: $viewModel.actualWakeTime,
                                            displayedComponents: .hourAndMinute
                                        )
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity)
                                        .colorScheme(.dark)
                                        .onChange(of: viewModel.actualWakeTime) { _ in
                                            viewModel.actualWakeTimeSet = true
                                        }
                                    }

                                    Divider().background(Color.white.opacity(0.15)).padding(.horizontal, 16)

                                    // Bedtime picker
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "moon.zzz.fill")
                                                .foregroundColor(.purple)
                                            Text("Actual Bedtime")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Spacer()
                                            if viewModel.actualBedtimeSet {
                                                Text(viewModel.timeString(viewModel.actualBedtime))
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.purple)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)

                                        DatePicker(
                                            "",
                                            selection: $viewModel.actualBedtime,
                                            displayedComponents: .hourAndMinute
                                        )
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity)
                                        .colorScheme(.dark)
                                        .onChange(of: viewModel.actualBedtime) { _ in
                                            viewModel.actualBedtimeSet = true
                                        }
                                    }

                                    // Save button — full width
                                    Button {
                                        Task { await viewModel.syncToNotion() }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "icloud.and.arrow.up.fill")
                                            Text("Save to Notion")
                                                .font(.headline)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.purple.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(16)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                viewModel.loadLocally()           // instant local restore
                await viewModel.loadFromNotion()  // then sync with Notion
            }
        }
    }
}

#Preview {
    SleepTrackerView()
}
