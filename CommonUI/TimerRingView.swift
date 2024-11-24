import SwiftUI

struct TimerRingView: View {
    @State var progress: CGFloat = 0.7
    @State private var waveOffset = Angle(degrees: 0)
    @State private var waveOffset2 = Angle(degrees: 180)
    @Environment(\.colorScheme) var colorScheme
    @State private var timer: Timer?
    
    @State var isOngoing: Bool = false
    
    var outerRingScale: CGFloat {
        isOngoing ? 1.15 : 0
    }
    
    var dotRingScale: CGFloat {
        isOngoing ? 0 : 1.15
    }
    
    var waveProgress: CGFloat {
        isOngoing ? progress : 1
    }

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
            let circleSize = min(390, proxy.size.width * 0.6)
            Button(action: {
                withAnimation {
                    isOngoing.toggle()
                }
            }, label: {
                VStack(spacing: 15){
                    // MARK: Timer Ring
                    ZStack{
                        Circle()
                            .stroke(innserCircleBackground, lineWidth: 10)
                            .scaleEffect(outerRingScale)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue.gradient, lineWidth: 10)
                            .scaleEffect(outerRingScale)
                            .rotationEffect(.init(degrees: 270))
                        
                        DotCircleView()
                            .scaleEffect(dotRingScale)

                        
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
                            .rotationEffect(.init(degrees: (progress * 360) + 270.0))
                            .scaleEffect(outerRingScale)

                        
                        Circle()
                            .fill(waveProgress >= 1 ? Color.blue : innserCircleBackground)
                            .overlay {
                                if waveProgress < 1 {
                                    Wave(offset: Angle(degrees: self.waveOffset.degrees), ratio: waveProgress)
                                        .fill(Color.blue.gradient.opacity(0.8))
                                        .mask {
                                            Circle()
                                        }
                                    
                                    Wave(offset: Angle(degrees: self.waveOffset2.degrees), ratio: waveProgress)
                                        .fill(Color.blue.opacity(0.5))
                                        .mask {
                                            Circle()
                                        }
                                }
                            }
                        
                        Text("25:00")
                            .font(.system(size: 45, weight: .bold))
                    }
                    .frame(width: circleSize, height: circleSize, alignment: .center)
                    .animation(.easeInOut, value: waveProgress)
                }
            })
            .buttonStyle(ShrinkButtonStyle())
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
    
    struct DotCircleView: View {
        let painted: CGFloat = 6
        let unpainted: CGFloat = 6
        @State private var rotate: Double = 0

        var body: some View {
            Circle()
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [painted, unpainted]))
                .rotationEffect(.degrees(rotate))
                .onAppear {
                    withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                        rotate += 360
                    }
                }
        }
    }
}

#Preview {
    TimerRingView()
}
