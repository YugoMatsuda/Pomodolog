import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct SpeachContent {
    @ObservableState
    struct State: Equatable {
        var displayResult: DisplayResult
        
        init(displayResult: DisplayResult) {
            self.displayResult = displayResult
        }
        
        enum DisplayResult: Equatable {
            case success(SpeachContentParam)
            case failure
            case loading
        }
        
        struct SpeachContentParam: Equatable {
            let text: String
            let color: Color
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
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.onLoad):
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
}

struct SpeachContentView: View {
    @Bindable var store: StoreOf<SpeachContent>

    var body: some View {
        Group {
            switch store.displayResult {
            case .success(let param):
                VStack {
                    Text(param.text)
                        .foregroundStyle(LinearGradient(
                            colors: [.red, .blue, .green, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .font(
                            .system(
                                size: UIDevice.current.userInterfaceIdiom == .phone ? 25 : 50,
                                weight: .regular
                            )
                        )
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.5), value: store.displayResult)
                        .contentTransition(.opacity)
                }
                .padding()
            case .failure:
                Text("Failed to genrerate words.")
                    .padding()
            case .loading:
                ProgressView()
                    .padding()
            }
        }

    }
}

#Preview {
    SpeachContentView(store: .init(initialState: SpeachContent.State.init(displayResult: .loading), reducer: {
        SpeachContent()
    }))
}
