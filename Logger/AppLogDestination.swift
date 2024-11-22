import Foundation

protocol AppLogDestination {
    var ignoreUnderThisLevel: LogLevel { get }

    func log(
        time: String,
        message: String,
        level: LogLevel,
        fileName: String,
        line: Int,
        column: Int,
        funcName: String
    )
}

extension AppLogDestination {
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }

    func log(
        message: String,
        level: LogLevel,
        filePath: String,
        line: Int,
        column: Int,
        funcName: String
    ) {
        if level.rawValue >= ignoreUnderThisLevel.rawValue {
            log(time: dateFormatter.string(from: Date()),
                message: message,
                level: level,
                fileName: Self.sourceFileName(filePath: filePath),
                line: line,
                column: column,
                funcName: funcName
            )
        }
    }

    static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}
