import SwiftUI

struct TimerRingView: View {
    @State private var waveOffset = Angle(degrees: 0)
    @State private var waveOffset2 = Angle(degrees: 180)
    @State private var timer: Timer?
    @Environment(\.colorScheme) var colorScheme
    
    let param: TimerRingParam
    
    private var innserCircleBackground: Color {
        return Color(UIColor.darkGray)
    }
    
    var body: some View {
        GeometryReader{ proxy in
            let circleSize =  proxy.size.width
            Group {
                ZStack {
                    switch param {
                    case .idle(let data):
                        DotCircleView(timerColor: param.timerColor)
                            .transition(.scale)
                            .scaleEffect(1.05)

                        Circle()
                            .fill(param.timerColor)
                            .scaleEffect(0.9)
                        
                        VStack(spacing: 0) {
                            Text(data.currentTag.name)
                                .foregroundStyle(.white)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(data.timerInterval.timerText)
                                .foregroundStyle(.white)
                                .font(
                                    .system(
                                        size: UIDevice.current.userInterfaceIdiom == .phone ? 45 : 90,
                                        weight: .bold
                                    )
                                )
                                .monospacedDigit()
                                .contentTransition(.numericText(value: data.timerInterval))
                                .animation(.snappy, value: data.timerInterval.timerText)
                        }
                    case .workSession(let data):
                        Circle()
                            .stroke(innserCircleBackground, lineWidth: 4)
                            .transition(.scale)
                            .scaleEffect(1.1)

                        Circle()
                            .trim(from: 0, to: data.progress)
                            .stroke(param.timerColor.gradient, lineWidth: 4)
                            .rotationEffect(.init(degrees: 270))
                            .transition(.scale)
                            .scaleEffect(1.1)
                        
                        Circle()
                            .fill(param.timerColor)
                            .frame(width: 30, height: 30)
                            .overlay(content: {
                                Circle()
                                    .fill(.white)
                                    .padding(5)
                            })
                            .offset(x: circleSize / 2)
                            .rotationEffect(.init(degrees: (data.progress * 360) + 270.0))
                            .scaleEffect(1.1)

                        
                        Circle()
                            .fill(data.progress >= 1 ? param.timerColor : innserCircleBackground)
                            .overlay {
                                if 0 < data.progress && data.progress < 1 {
                                    Wave(offset: Angle(degrees: self.waveOffset.degrees), ratio: data.progress)
                                        .fill(param.timerColor.gradient.opacity(0.8))
                                        .mask {
                                            Circle()
                                        }
                                    
                                    Wave(offset: Angle(degrees: self.waveOffset2.degrees), ratio: data.progress)
                                        .fill(param.timerColor.opacity(0.5))
                                        .mask {
                                            Circle()
                                        }
                                }
                            }
                            .scaleEffect(0.9)
                        
                        VStack(spacing: 0) {
                            let text = data.hasFinishedCountDown ? "+" : ""
                            Text(text + data.timerInterval.timerText)
                                .foregroundStyle(.white)
                                .font(
                                    .system(
                                        size: UIDevice.current.userInterfaceIdiom == .phone ? 45 : 90,
                                        weight: .bold
                                    )
                                )
                                .monospacedDigit()
                                .contentTransition(.numericText(value: data.timerInterval))
                                .animation(.snappy, value: data.timerInterval.timerText)
                        }
                        
                    case .breakSession(let data):
                        VStack(spacing: 0) {
                            let text = data.hasFinishedCountDown ? "+" : ""
                            Text(text + data.timerInterval.timerText)
                                .font(
                                    .system(
                                        size: UIDevice.current.userInterfaceIdiom == .phone ? 45 : 90,
                                        weight: .bold
                                    )
                                )
                                .monospacedDigit()
                                .contentTransition(.numericText(value: data.timerInterval))
                                .animation(.snappy, value: data.timerInterval.timerText)
                        }
                    }
                }
            }
            .onChange(of: param.isOngoingSession) { oldValue, newValue in
                self.timer?.invalidate()
                guard newValue else { return }
                startWaveAnimation()
            }
            .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
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

extension TimerRingView.TimerRingParam {
    static func makeIdle(_ timerSetting: TimerSetting) -> TimerRingView.TimerRingParam {
        .idle(
            .init(
                timerInterval: timerSetting.timerType == .countDown ? timerSetting.sessionTimeInterval : 0,
                currentTag: timerSetting.currentTag ?? .focus()
            )
        )
    }
}

extension TimerRingView {
    enum TimerRingParam: Equatable {
        case idle(IdleData)
        case workSession(WorkSessionData)
        case breakSession(BreakSessionData)
        
        struct IdleData: Equatable {
            var timerInterval: TimeInterval
            var currentTag: Tag
        }
        
        struct WorkSessionData: Equatable {
            var timerInterval: TimeInterval
            var progress: CGFloat
            var hasFinishedCountDown: Bool
            var currentTag: Tag
        }
        
        struct BreakSessionData: Equatable {
            var timerInterval: TimeInterval
            var hasFinishedCountDown: Bool
            var currentTag: Tag
        }
        
        var timerColor: Color {
            switch self {
            case .idle(let data):
                Color(hex: data.currentTag.colorHex) ?? Color.blue
            case .workSession(let data):
                Color(hex: data.currentTag.colorHex) ?? Color.blue
            case .breakSession(let data):
                Color(hex: data.currentTag.colorHex) ?? Color.blue
            }
        }
        
        var isOngoingSession: Bool {
            switch self {
            case .idle:
                return false
            case .workSession:
                return true
            case .breakSession:
                return false
            }
        }
    }
}

