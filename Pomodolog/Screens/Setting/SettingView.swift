import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationStack {
            Text("Setting")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Setting")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
