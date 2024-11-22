import Foundation

enum LogLevel: Int {
    case debug
    case info
    case warn
    case crit

    var string: String {
        let head = "😃"
        let last: String
        switch self {
        case .debug:
            last = "[💬]"
        case .info:
            last = "[ℹ️]"
        case .warn:
            last = "[⚠️]"
        case .crit:
            last = "[🔥]"
        }
        return head + " " + last
    }
}
