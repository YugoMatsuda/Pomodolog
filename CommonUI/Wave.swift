import SwiftUI

struct Wave: Shape {
    var offset: Angle
    var percent: Double
    
    var minPercent: Double {
        min(percent, 0.8)
    }

    var animatableData: AnimatablePair<Double, Double> {
         get { AnimatablePair(offset.degrees, minPercent) }
         set {
             offset = Angle(degrees: newValue.first)
             percent = newValue.second
         }
     }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHightRatio: Double = {
            switch percent {
            case 1...Double.infinity:
                return 0.045
            case 0.8...1:
                return 0.035
            default:
                return 0.025
            }
        }()
                
        let waveHeight = waveHightRatio * rect.height
        let yOffset = CGFloat(1 - minPercent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360)

        path.move(to: CGPoint(x: 0, y: yOffset + waveHeight * CGFloat(sin(offset.radians))))

        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 10) {
            let x = CGFloat(angle - startAngle.degrees) / 360 * rect.width
            let y = yOffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}
