import Foundation

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
