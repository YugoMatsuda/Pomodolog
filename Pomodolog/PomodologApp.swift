//
//  PomodologApp.swift
//  Pomodolog
//
//  Created by Yugo Matsuda on 2024-11-07.
//

import SwiftUI

@main
struct PomodologApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppView(store: self.delegate.store)
        }
    }
}
