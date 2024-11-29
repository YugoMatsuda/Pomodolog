import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct TimerSettingReducer {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSetting: TimerSetting
        var displayResult: DisplayResult = .loading
        
        enum DisplayResult: Equatable {
            case success([Tag])
            case failure
            case loading

        }
    }
    
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        enum ViewAction: Equatable {
            case onLoad
        }
        
        enum DelegateAction: Equatable {
        }
        
        enum InternalAction {
            case observeResponse(TaskResult<[Tag]>)
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.onLoad):
                return  .run { send in
                    let initialFetch = try await fetchEntity()
                    await send(.internal(.observeResponse(.success(initialFetch))), animation: .default)
                    let observeRemoteChange = coreDataClient.observeRemoteChange()
                    for try await _ in observeRemoteChange._throttle(for: .seconds(0.5), latest: true) {
                        AppLogger.shared.log("reload hilight", .debug)
                        let entity = try await fetchEntity()
                        await send(.internal(.observeResponse(.success(entity))), animation: .default)
                    }
                } catch: { error, send in
                    await send(.internal(.observeResponse(.failure(error))))
                }
            case let .internal(.observeResponse(.success(resp))):
                state.displayResult = .success(resp)
                return .none
            case let .internal(.observeResponse(.failure(error))):
                state.displayResult = .failure
                return .none
            case .internal:
                return .none
            case .binding:
                return .none
            case .delegate:
              return .none
            }
        }
    }
    
    private func fetchEntity() async throws -> [Tag] {
        try await coreDataClient.fetchAll(
            Tag.self,
            sortDescriptors: [SortDescriptorData(key: "createAt", ascending: false)]
        )
    }
}

struct TimerSettingView: View {
    @Bindable var store: StoreOf<TimerSettingReducer>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                
            }
            .navigationTitle("Timer Setting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onLoad {
                store.send(.view(.onLoad))
            }
        }
    }
}

#Preview {
    TimerSettingView(store: .init(initialState: TimerSettingReducer.State.init(
        timerSetting: Shared(TimerSetting.initial())
    ), reducer: {
        TimerSettingReducer()
    }))
}
