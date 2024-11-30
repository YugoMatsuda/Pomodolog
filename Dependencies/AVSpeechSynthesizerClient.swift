import Dependencies
import AVFoundation

struct AVSpeechSynthesizerClient: Sendable {
    var startSpeaking:@Sendable (_ param: SpeachParam) ->  Void
    var stopSpeaking: @Sendable () ->  Void
}
extension AVSpeechSynthesizerClient: DependencyKey {
    static var liveValue: AVSpeechSynthesizerClient {
        live()
    }
    
    static func live() -> AVSpeechSynthesizerClient {
        let synthesizer = AVSpeechSynthesizer()
        return Self(
            startSpeaking: { param in
                let speechUtterance = AVSpeechUtterance(string: param.text)
                speechUtterance.rate = 0.5
                synthesizer.speak(speechUtterance)
            },
            stopSpeaking: {
                synthesizer.stopSpeaking(at: .immediate)
            }
        )
    }
}

extension DependencyValues {
    var speechSynthesizerClient: AVSpeechSynthesizerClient {
        get { self[AVSpeechSynthesizerClient.self] }
        set { self[AVSpeechSynthesizerClient.self] = newValue }
    }
}


extension AVSpeechSynthesizer: @unchecked @retroactive Sendable {}

struct SpeachParam: Equatable {
    let text: String
}
