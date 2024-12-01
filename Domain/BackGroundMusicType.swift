import Foundation

enum BackGroundMusicType: String, CaseIterable {
    case random
    case bird
    case clock
    case insect
    case openFire
    case rain
    case river
    case wave
    
    var fileURL: URL? {
        if self == .random {
            return BackGroundMusicType.allCases
                .filter { $0 != .random }
                .randomElement()?
                .fileURL
        }
        return Bundle.main.url(forResource: self.rawValue, withExtension: "mp3")
    }
    
    var title: String {
        switch self {
        case .random:
            return "Random"
        case .bird:
            return "Bird"
        case .clock:
            return "Clock"
        case .insect:
            return "Insect"
        case .openFire:
            return "Open Fire"
        case .rain:
            return "Rain"
        case .river:
            return "River"
        case .wave:
            return "Wave"
        }
    }
}
