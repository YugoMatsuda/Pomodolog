import SwiftUI

struct TagItemView: View {
    let tag: Tag
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundColor(Color(hex: tag.colorHex))
                .font(.body)

            Text(tag.name)
                .font(.body)
        }
    }
}
