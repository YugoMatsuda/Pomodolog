import SwiftUI
import ComposableArchitecture
import CoreData

struct LongPressBackgroundButtonView: View {
    @State private var isHoldingClearButton = false
    @State private var longPressProgress: Double = 0
    @State private var longPressCount: CGFloat = 0
    @State private var timer: Timer?
    
    let longPressAction: () -> Void

    var body: some View {
        
        ZStack {
            VStack {
                Spacer()
                ProgressView(value: longPressProgress, total: 1)
                    .frame(width: 200, height: 10)
                    .padding(.horizontal, 60)
                    .opacity(isHoldingClearButton ? 1 : 0)
                
                Text("Long press to finish session")
                    .foregroundStyle(.white)
                    .font(.body)
                    .fontWeight(.regular)
                    .scaleEffect(isHoldingClearButton ? 1.0 : 1.2)
                    .opacity(isHoldingClearButton ? 1 : 0.5)
           
            }
            .padding(.bottom, 60)

            
            Color.clear.contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onLongPressGesture(minimumDuration: TimerConst.duration, perform: {
                    longPressAction()
                }, onPressingChanged: { isHolding in
                    withAnimation {
                        self.isHoldingClearButton = isHolding
                        if !isHolding {
                            self.longPressCount = 0
                            self.longPressProgress = 0
                        }
                    }
                    startTimer()
                })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func startTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            guard self.isHoldingClearButton else {
                self.timer?.invalidate()
                return
            }
            Task { @MainActor in
                withAnimation {
                    self.longPressCount += 0.01
                    self.longPressProgress = max(min(longPressCount / TimerConst.duration, 1), 0)
                }
            }
        }
    }
}
extension LongPressBackgroundButtonView {
    enum TimerConst {
        static let duration: TimeInterval = 2.0
    }
}
