//
//  DebugView.swift
//  Pomodolog
//
//  Created by Yugo Matsuda on 2024-11-24.
//

import SwiftUI
import ComposableArchitecture
import CoreData

struct DebugView: View {
    @State var userId: String?
    
    var body: some View {
        List {
            Text("Keychain UserId: \(userId ?? "nil")")

            Button("delete Keychain User") {
                KeychainHelper.deleteUserId()
            }
            
            Button("reset core data") {
                let container = CoreDataManager.shared.container
                let context = container.viewContext
                for entityName in container.managedObjectModel.entitiesByName.keys {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    
                    do {
                        try context.execute(batchDeleteRequest)
                        try context.save()
                    } catch {
                        print("Failed to delete \(entityName): \(error)")
                    }
                }
                context.reset()
            }
        }
        .onAppear {
            userId = try? KeychainHelper.getUserId()
        }
    }
}
