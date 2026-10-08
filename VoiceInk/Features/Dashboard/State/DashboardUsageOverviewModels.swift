import Foundation
import SwiftUI

enum DashboardAppCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case aiPrompts
    case otherTasks
    case documents
    case personalMessages
    case emails
    case workMessages

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .aiPrompts: return "AI prompts"
        case .otherTasks: return "Other tasks"
        case .documents: return "Documents"
        case .personalMessages: return "Personal messages"
        case .emails: return "Emails"
        case .workMessages: return "Work messages"
        }
    }

    var systemImage: String {
        switch self {
        case .aiPrompts: return "cpu"
        case .otherTasks: return "infinity"
        case .documents: return "doc.text"
        case .personalMessages: return "bubble.left"
        case .emails: return "envelope"
        case .workMessages: return "text.bubble"
        }
    }

    static func category(forBundleIdentifier bundleIdentifier: String) -> DashboardAppCategory {
        categoriesByBundleIdentifier[bundleIdentifier.lowercased()] ?? .otherTasks
    }

    private static let workMessagingBundleIdentifiers: Set<String> = [
        "com.tinyspeck.slackmacgap",
        "com.microsoft.teams",
        "com.microsoft.teams2",
    ]

    // Reuses the Mode trigger catalog so app grouping stays in one place.
    private static let categoriesByBundleIdentifier: [String: DashboardAppCategory] = {
        var categories: [String: DashboardAppCategory] = [:]

        for template in TriggerTemplateCatalog.templates {
            for app in template.apps {
                let bundleIdentifier = app.bundleIdentifier.lowercased()
                let category: DashboardAppCategory
                switch template.id {
                case "ai":
                    category = .aiPrompts
                case "email":
                    category = .emails
                case "writing":
                    category = .documents
                case "chat":
                    category = workMessagingBundleIdentifiers.contains(bundleIdentifier)
                        ? .workMessages : .personalMessages
                default:
                    continue
                }
                categories[bundleIdentifier] = category
            }
        }

        for bundleIdentifier in workMessagingBundleIdentifiers {
            categories[bundleIdentifier] = .workMessages
        }

        return categories
    }()
}

struct DashboardAppCategoryUsage: Codable, Equatable, Identifiable, Sendable {
    var id: DashboardAppCategory { category }
    let category: DashboardAppCategory
    let sessionCount: Int
}

struct DashboardModeWordShare: Codable, Equatable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let words: Int
}

struct DashboardStreakSummary: Codable, Equatable, Sendable {
    var currentDays: Int = 0
    var longestDays: Int = 0
    var currentStreakStart: Date?
    var currentStreakEnd: Date?

    func isPartOfCurrentStreak(_ day: Date) -> Bool {
        guard let currentStreakStart, let currentStreakEnd else { return false }
        return day >= currentStreakStart && day <= currentStreakEnd
    }

    /// A streak stays alive through today until midnight, so yesterday's activity still counts.
    static func make(activeDays: Set<Date>, now: Date, calendar: Calendar) -> DashboardStreakSummary {
        guard !activeDays.isEmpty else { return DashboardStreakSummary() }

        var longest = 0
        var running = 0
        var previousDay: Date?
        for day in activeDays.sorted() {
            if let previousDay,
                let expected = calendar.date(byAdding: .day, value: 1, to: previousDay),
                calendar.isDate(day, inSameDayAs: expected)
            {
                running += 1
            } else {
                running = 1
            }
            longest = max(longest, running)
            previousDay = day
        }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let streakEnd: Date
        if activeDays.contains(today) {
            streakEnd = today
        } else if activeDays.contains(yesterday) {
            streakEnd = yesterday
        } else {
            return DashboardStreakSummary(currentDays: 0, longestDays: longest)
        }

        var current = 0
        var streakStart = streakEnd
        var cursor = streakEnd
        while activeDays.contains(cursor) {
            current += 1
            streakStart = cursor
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return DashboardStreakSummary(
            currentDays: current,
            longestDays: max(longest, current),
            currentStreakStart: streakStart,
            currentStreakEnd: streakEnd
        )
    }
}

struct DashboardUsageOverview: Codable, Equatable, Sendable {
    static let empty = DashboardUsageOverview()

    var wordsPerMinute: Int = 0
    var correctedWordCount: Int = 0
    var dictionaryFixCount: Int = 0
    var appCategoryUsage: [DashboardAppCategoryUsage] = []
    var distinctAppCount: Int = 0
    var modeWordShares: [DashboardModeWordShare] = []
    var streak = DashboardStreakSummary()

    var totalFixCount: Int {
        correctedWordCount + dictionaryFixCount
    }

    var trackedAppSessionCount: Int {
        appCategoryUsage.reduce(0) { $0 + $1.sessionCount }
    }
}

enum DashboardBookBenchmark {
    // Typical adult novel length.
    static let wordsPerBook = 90_000
}
