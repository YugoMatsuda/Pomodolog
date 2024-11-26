import ComposableArchitecture
import SwiftUI
import AsyncAlgorithms

@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSetting: TimerSetting
        var timerConfig: TimerRingView.Config
        var buttonConfig: ActionButtonConfig = .initilal()

        var ongoingSession: PomodoroSession?
        
        init(
            timerSetting: Shared<TimerSetting>
        ) {
            self._timerSetting = timerSetting
            self.timerConfig = .makeIdle(timerSetting.wrappedValue)
        }
        
        
        var elapsedTime: TimeInterval {
            guard let ongoingSession = ongoingSession else {
                return 0
            }
            return Date.now.timeIntervalSince(ongoingSession.startAt)
        }
        
        var timerState: TimerState {
            guard let ongoingSession = ongoingSession else {
                return .initial
            }
            switch ongoingSession.sessionType {
            case .work:
                return .work
            case .break:
                return .workBreak
            }
        }
        
        enum TimerState: Equatable {
            case initial
            case work
            case workBreak
            
            var isOngoingSession: Bool {
                switch self {
                case .initial:
                    return false
                case .work, .workBreak:
                    return true
                }
            }
            
            var isWorkSession: Bool {
                switch self {
                case .initial, .workBreak:
                    return false
                case .work:
                    return true
                }
            }
        }
        
        struct ObserveResponse: Equatable {
            let ongoingSession: PomodoroSession?
            let timerSetting: TimerSetting
        }
        
        struct ActionButtonConfig: Equatable {
            let title: String
            let shouldShow: Bool
            let buttonColor: Color
        }
    }
    
    enum CancelID { case timer }

    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        enum ViewAction {
            case onLoad
            case didTapActionButton
        }
        
        enum InternalAction {
            case observeResponse(TaskResult<State.ObserveResponse>)
            case passedTime(PomodoroSession)
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient
    @Dependency(\.mainQueue) var mainQueue

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onLoad):
                return .run { send in
                    let initialFetch = try await fetchEntity()
                    await send(
                        .internal(.observeResponse(.success(initialFetch))),
                        animation: .default
                    )
                    let observeRemoteChange = coreDataClient.observeRemoteChange()
                    for try await _ in observeRemoteChange._throttle(for: .seconds(0.5), latest: true) {
                        AppLogger.shared.log("reload home", .debug)
                        let entity = try await fetchEntity()
                        await send(
                            .internal(.observeResponse(.success(entity))),
                            animation: .default
                        )
                    }
                }
            case .view(.didTapActionButton):
                let sessions = makeSession(state: state)
                return .run { send in
                    try await coreDataClient.insertList(sessions)
                }
            case .internal(.observeResponse(.success(let response))):
                Task.cancel(id: CancelID.timer)
                let didChangeToBreak: Bool = {
                    state.ongoingSession?.sessionType == .work
                    && response.ongoingSession?.sessionType == .break
                }()
                AppLogger.shared.log("didChangeToBreak: \(didChangeToBreak)", .debug)
                state.ongoingSession = response.ongoingSession
                state.timerSetting = response.timerSetting
                guard let ongoingSession = response.ongoingSession else {
                    state.timerConfig = .makeIdle(state.timerSetting)
                    state.buttonConfig = .initilal()
                    return .cancel(id: CancelID.timer)
                }
                state.buttonConfig = makeButtonConfig(ongoingSession, state: state)
                state.timerConfig = makeTimerConfig(ongoingSession, state: state)
                return .run { send in
                    for await _ in self.mainQueue.timer(interval: .seconds(1)) {
                        await send(
                            .internal(.passedTime(ongoingSession)),
                            animation: .default
                        )
                    }
                }
                .cancellable(id: CancelID.timer)
            case let .internal(.passedTime(ongoingSession)):
                state.timerConfig = makeTimerConfig(ongoingSession, state: state)
                state.buttonConfig = makeButtonConfig(ongoingSession, state: state)
                return .none
            case .internal:
                return .none
            case .binding:
                return .none
            }
        }
    }
    
    private func fetchEntity() async throws -> State.ObserveResponse {
        async let ongoingSession = coreDataClient.fetch(
            PomodoroSession.self,
            predicate: .getOngoingSession(),
            sortDescriptors: [SortDescriptorData(key: "startAt", ascending: true)],
            limit: 1
        ).first
        async let timerSetting: TimerSetting = coreDataClient
            .fetchById(TimerSetting.self, id: TimerSetting.id()) ?? .initial()
   
        let result = try await (ongoingSession, timerSetting)
        return .init(ongoingSession: result.0, timerSetting: result.1)
    }
    
    private func makeTimerConfig(
        _ ongoingSession: PomodoroSession,
        state: State
    ) -> TimerRingView.Config {
        let timerSetting = state.timerSetting
        let isCountUp = timerSetting.timerType == .countup
        let elapsedTime = state.elapsedTime
        
        switch ongoingSession.sessionType {
        case .work:
            if isCountUp {
                // カウントアップの場合
                let timerInterval = elapsedTime
                let progress = min(timerInterval / timerSetting.sessionTimeInterval, 1)
                
                return TimerRingView.Config(
                    isOngoing: true,
                    progress: CGFloat(progress),
                    timerInterval: timerInterval,
                    hasFinishedCountDown: false
                )
            } else {
                // カウントダウンの場合
                let remainingTime = timerSetting.sessionTimeInterval - elapsedTime
                if remainingTime < 0 {
                    // カウントダウンが終了した場合、カウントアップに切り替える
                    let newTimerInterval = abs(remainingTime)
                    let progress = min(newTimerInterval / timerSetting.sessionTimeInterval, 1)
                    
                    return TimerRingView.Config(
                        isOngoing: true,
                        progress: CGFloat(progress),
                        timerInterval: newTimerInterval,
                        hasFinishedCountDown: true
                    )
                } else {
                    // カウントダウン中
                    let progress = max(remainingTime / timerSetting.sessionTimeInterval, 0)
                    return TimerRingView.Config(
                        isOngoing: true,
                        progress: CGFloat(progress),
                        timerInterval: remainingTime,
                        hasFinishedCountDown: false
                    )
                }
            }
        case .break:
            // 休憩時は常にカウントダウン
            let remainingTime = timerSetting.shortBreakTimeInterval - elapsedTime
            if remainingTime < 0 {
                // カウントダウンが終了した場合、カウントアップに切り替える
                let newTimerInterval = abs(remainingTime)
                let progress = min(newTimerInterval / timerSetting.shortBreakTimeInterval, 1)
                
                return TimerRingView.Config(
                    isOngoing: true,
                    progress: CGFloat(progress),
                    timerInterval: newTimerInterval,
                    hasFinishedCountDown: true
                )
            } else {
                let progress = max(remainingTime / timerSetting.shortBreakTimeInterval, 0)
                return TimerRingView.Config(
                    isOngoing: true,
                    progress: CGFloat(progress),
                    timerInterval: remainingTime,
                    hasFinishedCountDown: false
                )
            }
        }
    }
    
    private func makeButtonConfig(
        _ ongoingSession: PomodoroSession,
        state: State
    ) -> State.ActionButtonConfig {
        let timerSetting = state.timerSetting
        let isCountUp = timerSetting.timerType == .countup
        let elapsedTime = state.elapsedTime
        switch ongoingSession.sessionType {
        case .work:
            if isCountUp {
                return .init(
                    title: "Break",
                    shouldShow: true,
                    buttonColor: .blue
                )
            } else {
                let remainingTime = timerSetting.sessionTimeInterval - elapsedTime
                let hasFinieshedCountDown = remainingTime < 0
                return .init(
                    title: "Break",
                    shouldShow: true,
                    buttonColor: .blue
                )
            }
        case .break:
            return .init(title: "Stop Break", shouldShow: true, buttonColor: .gray)
        }
    }
    
    private func makeSession(
        state: State
    ) -> [PomodoroSession] {
        let tag = state.timerSetting.currentTag
        guard var ongoingSession = state.ongoingSession else {
            return [
                PomodoroSession.makeNewWorkSession(tag)
            ]
        }
        switch ongoingSession.sessionType {
        case .work:
            ongoingSession.endAt = .now
            let nextBreakSession = PomodoroSession.makeNewBreakSession(tag)
            return [
                ongoingSession,
                nextBreakSession
            ]
        case .break:
            var finieshedSession = ongoingSession
            finieshedSession.endAt = .now
            return [
                finieshedSession
            ]
        }
    }
}

