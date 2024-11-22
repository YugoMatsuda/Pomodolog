import Foundation

struct PomodoroSession: Identifiable, Equatable, Sendable {
    var id: String
    var sessionType: SessionType
    var startAt: Date
    var endAt: Date?
    var createAt: Date
    var updateAt: Date
    
    init(
        id: String,
        sessionType: SessionType,
        startAt: Date,
        endAt: Date?,
        createAt: Date,
        updateAt: Date
    ) {
        self.id = id
        self.sessionType = sessionType
        self.startAt = startAt
        self.endAt = endAt
        self.createAt = createAt
        self.updateAt = updateAt
    }
}

extension PomodoroSession {
    enum SessionType: String, Equatable, CaseIterable {
        case work
        case `break`
    }
}
