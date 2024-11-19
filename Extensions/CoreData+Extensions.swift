import CoreData
import Foundation

extension NSPersistentContainer {
    func schedule<T>(
        contextType: ContextType = .view,
        _ action: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try Task.checkCancellation()

        let context: NSManagedObjectContext
        switch contextType {
        case .view:
            context = viewContext
        case .background:
            context = newBackgroundContext()
        case .defaultData(let author):
            context = newBackgroundContext()
            context.transactionAuthor = author
        }
        // 要検証
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        return try await context.perform(schedule: .immediate) {
            return try context.execute(action)
        }
    }
}

extension NSPersistentContainer {
    enum ContextType {
        case view
        case background
        case defaultData(String)
    }
}

extension NSManagedObjectContext {
    func execute<T>(
        _ action: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) throws -> T {
        defer {
            self.reset()
        }

        let value = try action(self)

        if hasChanges {
            try save()
        }

        return value
    }
}
