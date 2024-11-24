import Foundation
import SwiftUI

struct Tag: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var colorHex: String
    var sort: Int
    var sessionIds: [String]
    var createAt: Date
    var updateAt: Date
    
    init(
        id: String,
        name: String,
        colorHex: String,
        sort: Int,
        sessionIds: [String],
        createAt: Date,
        updateAt: Date
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sort = sort
        self.sessionIds = sessionIds
        self.createAt = createAt
        self.updateAt = updateAt
    }
}

extension Tag {
    static func focus() -> Self {
        .init(
            id: "focus",
            name: "🎯 Focus",
            colorHex: Color.green.toHex() ?? "",
            sort: 0,
            sessionIds: [],
            createAt: .now,
            updateAt: .now
        )
    }
    
    static func defaultTags() -> [Tag] {
        [
            .focus(),
            .init(
                id: "work",
                name: "💻 Work",
                colorHex: Color.blue.toHex() ?? "",
                sort: 1,
                sessionIds: [],
                createAt: .now,
                updateAt: .now
            ),
            .init(
                id: "reading",
                name: "📖 Reading",
                colorHex: Color.cyan.toHex() ?? "",
                sort: 1,
                sessionIds: [],
                createAt: .now,
                updateAt: .now
            ),
            .init(
                id: "study",
                name: "✏️ Study",
                colorHex: Color.purple.toHex() ?? "",
                sort: 1,
                sessionIds: [],
                createAt: .now,
                updateAt: .now
            )
        ]
    }
}
