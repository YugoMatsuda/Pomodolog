import ComposableArchitecture
import SwiftUI

@Reducer
struct RootPage {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSettnig: TimerSetting
        var selectionPage: SelectionPage? = .home
        var home: Home.State
        var hilight: Hilight.State

        var isOngoingSession: Bool {
            home.timerState.isOngoingSession
        }
        
        init(
            timerSettnig: Shared<TimerSetting>,
            isOnBackGroundMusicSound: Bool,
            isOnAIVoiceSound: Bool
        ) {
            self._timerSettnig = timerSettnig
            self.home = .init(
                timerSetting: timerSettnig,
                isOnBackGroundMusicSound: isOnBackGroundMusicSound,
                isOnAIVoiceSound: isOnAIVoiceSound
            )
            self.hilight = .init()
        }
        
        enum SelectionPage: Int, Equatable,Hashable, CaseIterable {
            case setting
            case home
            case hilight
        }
    }

    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case home(Home.Action)
        case hilight(Hilight.Action)

        enum ViewAction {
            case onAppear
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            Home()
        }
        Scope(state: \.hilight, action: \.hilight) {
            Hilight()
        }
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .binding:
                return .none
            case .home:
                return .none
            case .hilight:
                return .none
            }
        }
    }
}

struct RootPageView: View {
    @Bindable var store: StoreOf<RootPage>
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(RootPage.State.SelectionPage.allCases, id: \.self) { page in
                        switch page {
                        case .setting:
                            SettingView()
                                .id(page)
                        case .home:
                            HomeView(
                                store: store.scope(state: \.home, action: \.home)
                            )
                            .id(page)
                        case .hilight:
                            HilightView(
                                store: store.scope(state: \.hilight, action: \.hilight)
                            )
                                .id(page)
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $store.selectionPage)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never)
            .defaultScrollAnchor(.center)
            .scrollDisabled(store.isOngoingSession)
            .onChange(of: store.isOngoingSession) { _, newValue in
                guard newValue else { return }
                scrollProxy.scrollTo(RootPage.State.SelectionPage.home, anchor: .center)
            }
        }
    }
}

#Preview {
    RootPageView(
        store: .init(
            initialState: RootPage.State(
                timerSettnig: Shared<TimerSetting>.init(.initial()),
                isOnBackGroundMusicSound: true,
                isOnAIVoiceSound: true
            ),
            reducer: {
                RootPage()
            })
    )
}
