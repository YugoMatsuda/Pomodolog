import CoreData

extension Tag: CoreDataEntityConvertible {
    typealias Entity = CDTag
    static var entityType: CDTag.Type { CDTag.self }
}

extension CDTag: DomainConvertible {
    typealias DomainType = Tag
    
    static var entityName: String {
        "CDTag"
    }
    
    func toDomain(context: NSManagedObjectContext) -> Tag? {
        guard let id = self.id,
              let name = self.name,
              let colorHex = self.colorHex,
              let sessions = (self.sessions) as? Set<CDPomodoroSession>,
              let createAt = self.createAt,
              let updateAt = self.updateAt
        else {
            return nil
        }
        return Tag(
            id: id,
            name: name,
            colorHex: colorHex,
            sort: Int(self.sort),
            sessionIds: sessions.compactMap { $0.id },
            createAt: createAt,
            updateAt: updateAt
        )
    }
    
    static func fromDomain(
        _ domain: Tag,
        in context: NSManagedObjectContext
    ) throws -> Self {
        let fetchRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", domain.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)
        let cdTag: CDTag
        if let existing = results.first {
            cdTag = existing
        } else {
            cdTag = CDTag(context: context)
            cdTag.id = domain.id
            cdTag.createAt = domain.createAt
        }
        cdTag.name = domain.name
        cdTag.colorHex = domain.colorHex
        cdTag.sort = Int16(domain.sort)
        cdTag.updateAt = Date.now

        let sessionFetch: NSFetchRequest<CDPomodoroSession> = CDPomodoroSession.fetchRequest()
        let sessionIds = domain.sessionIds
        sessionFetch.predicate = NSPredicate(format: "id IN %@", sessionIds)
        let cdPomodoroSessions = try context.fetch(sessionFetch)
        cdTag.sessions = NSSet(array: cdPomodoroSessions)
        
        return cdTag as! Self
    }
}
