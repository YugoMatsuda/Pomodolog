import Foundation

enum TimerState: Equatable {
    case initial
    case session
    case sessionBreak
}

extension TimerState {
    struct SessionData: Equatable {
        let session: PomodoroSession
        
    }
}
