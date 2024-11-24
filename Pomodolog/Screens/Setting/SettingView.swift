import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationStack {
            List {
                #if DEBUG
                NavigationLink(destination: DebugView()) {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Setting")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
