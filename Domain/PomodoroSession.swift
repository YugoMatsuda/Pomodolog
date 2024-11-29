import Foundation

struct PomodoroSession: Identifiable, Equatable, Sendable {
    var id: String
    var sessionType: SessionType
    var tag: Tag?
    var startAt: Date
    var endAt: Date?
    var createAt: Date
    var updateAt: Date
    
    init(
        id: String,
        sessionType: SessionType,
        tag: Tag?,
        startAt: Date,
        endAt: Date?,
        createAt: Date,
        updateAt: Date
    ) {
        self.id = id
        self.sessionType = sessionType
        self.tag = tag
        self.startAt = startAt
        self.endAt = endAt
        self.createAt = createAt
        self.updateAt = updateAt
    }
    
    var duration: TimeInterval {
        endAt?.timeIntervalSince(startAt) ?? .zero
    }
}

extension PomodoroSession {
    enum SessionType: String, Equatable, CaseIterable {
        case work
        case `break`
    }
}

extension PomodoroSession {
    static func makeNewWorkSession(
        _ tag: Tag?
    ) -> Self {
        let now: Date = .now
        return .init(
            id: UUID().uuidString,
            sessionType: .work,
            tag: tag,
            startAt: now,
            endAt: nil,
            createAt: now,
            updateAt: now
        )
    }
    
    static func makeNewBreakSession(
        _ tag: Tag?
    ) -> Self {
        let now: Date = .now
        return .init(
            id: UUID().uuidString,
            sessionType: .break,
            tag: tag,
            startAt: now,
            endAt: nil,
            createAt: now,
            updateAt: now
        )
    }
}
