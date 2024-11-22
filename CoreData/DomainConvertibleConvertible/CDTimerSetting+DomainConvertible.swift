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
        return TimerSetting.init(
            shortBreakTimeMinutes: Int(self.shortBreakTimeMinutes),
            longBreakTimeMinutes: Int(self.longBreakMinutes),
            sessionCycle: Int(self.sessionCycle),
            timerType: self.timerType
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
        cdTimerSetting.timerType = domain.timerType
        cdTimerSetting.shortBreakTimeMinutes = Int16(domain.shortBreakTimeMinutes)
        cdTimerSetting.longBreakMinutes = Int16(domain.longBreakTimeMinutes)
        cdTimerSetting.sessionCycle = Int16(domain.sessionCycle)
        
        return cdTimerSetting as! Self
    }
}
