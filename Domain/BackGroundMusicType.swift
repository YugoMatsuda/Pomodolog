import Foundation

enum BackGroundMusicType: String, CaseIterable {
    case bird
    case clock
    case insect
    case openFire
    case rain
    case river
    case wave
    
    var fileUR: URL? {
        Bundle.main.url(forResource: self.rawValue, withExtension: "mp3")
    }
}
