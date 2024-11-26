import SwiftUI

struct TagItemView: View {
    let name: String
    let colorHex: String
    
    var body: some View {
        Text(name)
            .font(.system(size: 16))
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: colorHex))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
