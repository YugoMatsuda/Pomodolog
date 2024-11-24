import SwiftUI

struct ShrinkButtonStyle: ButtonStyle {
   
   func makeBody(configuration: Self.Configuration) -> some View {
     
     let isPressed = configuration.isPressed
     
     return configuration.label
       .scaleEffect(x: isPressed ? 0.9 : 1, y: isPressed ? 0.9 : 1, anchor: .center)
       .animation(.spring(response: 0.2, dampingFraction: 0.9, blendDuration: 0), value: isPressed)
   }
 }
