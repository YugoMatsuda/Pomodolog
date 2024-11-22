import Foundation

extension CDTimerSetting {
    var timerType: TimerSetting.TimerType {
        get {
            do {
                guard let data = timerTypeData else { return .initial() }
                let result = try JSONDecoder().decode(TimerSetting.TimerType.self, from: data)
                return result
            } catch {
                AppLogger.shared.log("Decoding failed with error: \(error)", .warn)
                return .initial()
            }
        }
        set {
            do {
                timerTypeData = try JSONEncoder().encode(newValue)
            } catch {
                AppLogger.shared.log("Encoding failed with error: \(error)", .warn)
            }
        }
    }
}
