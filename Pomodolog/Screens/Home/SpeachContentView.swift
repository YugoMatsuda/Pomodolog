import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct SpeachContent {
    @ObservableState
    struct State: Equatable {
        var displayResult: DisplayResult
        var feedBackType: FeedBackType? = nil
        
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
        
        enum FeedBackType: Equatable {
            case good
            case bad
        }
    }
    
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        enum ViewAction: Equatable {
            case onLoad
            case didTapGoodButton
            case didTapBadButton
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
            case .view(.didTapGoodButton):
                if state.feedBackType == .good {
                    state.feedBackType = nil
                } else {
                    state.feedBackType = .good
                }
                return .none
            case .view(.didTapBadButton):
                if state.feedBackType == .bad {
                    state.feedBackType = nil
                } else {
                    state.feedBackType = .bad
                }
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

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
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
                                size: isPhone ? 25 : 50,
                                weight: .regular
                            )
                        )
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.5), value: store.displayResult)
                        .contentTransition(.opacity)
                        .padding()
                    
                    HStack {
                        let size: CGFloat = isPhone ? 40 : 80
                        Spacer()
                        Button {
                            store.send(.view(.didTapGoodButton))
                        } label: {
                            let imageName = store.feedBackType == .good ? "hand.thumbsup.circle.fill" : "hand.thumbsup.circle"
                            Image(systemName: imageName)
                                .resizable()
                                .foregroundStyle(param.color)
                                .frame(width: size, height: size)
                        }
                        .buttonStyle(.plain)

                        Spacer().frame(width: 32)
    
                        Button {
                            store.send(.view(.didTapBadButton))
                        } label: {
                            let imageName = store.feedBackType == .bad ? "hand.thumbsdown.circle.fill" : "hand.thumbsdown.circle"
                            Image(systemName: imageName)
                                .resizable()
                                .foregroundStyle(param.color)
                                .frame(width: size, height: size)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    
                    Text("If you like our words, press the Good button; if not, press the Bad button. The AI will learn and use it to generate words for next time.")
                        .font(
                            .system(
                                size: isPhone ? 12 : 25,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                        .padding(.top)
                }
                .padding()
            case .failure:
                Text("Failed to genrerate words.")
                    .padding()
            case .loading:
                let size: CGFloat = isPhone ? 40 : 80
                ProgressView()
                    .frame(width: size, height: size)
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
