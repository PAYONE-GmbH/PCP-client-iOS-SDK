//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

import Foundation
import OSLog

enum PCPLogger {
    private static let logger: Logger = Self.createApplicationLogger()

    static func info(_ message: String) {
        logUnified(message: message, on: .info)
    }

    static func error(_ message: String) {
        logUnified(message: message, on: .error)
    }

    static func fault(_ message: String) {
        logUnified(message: message, on: .fault)
    }

    private static func logUnified(message: String, on level: OSLogType) {
        let logLevelPrefix = buildLogLevelPrefix(from: level)

        logger.log(level: level, "\(logLevelPrefix) \(message)")
    }

    private static func buildLogLevelPrefix(from level: OSLogType) -> String {
        switch level {
        case .debug: return "[🛠️]"
        case .info: return "[ℹ️]"
        case .default: return "[⚠️]"
        case .error: return "[🛑]"
        case .fault: return "[💥]"
        default: return "[Default]"
        }
    }

    private static func createApplicationLogger() -> Logger {
        Logger(
            subsystem: "PCPClient",
            category: "PCP"
        )
    }
}
