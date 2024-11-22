import ComposableArchitecture
import CoreData

protocol CoreDataClientProtocol: Sendable {
    func insert<T: CoreDataEntityConvertible>(
        _ domainEntity: T
    ) async throws
    
    func fetchAll<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        sortDescriptors: [SortDescriptorData]?
    ) async throws -> [T]
    
    func fetch<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        predicate: PredicateData?,
        sortDescriptors: [SortDescriptorData]?,
        limit: Int?
    ) async throws -> [T]
    
    func fetchById<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        id: String
    ) async throws -> T?
    
    func deleteById<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        id: String
    ) async throws
    
    func observe<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        predicate: PredicateData?,
        sortDescriptors: [SortDescriptorData]?,
        limit: Int?
    ) -> AsyncThrowingStream<[T], Error>
    
    
    func observeRemoteChange(
    ) -> AsyncThrowingStream<Void, Error>
}

// CoreDataClient の実装
struct CoreDataClient: CoreDataClientProtocol {
    static let shared = CoreDataClient()
    private let container = CoreDataManager.shared.container
    
    func insert<T: CoreDataEntityConvertible>(_ domainEntity: T) async throws {
        try await container.schedule(contextType: .background) { ctx in
            _ = try T.entityType.fromDomain(domainEntity, in: ctx)
        }
    }
    
    func fetchAll<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        sortDescriptors: [SortDescriptorData]?
    ) async throws -> [T] {
        return try await container.schedule(contextType: .background) { ctx in
            let fetchRequest = NSFetchRequest<T.Entity>(entityName: T.entityType.entityName)
            if let sortData = sortDescriptors {
                fetchRequest.sortDescriptors = sortData.map { $0.toNSSortDescriptor() }
            }
            let fetchedEntities = try ctx.fetch(fetchRequest)
            return fetchedEntities.compactMap { $0.toDomain(context: ctx) }
        }
    }
    
    func fetch<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        predicate: PredicateData?,
        sortDescriptors: [SortDescriptorData]?,
        limit: Int?
    ) async throws -> [T] {
        return try await container.schedule(contextType: .background) { ctx in
            let fetchRequest = NSFetchRequest<T.Entity>(entityName: T.entityType.entityName)
            
            if let limit {
                fetchRequest.fetchLimit = limit
            }
            
            // Predicateを復元
            if let predicateData = predicate {
                fetchRequest.predicate = predicateData.toNSPredicate()
            }
            
            // SortDescriptorを復元
            if let sortData = sortDescriptors {
                fetchRequest.sortDescriptors = sortData.map { $0.toNSSortDescriptor() }
            }
            
            let fetchedEntities = try ctx.fetch(fetchRequest)
            return fetchedEntities.compactMap { $0.toDomain(context: ctx) }
        }
    }
    
    func fetchById<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        id: String
    ) async throws -> T? {
        return try await container.schedule(contextType: .background) { ctx in
            let fetchRequest = NSFetchRequest<T.Entity>(entityName: T.entityType.entityName)
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == %@", id  as CVarArg)
            let fetchedEntities = try ctx.fetch(fetchRequest)
            return fetchedEntities.first?.toDomain(context: ctx)
        }
    }
    
    func deleteById<T: CoreDataEntityConvertible>(
        _ type: T.Type,
        id: String
    ) async throws {
        try await container.schedule(contextType: .background) { ctx in
            let fetchRequest = NSFetchRequest<T.Entity>(entityName: T.entityType.entityName)
            fetchRequest.predicate = NSPredicate(format: "id == %@", id  as CVarArg)
            let entity = try ctx.fetch(fetchRequest).first
            guard let entity else {
                throw DataBaseError.notFound
            }
            ctx.delete(entity)
        }
    }
    
    func observe<T>(
        _ type: T.Type,
        predicate: PredicateData?,
        sortDescriptors: [SortDescriptorData]?,
        limit: Int?)
    -> AsyncThrowingStream<[T], Error> where T : CoreDataEntityConvertible {
        AsyncThrowingStream { (continuation: AsyncThrowingStream<[T], Error>.Continuation) in
            let task = Task {
                do {
                    let initialValues = try await self.fetch(
                        type,
                        predicate: predicate,
                        sortDescriptors: sortDescriptors,
                        limit: limit
                    )
                    continuation.yield(initialValues)
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                
                let observeRemoteChange = NotificationCenter.default.observeNotifications(
                    from: .NSPersistentStoreRemoteChange,
                    object: CoreDataManager.shared.container.persistentStoreCoordinator
                )
                
                for try await _ in observeRemoteChange {
                    AppLogger.shared.log("NSPersistentStoreRemoteChange", .debug)
                    do {
                        let updatedValues = try await self.fetch(
                            type,
                            predicate: predicate,
                            sortDescriptors: sortDescriptors,
                            limit: limit
                        )
                        continuation.yield(updatedValues)
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func observeRemoteChange() -> AsyncThrowingStream<Void, Error> {
        AsyncThrowingStream { (continuation: AsyncThrowingStream<Void, Error>.Continuation) in
            let task = Task {
                
                let observeRemoteChange = NotificationCenter.default.observeNotifications(
                    from: .NSPersistentStoreRemoteChange,
                    object: CoreDataManager.shared.container.persistentStoreCoordinator
                )
                
                for try await _ in observeRemoteChange {
                    AppLogger.shared.log("NSPersistentStoreRemoteChange", .debug)
                    continuation.yield(())
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
extension CoreDataClient: DependencyKey {
    static let liveValue: CoreDataClientProtocol = CoreDataClient.shared
}

extension CoreDataClient {
    enum DataBaseError: Error {
        case notFound
    }
}

extension DependencyValues {
    var coreDataClient: CoreDataClientProtocol {
        get { self[CoreDataClient.self] }
        set { self[CoreDataClient.self] = newValue }
    }
}
