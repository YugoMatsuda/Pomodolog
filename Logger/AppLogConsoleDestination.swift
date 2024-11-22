import Foundation

struct AppLogConsoleDestination: AppLogDestination {
    private let serialLogQueue: DispatchQueue = DispatchQueue(
        label: "yourapp.domain.AppLogConsoleDestination"
    )
    let ignoreUnderThisLevel: LogLevel

    init(_ ignoreUnderThisLevel: LogLevel) {
        self.ignoreUnderThisLevel = ignoreUnderThisLevel
    }

    func log(
        time: String,
        message: String,
        level: LogLevel,
        fileName: String,
        line: Int,
        column: Int,
        funcName: String
    ) {
        serialLogQueue.async {
            print(
                "\(time) \(level.string)[\(fileName)]:\(line) \(column) \(funcName) -> \(message)"
            )
        }
    }
}
