//
//  Formatters.swift
//  Fer
//

import Foundation

enum Formatters {
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    static func weight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private static let lbPerKg = 2.20462

    /// Converts a canonical lb value to the display unit and formats it.
    static func weight(_ lbValue: Double, unit: UserProfile.WeightUnit) -> String {
        weight(displayValue(lbValue, unit: unit))
    };Z

    /// Converts a canonical lb value into the given display unit (no formatting).
    static func displayValue(_ lbValue: Double, unit: UserProfile.WeightUnit) -> Double {
        unit == .kg ? lbValue / lbPerKg : lbValue
    }

    /// Converts a value entered in the given display unit back to canonical lb for storage.
    static func toStorageWeight(_ input: Double, unit: UserProfile.WeightUnit) -> Double {
        unit == .kg ? input * lbPerKg : input
    }

    static let relativeDate: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortWeekdayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()
}
