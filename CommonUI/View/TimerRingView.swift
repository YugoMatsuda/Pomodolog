import SwiftUI

struct TimerRingView: View {
    @State private var waveOffset = Angle(degrees: 0)
    @State private var waveOffset2 = Angle(degrees: 180)
    @State private var timer: Timer?
    @Environment(\.colorScheme) var colorScheme
    
    let config: Config
    
    struct Config: Equatable {
        var progress: CGFloat
        var timerInterval: TimeInterval
        var hasFinishedCountDown: Bool
        var timerState: TimerState
        var currentTag: Tag
        
        init(
            progress: CGFloat,
            timerInterval: TimeInterval,
            hasFinishedCountDown: Bool,
            timerState: TimerState,
            currentTag: Tag
        ) {
            self.progress = progress
            self.timerInterval = timerInterval
            self.hasFinishedCountDown = hasFinishedCountDown
            self.timerState = timerState
            self.currentTag = currentTag
        }
    }
    
    var trimRingScale: CGFloat {
        config.timerState.isWorkSession ? 1.1 : 0
    }
    
    var dotRingScale: CGFloat {
        config.timerState.isOngoingSession ? 0 : 1.0
    }
    
    var waveProgress: CGFloat {
        config.timerState.isOngoingSession ? config.progress : 1
    }
    
    var timerColor: Color {
        Color(hex: config.currentTag.colorHex) ?? Color.blue
    }

    private var innserCircleBackground: Color {
        return Color(UIColor.darkGray)
    }
    
    var body: some View {
        GeometryReader{ proxy in
            let circleSize =  proxy.size.width
            // MARK: Timer Ring
            ZStack{
                Circle()
                    .stroke(innserCircleBackground, lineWidth: 4)
                    .scaleEffect(trimRingScale)
                
                Circle()
                    .trim(from: 0, to: config.progress)
                    .stroke(timerColor.gradient, lineWidth: 4)
                    .scaleEffect(trimRingScale)
                    .rotationEffect(.init(degrees: 270))
                
                DotCircleView(timerColor: timerColor)
                    .scaleEffect(dotRingScale)

                
                Circle()
                    .fill(timerColor)
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
                    .fill(waveProgress >= 1 ? timerColor : innserCircleBackground)
                    .overlay {
                        if 0 < waveProgress && waveProgress < 1 {
                            Wave(offset: Angle(degrees: self.waveOffset.degrees), ratio: waveProgress)
                                .fill(timerColor.gradient.opacity(0.8))
                                .mask {
                                    Circle()
                                }
                            
                            Wave(offset: Angle(degrees: self.waveOffset2.degrees), ratio: waveProgress)
                                .fill(timerColor.opacity(0.5))
                                .mask {
                                    Circle()
                                }
                        }
                    }
                    .scaleEffect(0.9)

                VStack(spacing: 0) {
                    if !config.timerState.isOngoingSession {
                        Text(config.currentTag.name)
                            .foregroundStyle(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    let text = config.hasFinishedCountDown ? "+" : ""
                    Text(text + config.timerInterval.timerText)
                        .foregroundStyle(.white)
                        .font(
                            .system(
                                size: UIDevice.current.userInterfaceIdiom == .phone ? 45 : 90,
                                weight: .bold
                            )
                        )
                        .monospacedDigit()
                        .contentTransition(.numericText(value: config.timerInterval))
                        .animation(.snappy, value: config.timerInterval.timerText)
                }
              
            }
            .animation(.easeInOut, value: waveProgress)
            .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
            .onChange(of: config.timerState.isOngoingSession) { oldValue, newValue in
                self.timer?.invalidate()
                guard newValue else { return }
                startWaveAnimation()
            }
        }
    }
    
    private func startWaveAnimation() {
        withAnimation(Animation.linear(duration: 1.5)) {
            self.waveOffset = Angle(degrees: self.waveOffset.degrees + 360)
            self.waveOffset2 = Angle(degrees: self.waveOffset2.degrees - 360)
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(Animation.linear(duration: 1.5)) {
                    self.waveOffset = Angle(degrees: self.waveOffset.degrees + 360)
                    self.waveOffset2 = Angle(degrees: self.waveOffset2.degrees - 360)
                }
            }
        }
    }
    
    struct DotCircleView: View {
        let painted: CGFloat = 6
        let unpainted: CGFloat = 6
        let timerColor: Color
        @State private var rotate: Double = 0

        var body: some View {
            Circle()
                .stroke(timerColor, style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [painted, unpainted]))
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
            progress: 1,
            timerInterval: timerSetting.timerType == .countDown ? timerSetting.sessionTimeInterval : 0,
            hasFinishedCountDown: false,
            timerState: .initial,
            currentTag: timerSetting.currentTag ?? .focus()
        )
    }
}
