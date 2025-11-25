//
//  DateFormatters.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Japanese Date Formatting Utilities
//

import Foundation

extension DateFormatter {
    /// Japanese Era (令和) formatter with date and time
    /// Format: "令和7年 11月26日 17:48"
    static let japaneseEraDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "Gyy年 MM月dd日 HH:mm"
        return formatter
    }()

    /// Japanese Era (令和) formatter with date only
    /// Format: "令和7年 11月26日"
    static let japaneseEraDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "Gyy年 MM月dd日"
        return formatter
    }()

    /// Japanese Era (令和) formatter for year and month
    /// Format: "令和7年 11月"
    static let japaneseEraYearMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "Gyy年 MM月"
        return formatter
    }()
}

extension Date {
    /// Format date as Japanese Era with date and time
    /// Example: "令和7年 11月26日 17:48"
    var japaneseEraDateTimeString: String {
        DateFormatter.japaneseEraDateTime.string(from: self)
    }

    /// Format date as Japanese Era with date only
    /// Example: "令和7年 11月26日"
    var japaneseEraDateString: String {
        DateFormatter.japaneseEraDate.string(from: self)
    }

    /// Format date as Japanese Era with year and month
    /// Example: "令和7年 11月"
    var japaneseEraYearMonthString: String {
        DateFormatter.japaneseEraYearMonth.string(from: self)
    }
}
