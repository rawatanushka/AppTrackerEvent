//
//  Formatters.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import Foundation

/// Shared date and number formatters used throughout the app.
///
/// Declared as static lazy constants so each formatter is created only once.
enum Formatters {
    /// 10:29:41 AM — matches the timestamp style in the design.
    static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm:ss a"
        return formatter
    }()

    /// Formats a percentage value with exactly two decimal places.
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formats an integer with locale-aware grouping separators.
    static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    /// Converts a percentage `Double` to a display string such as `"42.50%"`.
    ///
    /// - Parameter value: The percentage value (0–100).
    /// - Returns: A formatted string with a trailing `%` sign.
    static func percentString(_ value: Double) -> String {
        (percentage.string(from: NSNumber(value: value)) ?? "0.00") + "%"
    }

    /// Converts an `Int` count to a locale-formatted string.
    ///
    /// - Parameter value: The integer value to format.
    /// - Returns: A formatted string (e.g. `"1,234"`).
    static func countString(_ value: Int) -> String {
        integer.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
