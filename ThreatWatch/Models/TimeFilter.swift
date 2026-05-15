//
//  TimeFilter.swift
//  ThreatWatch
//

import Foundation

enum TimeFilter: String, CaseIterable, Identifiable {
    case all         = "全部"
    case today       = "今天"
    case week        = "一週內"
    case month       = "一個月內"
    case threeMonths = "三個月"

    var id: String { rawValue }

    var cutoffDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .all:         return nil
        case .today:       return cal.startOfDay(for: now)
        case .week:        return cal.date(byAdding: .weekOfYear, value: -1, to: now)
        case .month:       return cal.date(byAdding: .month,      value: -1, to: now)
        case .threeMonths: return cal.date(byAdding: .month,      value: -3, to: now)
        }
    }
}
