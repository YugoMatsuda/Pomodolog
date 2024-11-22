import Foundation
import CoreData

protocol DomainConvertible where Self: NSManagedObject {
    associatedtype DomainType
    static var entityName: String { get }
    func toDomain(context: NSManagedObjectContext) -> DomainType?
    static func fromDomain(_ domain: DomainType, in context: NSManagedObjectContext) throws -> Self
}
