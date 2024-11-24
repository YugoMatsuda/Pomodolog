import SwiftUI

struct TimerRingView: View {
    @State var progress: CGFloat = 1
    @State private var waveOffset = Angle(degrees: 0)
    @State private var waveOffset2 = Angle(degrees: 180)
    @Environment(\.colorScheme) var colorScheme
    @State private var timer: Timer?

    private var innserCircleBackground: Color {
        #if os(iOS)
            if colorScheme == .dark {
                return Color(UIColor.darkGray)
            } else {
                return Color(UIColor.systemGroupedBackground)
            }
        #else
        return Color(UIColor.darkGray).opacity(0.4)
        #endif
    }
    
    var body: some View {
        GeometryReader{ proxy in
            let circleSize = min(390, proxy.size.width * 0.65)
            VStack(spacing: 15){
                // MARK: Timer Ring
                ZStack{
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue.gradient, lineWidth: 10)
                        .scaleEffect(1.15)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                        .overlay(content: {
                            Circle()
                                .fill(.white)
                                .padding(5)
                        })
                        .frame(width: circleSize, height: circleSize, alignment: .center)
                        .offset(x: circleSize / 2)
                        .rotationEffect(.init(degrees: 270))
                        .scaleEffect(1.15)

                    
                    Circle()
                        .fill(innserCircleBackground)
                        .overlay {
                            Wave(offset: Angle(degrees: self.waveOffset.degrees), ratio: 0.7)
                                .fill(Color.blue.gradient.opacity(0.8))
                                .mask {
                                    Circle()
                                }
                            
                            Wave(offset: Angle(degrees: self.waveOffset2.degrees), ratio: 0.7)
                                .fill(Color.blue.opacity(0.5))
                                .mask {
                                    Circle()
                                }
                        }
                    
                    Text("25:00")
                        .font(.system(size: 45, weight: .bold))
                        .animation(.none, value: progress)
                }
                .frame(width: circleSize, height: circleSize, alignment: .center)
                .animation(.easeInOut, value: progress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                startWaveAnimation()
            }
        }
    }
    
    private func startWaveAnimation() {
        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
            self.waveOffset = Angle(degrees: self.waveOffset.degrees + 360)
            self.waveOffset2 = Angle(degrees: self.waveOffset2.degrees - 360)
        }
    }
}

#Preview {
    TimerRingView()
}
