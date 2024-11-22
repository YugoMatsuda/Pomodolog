import Foundation

final class AppLogger: @unchecked Sendable  {
    /// shared はシングルトンオブジェクトを表す
    static let shared = AppLogger([
        AppLogConsoleDestination(.debug),
//        AppLogCrashlyticsRecordDestination(.warn),
//        AppLogCrashlyticsLogDestination(.crit)
    ])

    private let logDestinations: [AppLogDestination]
    private init(_ logDestinations: [AppLogDestination]) {
        self.logDestinations = logDestinations
    }

    /// log はロギングを行う
    func log(
        _ message: String,
        _ level: LogLevel,
        filePath: String = #file,
        line: Int = #line,
        column: Int = #column,
        funcName: String = #function
    ) {
        for dst in logDestinations {
            dst.log(
                message: message,
                level: level,
                filePath: filePath,
                line: line,
                column: column,
                funcName: funcName
            )
        }
    }
}
