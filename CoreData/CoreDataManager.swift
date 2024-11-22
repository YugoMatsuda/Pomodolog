import CoreData
import CloudKit

struct CoreDataManager {
    static let shared = CoreDataManager()

    static let preview: CoreDataManager = {
        let result = CoreDataManager(type: .preview)
        return result
    }()
    
    static let test: CoreDataManager = {
        let result = CoreDataManager(type: .test)
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(type: ContainerType = .impl) {
        container = NSPersistentCloudKitContainer(name: "Pomodolog")
        let appGroupID = "group.UGO.Pomodolog"
        let cloudContainerIdentifier = "iCloud.UGO.Pomodolog"
        let sqlite = "Pomodolog.sqlite"

        guard let newDocumentDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("共有コンテナにアクセスできません。")
        }
        let newStoreURL = newDocumentDirectory.appendingPathComponent(sqlite)
        
        switch type {
        case .impl:
            let storeDescription = NSPersistentStoreDescription(url: newStoreURL)
            let cloudOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudContainerIdentifier)
            storeDescription.cloudKitContainerOptions = cloudOptions

            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            container.persistentStoreDescriptions = [storeDescription]
        case .test, .preview:
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    
    enum ContainerType {
        case impl
        case test
        case preview
    }
}
