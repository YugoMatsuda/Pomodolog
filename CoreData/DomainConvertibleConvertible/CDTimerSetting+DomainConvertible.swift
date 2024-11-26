import CoreData

extension TimerSetting: CoreDataEntityConvertible {
    typealias Entity = CDTimerSetting
    static var entityType: CDTimerSetting.Type { CDTimerSetting.self }
}

extension CDTimerSetting: DomainConvertible {
    typealias DomainType = TimerSetting
    
    static var entityName: String {
        "CDTimerSetting"
    }

    func toDomain(context: NSManagedObjectContext) -> TimerSetting? {
        guard let timerTypeValue = self.timerType,
              let type = TimerSetting.TimerType(rawValue: timerTypeValue)
        else { return nil }
        return TimerSetting.init(
            sessionTimeMinutes: Int(self.sessionTimeMinutes),
            shortBreakTimeMinutes: Int(self.shortBreakTimeMinutes),
            longBreakTimeMinutes: Int(self.longBreakMinutes),
            sessionCycle: Int(self.sessionCycle),
            timerType: type,
            currentTag: self.currentTag?.toDomain(context: context)
        )
    }
    
    static func fromDomain(_ domain: TimerSetting, in context: NSManagedObjectContext) throws -> Self {
        let fetchRequest: NSFetchRequest<CDTimerSetting> = CDTimerSetting.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", TimerSetting.id() as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)
        let cdTimerSetting: CDTimerSetting
        if let existing = results.first {
            cdTimerSetting = existing
        } else {
            cdTimerSetting = CDTimerSetting(context: context)
            cdTimerSetting.id = TimerSetting.id()
        }
        cdTimerSetting.sessionTimeMinutes = Int16(domain.sessionTimeMinutes)
        cdTimerSetting.timerType = domain.timerType.rawValue
        cdTimerSetting.shortBreakTimeMinutes = Int16(domain.shortBreakTimeMinutes)
        cdTimerSetting.longBreakMinutes = Int16(domain.longBreakTimeMinutes)
        cdTimerSetting.sessionCycle = Int16(domain.sessionCycle)
        
        if let tag = domain.currentTag {
            cdTimerSetting.currentTag = try CDTag.fromDomain(tag, in: context)
        } else {
            cdTimerSetting.currentTag = nil
        }
        
        return cdTimerSetting as! Self
    }
}
