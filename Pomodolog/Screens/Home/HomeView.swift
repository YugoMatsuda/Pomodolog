import ComposableArchitecture
import SwiftUI
import AsyncAlgorithms

@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSetting: TimerSetting
        var ongoingSession: PomodoroSession?
        var currentTime: Date = .now
        
        var timerState: TimerState {
            guard let ongoingSession = ongoingSession else { return .initial }
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
        }
        
        struct ObserveResponse: Equatable {
            let ongoingSession: PomodoroSession?
            let timerSetting: TimerSetting
        }
    }
    
    enum CancelID { case timer }

    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        enum ViewAction {
            case onLoad
        }
        
        enum InternalAction {
            case observeResponse(TaskResult<State.ObserveResponse>)
            case passedTime
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient

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
            case .internal(.observeResponse(.success(let response))):
                state.ongoingSession = response.ongoingSession
                state.timerSetting = response.timerSetting
                if state.ongoingSession != nil {
                    return .run { send in
                        await send(
                            .internal(.passedTime),
                            animation: .default
                        )
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    return .cancel(id: CancelID.timer)
                }
            case .internal(.passedTime):
                state.currentTime = .now
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
}

struct HomeView: View {
    @Bindable var store: StoreOf<Home>

    var body: some View {
        ZStack{
            switch store.timerState {
            case .initial:
                TimerRingView()
            case .work:
                AuroraView()
                TimerRingView()
            case .workBreak:
                TimerRingView()
            }
        }
        .onLoad {
            store.send(.view(.onLoad))
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
