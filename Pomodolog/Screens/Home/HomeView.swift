import ComposableArchitecture
import SwiftUI
import AsyncAlgorithms
import AVFoundation

@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSetting: TimerSetting
        @Presents var destination: Destination.State?
        var timerRingParam: TimerRingView.TimerRingParam
        var isOnBackGroundMusicSound: Bool
        var isOnAIVoiceSound: Bool
        var speachContent: SpeachContent.State?
        var avAudioPlayer: AVAudioPlayer? = nil
        
        var ongoingSession: PomodoroSession?
        
        init(
            timerSetting: Shared<TimerSetting>,
            isOnBackGroundMusicSound: Bool,
            isOnAIVoiceSound: Bool
        ) {
            self._timerSetting = timerSetting
            self.timerRingParam = .makeIdle(timerSetting.wrappedValue)
            self.isOnBackGroundMusicSound = isOnBackGroundMusicSound
            self.isOnAIVoiceSound = isOnAIVoiceSound
            self.speachContent = nil
        }
        
        var elapsedTime: TimeInterval {
            guard let ongoingSession = ongoingSession else {
                return 0
            }
            return Date.now.timeIntervalSince(ongoingSession.startAt)
        }
        
        var hasFinishedSessionTime: Bool {
            guard let ongoingSession = ongoingSession
            else {
                return true
            }
                let remainingTime: TimeInterval = {
                    switch ongoingSession.sessionType {
                    case .work:
                        return timerSetting.sessionTimeInterval - elapsedTime
                    case .break:
                        return timerSetting.shortBreakTimeInterval - elapsedTime
                    }
                }()
            return remainingTime < 0
        }
        
        var shouldShowLongPressBachgound: Bool {
            !hasFinishedSessionTime && timerState.isWorkSession
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
        
        var currentTagColor: Color {
            Color(hex: timerSetting.currentTag?.colorHex ?? "") ?? .blue
        }
        
        var actionButtonConfig: ActionButtonConfig? {
            guard let ongoingSession = ongoingSession else {
                return .init(title: "Start", buttonColor: Color(hex: timerSetting.currentTag?.colorHex ?? "") ?? .blue)
            }

            let color = Color(hex: ongoingSession.tag?.colorHex ?? "") ?? .blue
            switch ongoingSession.sessionType {
            case .work:
                guard hasFinishedSessionTime else { return nil }
                return ActionButtonConfig.init(title: "Break", buttonColor: color)
            case .break:
                return ActionButtonConfig.init(title: "Stop Break", buttonColor: color)
            }
        }
        
        struct ObserveResponse: Equatable {
            let ongoingSession: PomodoroSession?
            let timerSetting: TimerSetting
        }
        
        struct ActionButtonConfig: Equatable {
            let title: String
            let buttonColor: Color
        }
    }
    
    enum CancelID { case timer }

    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)
        case destination(PresentationAction<Destination.Action>)
        case speachContent(SpeachContent.Action)

        enum ViewAction {
            case onLoad
            case didTapActionButton
            case didLongPressActionButton
            case didTapTimerRing
            case didTapBGMSoundButton
            case didTapAIVoiceSoundButton
        }
        
        enum InternalAction {
            case observeResponse(TaskResult<State.ObserveResponse>)
            case passedTime(PomodoroSession)
            case didRecieveGeneratedWord(String)
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient
    @Dependency(\.speechSynthesizerClient) var speechSynthesizerClient
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.continuousClock) var clock
    @Dependency(\.userDefaults) var userDefaults

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
            case .view(.didLongPressActionButton):
                return .run(priority: .high) { [state] send in
                    guard var ongoingSession = state.ongoingSession else {
                        return
                    }
                    // 30秒以下の場合は記録しない
                    if state.elapsedTime <= 30 {
                        try await coreDataClient.deleteById(PomodoroSession.self, id: ongoingSession.id)
                    } else {
                        ongoingSession.endAt = .now
                        try await coreDataClient.insert(ongoingSession)
                    }
                }
            case .view(.didTapTimerRing):
                state.destination = .timerSettingView(
                    TimerSettingReducer.State.init(
                        timerSetting: state.$timerSetting
                    )
                )
                return .none
            case .view(.didTapBGMSoundButton):
                state.isOnBackGroundMusicSound.toggle()
                if state.isOnBackGroundMusicSound {
                    state.avAudioPlayer?.play()
                } else {
                    state.avAudioPlayer?.stop()
                }
                return .run { [state] _ in
                    await userDefaults.setIsOnBackGroundMusicSound(state.isOnBackGroundMusicSound)
                }
            case .view(.didTapAIVoiceSoundButton):
                state.isOnAIVoiceSound.toggle()
                if state.isOnAIVoiceSound, case .success(let param) = state.speachContent?.displayResult {
                    speechSynthesizerClient.startSpeaking(.init(text: param.text))
                } else {
                    speechSynthesizerClient.stopSpeaking()
                }
                return .run { [state] _ in
                    await userDefaults.setIsOnAIVoiceSound(state.isOnAIVoiceSound)
                }
            case .internal(.observeResponse(.success(let response))):
                Task.cancel(id: CancelID.timer)
                
                let shouldFetchPraiseWord: Bool = {
                    // 休憩に変化したケース
                    let didChangedToBreak = state.ongoingSession?.sessionType == .work && response.ongoingSession?.sessionType == .break
                    // 別端末で休憩セッション中だったケース
                    let inBreakSession = state.ongoingSession == nil && response.ongoingSession?.sessionType == .break
                    return didChangedToBreak || inBreakSession
                }()
                
                AppLogger.shared.log("shouldFetchPraiseWord: \(shouldFetchPraiseWord)", .debug)
                if shouldFetchPraiseWord {
                    state.speachContent = .init(displayResult: .loading)
                }
                
                state.ongoingSession = response.ongoingSession
                state.timerSetting = response.timerSetting
                
                guard let ongoingSession = response.ongoingSession else {
                    state.timerRingParam = .makeIdle(state.timerSetting)
                    state.speachContent = nil
                    state.avAudioPlayer?.stop()
                    state.avAudioPlayer = nil
                    speechSynthesizerClient.stopSpeaking()
                    return .cancel(id: CancelID.timer)
                }

                state.timerRingParam = makeTimerConfig(ongoingSession, state: state)
                state.avAudioPlayer = makePlayer(ongoingSession, state: state)
                if state.isOnBackGroundMusicSound {
                    state.avAudioPlayer?.play()
                }
                
                return .merge(
                    .run { send in
                        for await _ in self.mainQueue.timer(interval: .seconds(0.1)) {
                            await send(
                                .internal(.passedTime(ongoingSession)),
                                animation: .default
                            )
                        }
                    }.cancellable(id: CancelID.timer),
                    .run { send in
                        guard shouldFetchPraiseWord else { return }
                        try await self.clock.sleep(for: .seconds(1))
                        await send(
                            .internal(.didRecieveGeneratedWord(Const.praiseWord)), animation: .default)
                    }
                )
            case let .internal(.passedTime(ongoingSession)):
                state.timerRingParam = makeTimerConfig(ongoingSession, state: state)
                return .none
            case .internal(.didRecieveGeneratedWord(let word)):
                AppLogger.shared.log("didRecieveGeneratedWord: \(word)", .debug)
                state.speachContent = .init(
                    displayResult: .success(
                        .init(
                            text: word,
                            color: Color(hex: state.timerSetting.currentTag?.colorHex ?? "") ?? .blue
                        )
                    )
                )
                guard state.isOnAIVoiceSound else { return .none }
                speechSynthesizerClient.startSpeaking(.init(text: word))
                return .none
            case .speachContent:
                return .none
            case .internal:
                return .none
            case .destination:
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.speachContent, action: \.speachContent) {
            SpeachContent()
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
    ) -> TimerRingView.TimerRingParam {
        let timerSetting = state.timerSetting
        let isCountUp = timerSetting.timerType == .countup
        let elapsedTime = state.elapsedTime
        let tag = timerSetting.currentTag ?? .focus()

        switch ongoingSession.sessionType {
        case .work:
            if isCountUp {
                // カウントアップの場合
                let timerInterval = elapsedTime
                let progress = min(timerInterval / timerSetting.sessionTimeInterval, 1)
                
                return .workSession(
                    .init(
                        timerInterval: timerInterval,
                        progress: CGFloat(progress),
                        hasFinishedCountDown: state.hasFinishedSessionTime,
                        currentTag: tag
                    )
                )
            } else {
                // カウントダウンの場合
                let remainingTime = timerSetting.sessionTimeInterval - elapsedTime
                if state.hasFinishedSessionTime {
                    // カウントダウンが終了した場合、カウントアップに切り替える
                    let newTimerInterval = abs(remainingTime)
                    return .workSession(
                        .init(
                            timerInterval: newTimerInterval,
                            progress: 0,
                            hasFinishedCountDown: true,
                            currentTag: tag
                        )
                    )
                } else {
                    // カウントダウン中
                    let progress = max(remainingTime / timerSetting.sessionTimeInterval, 0)
                    return .workSession(
                        .init(
                            timerInterval: remainingTime,
                            progress: progress,
                            hasFinishedCountDown: false,
                            currentTag: tag
                        )
                    )
                }
            }
        case .break:
            // 休憩時は常にカウントダウン
            let remainingTime = timerSetting.shortBreakTimeInterval - elapsedTime
            if remainingTime < 0 {
                // カウントダウンが終了した場合、カウントアップに切り替える
                let newTimerInterval = abs(remainingTime)
                return .breakSession(
                    .init(
                        timerInterval: newTimerInterval,
                        hasFinishedCountDown: true,
                        currentTag: tag
                    )
                )
            } else {
                return .breakSession(
                    .init(
                        timerInterval: remainingTime,
                        hasFinishedCountDown: false,
                        currentTag: tag
                    )
                )
            }
        }
    }
    
    private func makePlayer(
        _ ongoingSession: PomodoroSession,
        state: State
    ) -> AVAudioPlayer? {
        guard case .work = state.timerState,
              let url = state.timerSetting.backgroundMusicType.fileURL
        else {
            return nil
        }
        do {
            let player =  try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            AppLogger.shared.log("Failed to make player", .crit)
            return nil
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

extension Home {
    @Reducer(state: .equatable)
    enum Destination {
        case timerSettingView(TimerSettingReducer)
    }
    
    enum Const {
        static let praiseWord = "I'd almost want to crown you with the title of Pomodoro Master!"
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<Home>
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let timerSize = min(420, proxy.size.width * 0.6)
                let buttonSize = min(300, proxy.size.width * 0.35)
                ZStack{
                    AuroraView(color: store.currentTagColor)
                        .opacity(store.timerState.isWorkSession ? 1 : 0)
                    VStack {
                        spacer
                        Button(action: {
                            store.send(.view(.didTapTimerRing))
                        }) {
                            TimerRingView(param: store.timerRingParam, circleSize: timerSize)
                        }
                        .buttonStyle(ShrinkButtonStyle())
                        .disabled(store.timerState.isOngoingSession)
                        .sheet(
                            item: $store.scope(
                                state: \.destination?.timerSettingView,
                                action: \.destination.timerSettingView
                            )
                        ) { store in
                            TimerSettingView(store: store)
                        }
                        
                        if let store = self.store.scope(state: \.speachContent, action: \.speachContent) {
                            SpeachContentView(store: store)
                        }
                        
                        button(size: buttonSize)
                        
                        Spacer()
                    }
                    
                    if store.shouldShowLongPressBachgound {
                        LongPressBackgroundButtonView(color: store.currentTagColor, longPressAction: {
                            store.send(.view(.didLongPressActionButton))
                        })
                    }
                }
                .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        toolBarTitle
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        toolBarTrailingButton
                    }
                }
            }
            .onLoad {
                store.send(.view(.onLoad))
            }
        }

    }
    
    @ViewBuilder
    private var toolBarTitle: some View {
        Group {
            switch store.timerState {
            case .initial:
                EmptyView()
            case .work:
                Text(store.timerSetting.currentTag?.name ?? "")
                    .foregroundStyle(.white)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            case .workBreak:
                Text("Break")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private var toolBarTrailingButton: some View {
        Group {
            switch store.timerState {
            case .initial:
                EmptyView()
            case .work:
                let imageName = store.isOnBackGroundMusicSound ? "waveform" : "waveform.slash"
                Button("", systemImage: imageName) {
                    store.send(.view(.didTapBGMSoundButton))
                }
                .foregroundStyle(.white)
                .buttonStyle(.plain)
            case .workBreak:
                let imageName = store.isOnAIVoiceSound ? "speaker.wave.2.fill" : "speaker.slash.fill"
                Button("", systemImage: imageName) {
                    store.send(.view(.didTapAIVoiceSoundButton))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private  var spacer: some View {
        switch store.timerState {
        case .initial:
            Spacer()
        case .work:
            Spacer()

        case .workBreak:
            Spacer().frame(height: 12)
        }
    }
    
    @ViewBuilder
    private func button(size: CGFloat) -> some View {
        if let config = store.actionButtonConfig {
            VStack {
                Spacer().frame(height: UIDevice.current.userInterfaceIdiom == .phone ? 40 : 60)
                Button {
                    store.send(.view(.didTapActionButton))
                } label: {
                    Text(config.title)
                        .font(
                            .system(
                                size: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40,
                                weight: .regular
                            )
                        )
                        .frame(width: size, height: UIDevice.current.userInterfaceIdiom == .phone ? 40 : 70)
                        .foregroundStyle(.white)
                        .background(config.buttonColor)
                        .cornerRadius(UIDevice.current.userInterfaceIdiom == .phone ? 24 : 48)
                }
                .buttonStyle(ShrinkButtonStyle())
            }
        }
    }
}

#Preview {
    HomeView(store: .init(initialState: Home.State.init(
        timerSetting: Shared(TimerSetting.initial()),
        isOnBackGroundMusicSound: false,
        isOnAIVoiceSound: false
    ), reducer: {
        Home()
    }))
}