extension Home.State.ActionButtonConfig {
    static func initilal() -> Self {
        .init(
            title: "Start",
            shouldShow: true,
            buttonColor: .blue
        )
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<Home>

    var body: some View {
            GeometryReader { proxy in
                let timerSize = min(420, proxy.size.width * 0.6)
                let buttonSize = min(300, proxy.size.width * 0.4)
                ZStack{
                    AuroraView()
                        .opacity(store.timerState.isWorkSession ? 1 : 0)
                    VStack {
                        Button(action: {
                        }) {
                            TimerRingView(config: store.timerConfig)
                                .frame(width: timerSize, height: timerSize)
                        }
                        .buttonStyle(ShrinkButtonStyle())
                        
                        button(size: buttonSize)
                    }
                }
                .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)
            }
            .onLoad {
                store.send(.view(.onLoad))
            }
    }
    
    @ViewBuilder
    func button(size: CGFloat) -> some View {
        if store.buttonConfig.shouldShow {
            VStack {
                Spacer().frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 50 : 80)
                Button {
                    store.send(.view(.didTapActionButton))
                } label: {
                    Text(store.buttonConfig.title)
                        .font(
                            .system(
                                size: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40,
                                weight: .bold
                            )
                        )
                        .frame(width: size, height: UIDevice.current.userInterfaceIdiom == .phone ? 50 : 80)
                        .foregroundStyle(.white)
                        .background(store.buttonConfig.buttonColor)
                        .cornerRadius(UIDevice.current.userInterfaceIdiom == .phone ? 24 : 48)
                }
                .buttonStyle(ShrinkButtonStyle())
            }
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
