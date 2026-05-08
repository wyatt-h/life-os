import Foundation

// MARK: - DayKey
// Returns a stable date string that rolls over at 4:00 AM instead of midnight.
// Any time between 00:00–03:59 is treated as still belonging to the previous day.
// Used by all ViewModels to determine when to reset daily state.

enum DayKey {
    /// The reset hour (24h). State resets when the clock passes this hour.
    static let resetHour = 4

    /// Returns an ISO date string (e.g. "2026-05-08") representing the current
    /// logical day, where the day rolls over at `resetHour` AM.
    static var current: String {
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)

        // If it's before 4 AM, treat it as still the previous day
        let logicalDate: Date
        if hour < resetHour {
            logicalDate = cal.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            logicalDate = now
        }

        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.string(from: logicalDate)
    }
}
