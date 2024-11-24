import CoreData
import Foundation

struct SortDescriptorData: Sendable {
    let key: String
    let ascending: Bool
    
    func toNSSortDescriptor() -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: ascending)
    }
}

struct PredicateData: Sendable {
    let format: String
    let arguments: [any CVarArg & Sendable]
    
    func toNSPredicate() -> NSPredicate {
        return NSPredicate(format: format, argumentArray: arguments)
    }
}

extension PredicateData {
    static func getOngoingSession() -> PredicateData {
        return PredicateData(
           format: "endAt == nil",
           arguments: []
       )
    }
}

extension SortDescriptorData {
    static func ascBySort() -> Self {
        .init(key: "sort", ascending: true)
    }
}

