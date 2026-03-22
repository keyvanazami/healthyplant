import Foundation

// MARK: - Date Extensions

extension Date {

    /// e.g. "Mar 22, 2026"
    var mediumFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// e.g. "3:45 PM"
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// e.g. "March 2026"
    var monthYearFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    /// e.g. "22"
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    /// Start of the current day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Start of the current month
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Number of days in the current month
    var daysInMonth: Int {
        let range = Calendar.current.range(of: .day, in: .month, for: self)
        return range?.count ?? 30
    }

    /// Weekday index (0 = Sunday) for the first day of the month
    var firstWeekdayOfMonth: Int {
        let first = startOfMonth
        let weekday = Calendar.current.component(.weekday, from: first)
        return weekday - 1 // Convert 1-based to 0-based
    }

    /// Returns a new date by adding the given number of months
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Check if two dates share the same calendar day
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - String Extensions

extension String {
    /// Returns a trimmed version of the string
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns true if string is empty or only whitespace
    var isBlank: Bool {
        trimmed.isEmpty
    }
}

// MARK: - Height Formatting

extension Int {
    /// Format a total-inches value as "Xft Yin"
    static func formatHeight(feet: Int, inches: Int) -> String {
        "\(feet)ft \(inches)in"
    }
}
