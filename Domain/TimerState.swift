import Foundation

enum TimerState: Equatable {
    case initial
    case work
    case workBreak
    
    var isOngoingSession: Bool {
        switch self {
        case .initial:
            return false
        case .work, .workBreak:
            return true
        }
    }
    
    var isWorkSession: Bool {
        switch self {
        case .initial, .workBreak:
            return false
        case .work:
            return true
        }
    }
}
