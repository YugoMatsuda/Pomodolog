import CoreData

protocol CoreDataEntityConvertible: Sendable {
    associatedtype Entity: DomainConvertible where Entity.DomainType == Self
    static var entityType: Entity.Type { get }
}
