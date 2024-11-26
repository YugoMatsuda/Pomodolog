import SwiftUI

struct TimerRingView: View {
    @State private var waveOffset = Angle(degrees: 0)
    @State private var waveOffset2 = Angle(degrees: 180)
    @Environment(\.colorScheme) var colorScheme
    
    let config: Config
    
    struct Config: Equatable {
        var isOngoing: Bool
        var progress: CGFloat
        var timerInterval: TimeInterval
        var hasFinishedCountDown: Bool
    }
    
    var trimRingScale: CGFloat {
        config.isOngoing ? 1.1 : 0
    }
    
    var dotRingScale: CGFloat {
        config.isOngoing ? 0 : 1.0
    }
    
    var waveProgress: CGFloat {
        config.isOngoing ? config.progress : 1
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
            let circleSize =  proxy.size.width
            // MARK: Timer Ring
            ZStack{
                Circle()
                    .stroke(innserCircleBackground, lineWidth: 10)
                    .scaleEffect(trimRingScale)
                
                Circle()
                    .trim(from: 0, to: config.progress)
                    .stroke(Color.blue.gradient, lineWidth: 10)
                    .scaleEffect(trimRingScale)
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
                    .offset(x: circleSize / 2)
                    .rotationEffect(.init(degrees: (config.progress * 360) + 270.0))
                    .scaleEffect(trimRingScale)

                
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
                    .scaleEffect(0.9)

                let text = config.hasFinishedCountDown ? "+" : ""
                Text(text + config.timerInterval.timerText)
                    .foregroundStyle(.white)
                    .font(
                        .system(
                            size: UIDevice.current.userInterfaceIdiom == .phone ? 45 : 90,
                            weight: .bold
                        )
                    )
                    .animation(.snappy, value: config.timerInterval)
            }
            .animation(.easeInOut, value: waveProgress)
            .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
            .onChange(of: config) { oldValue, newValue in
//                startWaveAnimation()
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

extension TimerRingView.Config {
    static func makeIdle(_ timerSetting: TimerSetting) -> TimerRingView.Config {
        .init(
            isOngoing: false,
            progress: 1,
            timerInterval: timerSetting.sessionTimeInterval,
            hasFinishedCountDown: false
        )
    }
}
