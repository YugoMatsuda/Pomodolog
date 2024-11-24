import ComposableArchitecture
import SwiftUI

@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSetting: TimerSetting
    }

    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)

        enum ViewAction {
            case onAppear
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .binding:
                return .none
            }
        }
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<Home>
    
    
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
        VStack{
            GeometryReader{ proxy in
                VStack(spacing: 15){
                    // MARK: Timer Ring
                    ZStack{
                        let innserCircleSize = proxy.size.width * 0.6
                        
                        Circle()
                            .fill(innserCircleBackground)
                            .frame(width: innserCircleSize, height: innserCircleSize)
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
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue.gradient, lineWidth: 8)
                        
                        // MARK: Knob
                        GeometryReader{proxy in
                            let size = proxy.size
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 30, height: 30)
                                .overlay(content: {
                                    Circle()
                                        .fill(.white)
                                        .padding(5)
                                })
                                .frame(width: size.width, height: size.height, alignment: .center)
                            // MARK: Since View is Rotated Thats Why Using X
                                .offset(x: size.height / 2)
                                .rotationEffect(.init(degrees: 270))
                        }
                        
                        Text("25:00")
                            .font(.system(size: 45, weight: .bold))
                            .animation(.none, value: progress)
                    }
                    .padding(60)
                    .frame(height: proxy.size.width)
                    .animation(.easeInOut, value: progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            startWaveAnimation()
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
    HomeView(store: .init(initialState: Home.State.init(
        timerSetting: Shared(TimerSetting.initial())
    ), reducer: {
        Home()
    }))
}
