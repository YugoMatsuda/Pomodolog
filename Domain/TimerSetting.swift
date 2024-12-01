import Foundation

struct TimerSetting: Equatable, Sendable {
    var sessionTimeMinutes: Int
    var shortBreakTimeMinutes: Int
    var longBreakTimeMinutes: Int
    var sessionCycle: Int
    var timerType: TimerType
    var backgroundMusicType: BackgroundMusicType
    var currentTag: Tag?
    
    var sessionTimeInterval: TimeInterval {
        TimeInterval(sessionTimeMinutes * 60)
    }
    
    // Optional: Similarly, you can add computed properties for the other time properties
    var shortBreakTimeInterval: TimeInterval {
        TimeInterval(shortBreakTimeMinutes * 60)
    }
    
    var longBreakTimeInterval: TimeInterval {
        TimeInterval(longBreakTimeMinutes * 60)
    }
    
    init(
        sessionTimeMinutes: Int,
        shortBreakTimeMinutes: Int,
        longBreakTimeMinutes: Int,
        sessionCycle: Int,
        timerType: TimerType,
        backgroundMusicType: BackgroundMusicType,
        currentTag: Tag?
    ) {
        self.sessionTimeMinutes = sessionTimeMinutes
        self.shortBreakTimeMinutes = shortBreakTimeMinutes
        self.longBreakTimeMinutes = longBreakTimeMinutes
        self.sessionCycle = sessionCycle
        self.timerType = timerType
        self.backgroundMusicType = backgroundMusicType
        self.currentTag = currentTag
    }
}

extension TimerSetting {
    enum TimerType: String, Equatable, Codable, CaseIterable {
        case countup
        case countDown
        
        static func initial() -> TimerType {
            .countDown
        }
        
        var title: String {
            switch self {
            case .countup:
                return "Count Up"
            case .countDown:
                return "Count Down"
            }
        }
    }
}

extension TimerSetting {
    static func id() -> String {
        "0"
    }
    
    static func initial() -> TimerSetting {
        .init(
            sessionTimeMinutes: 25,
            shortBreakTimeMinutes: 5,
            longBreakTimeMinutes: 15,
            sessionCycle: 4,
            timerType: .initial(),
            backgroundMusicType: .random,
            currentTag: .focus()
        )
    }
}
