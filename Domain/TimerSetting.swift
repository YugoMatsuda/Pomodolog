import Foundation

struct TimerSetting: Equatable, Sendable {
    var shortBreakTimeMinutes: Int
    var longBreakTimeMinutes: Int
    var sessionCycle: Int
    var timerType: TimerType
    var currentTag: Tag?
    
    init(
        shortBreakTimeMinutes: Int,
        longBreakTimeMinutes: Int,
        sessionCycle: Int,
        timerType: TimerType,
        currentTag: Tag?
    ) {
        self.shortBreakTimeMinutes = shortBreakTimeMinutes
        self.longBreakTimeMinutes = longBreakTimeMinutes
        self.sessionCycle = sessionCycle
        self.timerType = timerType
        self.currentTag = currentTag
    }
}

extension TimerSetting {
    enum TimerType: Equatable, Codable {
        case countup
        case countDown(minutes: Int)
        
        static func initial() -> TimerType {
            .countDown(minutes: 25)
        }
    }
}

extension TimerSetting {
    static func id() -> String {
        "0"
    }
    
    static func initial() -> TimerSetting {
        .init(
            shortBreakTimeMinutes: 5,
            longBreakTimeMinutes: 15,
            sessionCycle: 4,
            timerType: .initial(),
            currentTag: .focus()
        )
    }
}
