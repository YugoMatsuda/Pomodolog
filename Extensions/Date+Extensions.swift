import Foundation

extension Date {
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        let calendar = Calendar(identifier: .gregorian)
        var current = calendar
        current.firstWeekday = 2 // Set Monday as the first day of the week
        
        guard let startOfWeek = current.date(from: current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return false
        }
        
        let endOfWeek = current.date(byAdding: .day, value: 6, to: startOfWeek)!
        return self >= startOfWeek && self <= endOfWeek
    }
    
    var isThisMonth: Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        
        return month == currentMonth && year == currentYear
    }
    
    var isThisYear: Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let year = calendar.component(.year, from: self)
        
        return year == currentYear
    }
    
    func toFormattedString() -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        let currentDate = Date()
        
        // Check if the date is today
        if calendar.isDateInToday(self) {
            return "Today"
        }
        
        // Check if the date is within the current year
        let yearComponent = calendar.component(.year, from: self)
        let currentYearComponent = calendar.component(.year, from: currentDate)
        
        if yearComponent == currentYearComponent {
            formatter.dateFormat = "M/d"
        } else {
            formatter.dateFormat = "yyyy/M/d"
        }
        
        return formatter.string(from: self)
    }
    
    func isWithinSpecifiedMinutes(minutes: Int) -> Bool {
        let now = Date.now
        let nMinutesInSeconds = TimeInterval(minutes * 60)
        
        // 日付と現在の差を秒単位で取得
        let difference = abs(now.timeIntervalSince(self))
        
        return difference <= nMinutesInSeconds
    }
    
    func getCurrentTimeRange(minuteInterval: Int) -> String {
        let calendar = Calendar.current

        let components = calendar.dateComponents([.hour, .minute], from: self)
        guard let currentHour = components.hour, let currentMinute = components.minute else {
            return ""
        }
        let startMinute = (currentMinute / minuteInterval) * minuteInterval
        let endMinute = startMinute + minuteInterval

        var endHour = currentHour
        var adjustedEndMinute = endMinute
        if endMinute >= 60 {
            endHour += 1
            adjustedEndMinute = endMinute - 60
            if endHour >= 24 {
                endHour = endHour % 24
            }
        }

        let isAM = currentHour < 12
        let amPm = isAM ? "AM" : "PM"

        // 時刻のフォーマット
        let startTime = String(format: "%02d:%02d", currentHour, startMinute)
        let endTime = String(format: "%02d:%02d", endHour, adjustedEndMinute)

        return "\(amPm): \(startTime) ~ \(endTime)"
    }
    
    var minimumWeekday: String {
        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale.current
        // 曜日の1文字表記を取得
        let weekdayIndex = Calendar.current.component(.weekday, from: self) - 1
        return shortFormatter.veryShortStandaloneWeekdaySymbols[weekdayIndex]
    }
    
    var shortWeekday: String {
        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale.current
        // 曜日の3文字表記を指定
        shortFormatter.dateFormat = "EEE"
        return shortFormatter.string(from: self)
    }
    
    var longWeekday: String {
        let shortFormatter = DateFormatter()
        // ロケールを設定（必要に応じて変更）
        shortFormatter.locale = Locale.current
        // 曜日の3文字表記を指定
        shortFormatter.dateFormat = "EEEE"
        return shortFormatter.string(from: self)
    }
}

extension Date {
    func startOfHour() -> Self {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: self)) ?? self
    }
    
    func startOfDay() -> Self {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }
    
    func endOfDay() -> Self {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self)!
    }
    
    func startOfNextDay() -> Self {
        let calendar = Calendar.current
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: self) else {
            return self
        }
        return calendar.startOfDay(for: nextDay)
    }

    
    func startOfMonth() -> Self {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: self))) ?? Date()
    }
    
    func startOfNextMonth() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: self)
        components.month = components.month! + 1
        components.day = 1
        return calendar.date(from: components)!
    }
    
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        guard let startOfWeek = calendar.date(from: components) else {
            return self
        }
        return calendar.date(byAdding: .day, value: 1, to: startOfWeek) ?? self
    }
    
    func startOfNextWeek() -> Date {
        let calendar = Calendar.current
        let startOfWeek = startOfWeek()
        guard let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return self
        }
        return nextWeekStart
    }
    
    func endOfWeek() -> Date {
        let calendar = Calendar.current
        let components = DateComponents(day: 6)
        guard let endOfWeek = calendar.date(byAdding: components, to: self.startOfWeek()) else {
            return self
        }
        return endOfWeek
    }
    
    func startOfYear() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        guard let yearStart = calendar.date(from: components) else {
            return self
        }
        return yearStart
    }
    
    func startOfNextYear() -> Date {
        let calendar = Calendar.current
        let yearStart = startOfYear()
        guard let nextYearStart = calendar.date(byAdding: .year, value: 1, to: yearStart) else {
            return self
        }
        return nextYearStart
    }
    
    func dateByAdding(unit: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: unit, value: value, to: self) ?? Date()
    }
    
    func dateBySubtracting(unit: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: unit, value: -value, to: self) ?? Date()
    }
    
    func dateByAddingHour() -> Date {
        return Calendar.current.date(byAdding: .hour, value: 1, to: self) ?? Date()
    }
    
    func dateBySubtractingHour() -> Date {
        return Calendar.current.date(byAdding: .hour, value: -1, to: self) ?? Date()
    }
    
    func dateByAddingDay() -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self) ?? Date()
    }
    
    func dateBySubtractingDay() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self) ?? Date()
    }
    
    func dateByAddingWeek() -> Date {
        return Calendar.current.date(byAdding: .day, value: 7, to: self) ?? Date()
    }
    
    func dateBySubtractingWeek() -> Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: self) ?? Date()
    }
    
    func dateByAddingMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: 1, to: self) ?? Date()
    }
    
    func dateBySubtractingMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: self) ?? Date()
    }
    
    func dateByAddingYear() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: self) ?? Date()
    }
    
    func dateBySubtractingYear() -> Date {
        return Calendar.current.date(byAdding: .year, value: -1, to: self) ?? Date()
    }

    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current // ユーザーの現在のロケールを使用
        formatter.unitsStyle = .short // 短縮形を使用（例: "5m ago"）
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
