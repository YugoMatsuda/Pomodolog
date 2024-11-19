import Foundation

extension TimeInterval {
    func toLocalizedString(unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = unitsStyle
        formatter.zeroFormattingBehavior = .dropAll
        
        return formatter.string(from: self)
    }
}
