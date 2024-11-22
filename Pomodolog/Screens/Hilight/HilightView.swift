import SwiftUI

struct HilightView: View {
    var body: some View {
        NavigationStack {
            Text("Hilight")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Hilight")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HilightView()
}
