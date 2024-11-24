import CoreData

extension PomodoroSession: CoreDataEntityConvertible {
    typealias Entity = CDPomodoroSession
    static var entityType: CDPomodoroSession.Type { CDPomodoroSession.self }
}

extension CDPomodoroSession: DomainConvertible {
    typealias DomainType = PomodoroSession
    
    static var entityName: String {
        "CDPomodoroSession"
    }

    func toDomain(context: NSManagedObjectContext) -> PomodoroSession? {
        guard let id = self.id,
              let sessionTypeRawValue = self.sessionType,
              let sessionType = PomodoroSession.SessionType(rawValue: sessionTypeRawValue),
              let startAt = self.startAt,
              let createAt = self.createAt,
              let updateAt = self.updateAt
        else {
            return nil
        }
        return PomodoroSession(
            id: id,
            sessionType: sessionType,
            tag: self.tag?.toDomain(context: context),
            startAt: startAt,
            endAt: endAt,
            createAt: createAt,
            updateAt: updateAt
        )
    }
    
    static func fromDomain(_ domain: PomodoroSession, in context: NSManagedObjectContext) throws -> Self {
        let fetchRequest: NSFetchRequest<CDPomodoroSession> = CDPomodoroSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", domain.id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)
        let cdPomodoroSession: CDPomodoroSession
        if let existing = results.first {
            cdPomodoroSession = existing
        } else {
            cdPomodoroSession = CDPomodoroSession(context: context)
            cdPomodoroSession.id = domain.id
            cdPomodoroSession.createAt = domain.createAt
        }
        cdPomodoroSession.startAt = domain.startAt
        cdPomodoroSession.endAt = domain.endAt
        cdPomodoroSession.sessionType = domain.sessionType.rawValue
        cdPomodoroSession.updateAt = domain.updateAt
        
        if let tag = domain.tag {
            let tagsFetchRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
            tagsFetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
            fetchRequest.fetchLimit = 1
            let cdTag = try context.fetch(tagsFetchRequest).first
            cdPomodoroSession.tag = cdTag
        } else {
            cdPomodoroSession.tag = nil
        }
            
        return cdPomodoroSession as! Self
    }
}
