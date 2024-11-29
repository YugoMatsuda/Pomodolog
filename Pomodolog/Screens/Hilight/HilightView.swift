import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct Hilight {
    @ObservableState
    struct State: Equatable {
        var displayResult: DisplayResult = .loading
        
        enum DisplayResult: Equatable {
            case success([PomodoroSession])
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
            case observeResponse(TaskResult<[PomodoroSession]>)
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
                AppLogger.shared.log("observeResponse error:\(error)", .crit)
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
    
    private func fetchEntity() async throws -> [PomodoroSession] {
        try await coreDataClient.fetchAll(
            PomodoroSession.self,
            sortDescriptors: [SortDescriptorData(key: "createAt", ascending: false)]
        )
    }
}

struct HilightView: View {
    @Bindable var store: StoreOf<Hilight>

    var body: some View {
        NavigationStack {
            Group {
                switch store.displayResult {
                case .success(let sessions):
                    List {
                        ForEach(sessions) { session in
                            VStack {
                                HStack {
                                    Text("\(session.sessionType)")
                                    Text("\(session.tag?.name ?? "")")
                                }
                                Text(session.duration.toLocalizedString())
                                
                                Text(session.createAt.formatted(.dateTime.year().month().day().hour().minute()))
                            }
                        }
                    }
                case .failure:
                    Text("Failed to load")
                case .loading:
                    ProgressView()
                }
            }
            .navigationTitle("Hilight")
            .navigationBarTitleDisplayMode(.inline)
            .onLoad {
                store.send(.view(.onLoad))
            }
        }
    }
}

#Preview {
    HilightView(store: .init(initialState: Hilight.State.init(), reducer: {
        Hilight()
    }))
}
