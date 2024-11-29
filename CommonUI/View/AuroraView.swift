import SwiftUI
import Combine

struct AuroraView: View {
    
    private enum AnimationProperties {
        static let animationSpeed: Double = 4
        static let timerDuration: TimeInterval = 3
        static let blurRadius: CGFloat = 130
    }
    
    // 親から渡される color を通常のプロパティとして定義
    let color: Color
    
    // CircleAnimator を @State で管理
    @State private var animator: CircleAnimator
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    // カスタムイニシャライザで animator と timer を初期化
    init(color: Color) {
        self.color = color
        self._animator = State(initialValue: CircleAnimator(color: color))
        self._timer = State(initialValue: Timer.publish(every: AnimationProperties.timerDuration, on: .main, in: .common).autoconnect())
    }
    
    var body: some View {
        ZStack {
            ZStack {
                ForEach(animator.circles) { circle in
                    MovingCircle(originOffset: circle.position)
                        .foregroundColor(circle.color)
                }
            }
            .blur(radius: AnimationProperties.blurRadius)
        }
        .background(Color.black)
        .onAppear {
            animateCircles()
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
        .onReceive(timer) { _ in
            animateCircles()
        }
        // 親から渡された color の変更を監視
        .onChange(of: color) { _, newColor in
            animator.updateCirclesColor(newColor)
        }
    }
    
    private func animateCircles() {
        withAnimation(.easeInOut(duration: AnimationProperties.animationSpeed)) {
            animator.animate()
        }
    }
}

private struct MovingCircle: Shape {
    
    var originOffset: CGPoint
    
    var animatableData: CGPoint.AnimatableData {
        get {
            originOffset.animatableData
        }
        set {
            originOffset.animatableData = newValue
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let adjustedX = rect.width * originOffset.x
        let adjustedY = rect.height * originOffset.y
        let smallestDimension = min(rect.width, rect.height)
        path.addArc(center: CGPoint(x: adjustedX, y: adjustedY), radius: smallestDimension / 2, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        return path
    }
}

private class CircleAnimator: ObservableObject {
    class Circle: Identifiable {
        init(position: CGPoint, color: Color) {
            self.position = position
            self.color = color
        }
        var position: CGPoint
        let id = UUID().uuidString
        let color: Color
    }
    
    @Published private(set) var circles: [Circle] = []
    private(set) var color: Color
    
    var colors: [Color] {
        return [
            color,
            color.opacity(0.6),
            color.opacity(0.3),
        ]
    }
    
    init(color: Color) {
        self.color = color
        self.circles = colors.map { color in
            Circle(position: CircleAnimator.generateRandomPosition(), color: color)
        }
    }
    
    // 円の色のみを更新
    func updateCirclesColor(_ newColor: Color) {
        self.color = newColor
        let newColors = [
            newColor,
            newColor.opacity(0.6),
            newColor.opacity(0.3),
        ]
        for (index, circle) in circles.enumerated() {
            if index < newColors.count {
                circles[index] = Circle(position: circle.position, color: newColors[index])
            }
        }
    }
    
    // 円のポジションを更新
    func animate() {
        for index in circles.indices {
            circles[index].position = CircleAnimator.generateRandomPosition()
        }
    }
    
    static func generateRandomPosition() -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0 ... 1), y: CGFloat.random(in: 0 ... 1))
    }
}
