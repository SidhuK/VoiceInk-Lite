import SwiftUI

struct DashboardStreakCard: View {
    private static let daysPerWeek = 7
    private static let cellSize: CGFloat = 16
    private static let minimumCellSpacing: CGFloat = 5
    private static let weekdayLabelWidth: CGFloat = 34
    private static let trailingChevronWidth: CGFloat = 24
    private static let monthLabelHeight: CGFloat = 14
    private static let minimumVisibleWeeks = 4

    let points: [DashboardProductivityPoint]
    let streak: DashboardStreakSummary

    @State private var pageOffset = 0

    private var calendar: Calendar {
        DashboardPeriodWindows.dashboardCalendar()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            GeometryReader { geometry in
                heatmap(width: geometry.size.width)
            }
            .frame(height: gridHeight)

            legend
        }
        .dashboardUsageCardStyle()
    }

    // MARK: Header and legend

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(streakTitle)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.Text.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("Longest streak | \(longestStreakText)")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var streakTitle: String {
        switch streak.currentDays {
        case 0: return String(localized: "No active streak")
        case 1: return String(localized: "1 day streak")
        default: return String(localized: "\(streak.currentDays) day streak")
        }
    }

    private var longestStreakText: String {
        streak.longestDays == 1
            ? String(localized: "1 day")
            : String(localized: "\(streak.longestDays) days")
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("More")
            ForEach(ActivityLevel.legendOrder) { level in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(level.color)
                    .frame(width: 14, height: 14)
            }
            Text("Less")

            Spacer(minLength: 12)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(AppTheme.Usage.strongest, lineWidth: 1.5)
                .frame(width: 14, height: 14)
            Text("Current streak")
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(AppTheme.Text.secondary)
        .accessibilityHidden(true)
    }

    // MARK: Heatmap

    private var gridHeight: CGFloat {
        Self.monthLabelHeight + 6
            + CGFloat(Self.daysPerWeek) * Self.cellSize
            + CGFloat(Self.daysPerWeek - 1) * Self.minimumCellSpacing
    }

    private func heatmap(width: CGFloat) -> some View {
        let model = HeatmapModel(
            points: points,
            streak: streak,
            calendar: calendar,
            visibleWeeks: visibleWeekCount(for: width),
            pageOffset: pageOffset
        )
        let columnSpacing = columnSpacing(for: width, weekCount: model.weeks.count)

        return HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                pageButton(systemName: "chevron.left", isEnabled: model.hasOlderPage, help: "Show earlier weeks") {
                    pageOffset += 1
                }
                .frame(height: Self.monthLabelHeight)

                VStack(alignment: .leading, spacing: Self.minimumCellSpacing) {
                    ForEach(model.weekdaySymbols, id: \.self) { symbol in
                        Text(verbatim: symbol)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.Text.secondary)
                            .frame(height: Self.cellSize)
                    }
                }
            }
            .frame(width: Self.weekdayLabelWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: columnSpacing) {
                    ForEach(model.weeks) { week in
                        Text(verbatim: week.monthLabel ?? "")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.Text.secondary)
                            .fixedSize()
                            .frame(width: Self.cellSize, height: Self.monthLabelHeight, alignment: .leading)
                    }
                }

                HStack(alignment: .top, spacing: columnSpacing) {
                    ForEach(model.weeks) { week in
                        VStack(spacing: Self.minimumCellSpacing) {
                            ForEach(week.days) { day in
                                DayCell(day: day, size: Self.cellSize)
                            }
                        }
                    }
                }
            }

            pageButton(systemName: "chevron.right", isEnabled: pageOffset > 0, help: "Show later weeks") {
                pageOffset = max(pageOffset - 1, 0)
            }
            .frame(width: Self.trailingChevronWidth, height: Self.monthLabelHeight, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary(model: model)))
    }

    private func gridWidth(for width: CGFloat) -> CGFloat {
        width - Self.weekdayLabelWidth - Self.trailingChevronWidth
    }

    private func visibleWeekCount(for width: CGFloat) -> Int {
        let gridWidth = gridWidth(for: width)
        let count = Int((gridWidth + Self.minimumCellSpacing) / (Self.cellSize + Self.minimumCellSpacing))
        return max(count, Self.minimumVisibleWeeks)
    }

    private func columnSpacing(for width: CGFloat, weekCount: Int) -> CGFloat {
        guard weekCount > 1 else { return Self.minimumCellSpacing }
        let gridWidth = gridWidth(for: width)
        let spacing = (gridWidth - CGFloat(weekCount) * Self.cellSize) / CGFloat(weekCount - 1)
        return max(spacing, Self.minimumCellSpacing)
    }

    private func pageButton(
        systemName: String,
        isEnabled: Bool,
        help: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.Text.secondary)
                .frame(width: 18, height: Self.monthLabelHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .help(help)
        .accessibilityLabel(Text(help))
    }

    private func accessibilitySummary(model: HeatmapModel) -> String {
        let activeDays = model.weeks.reduce(0) { total, week in
            total + week.days.filter { $0.level != .none && $0.level != .future }.count
        }
        return String(
            localized: "\(streakTitle). Longest streak \(longestStreakText). \(activeDays) active days in the weeks shown."
        )
    }
}

// MARK: - Model

private enum ActivityLevel: Int, Identifiable {
    case future
    case none
    case low
    case medium
    case high
    case highest

    var id: Int { rawValue }

    static let legendOrder: [ActivityLevel] = [.highest, .high, .medium, .low]

    var color: Color {
        switch self {
        case .future: return AppTheme.Usage.future
        case .none: return AppTheme.Usage.inactive
        case .low: return AppTheme.Usage.light
        case .medium: return AppTheme.Usage.medium
        case .high: return AppTheme.Usage.strong
        case .highest: return AppTheme.Usage.strongest
        }
    }
}

private struct HeatmapDay: Identifiable {
    var id: Date { date }
    let date: Date
    let words: Int
    let level: ActivityLevel
    let isInCurrentStreak: Bool
    let helpText: String
}

private struct HeatmapWeek: Identifiable {
    var id: Date { start }
    let start: Date
    let monthLabel: String?
    let days: [HeatmapDay]
}

private struct HeatmapModel {
    private static let minimumColumnsBetweenMonthLabels = 3

    let weeks: [HeatmapWeek]
    let weekdaySymbols: [String]
    let hasOlderPage: Bool

    init(
        points: [DashboardProductivityPoint],
        streak: DashboardStreakSummary,
        calendar: Calendar,
        visibleWeeks: Int,
        pageOffset: Int
    ) {
        let today = calendar.startOfDay(for: Date())
        let currentWeekStart = Self.startOfWeek(containing: today, calendar: calendar)
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -(pageOffset * visibleWeeks), to: currentWeekStart)
            ?? currentWeekStart
        let firstWeekStart = calendar.date(byAdding: .weekOfYear, value: -(visibleWeeks - 1), to: lastWeekStart)
            ?? lastWeekStart

        var wordsByDay: [Date: Int] = [:]
        for point in points where point.words > 0 {
            wordsByDay[calendar.startOfDay(for: point.date), default: 0] += point.words
        }
        let thresholds = Self.levelThresholds(for: Array(wordsByDay.values))

        let earliestActivity = wordsByDay.keys.min() ?? today
        hasOlderPage = firstWeekStart > Self.startOfWeek(containing: earliestActivity, calendar: calendar)

        let shift = calendar.firstWeekday - 1
        let symbols = calendar.shortWeekdaySymbols
        weekdaySymbols = Array(symbols[shift...] + symbols[..<shift])

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.locale = .current
        monthFormatter.setLocalizedDateFormatFromTemplate("MMM")

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = .current
        dayFormatter.dateStyle = .medium

        let weekStarts = (0..<visibleWeeks).compactMap { weekIndex in
            calendar.date(byAdding: .weekOfYear, value: weekIndex, to: firstWeekStart)
        }
        let months = weekStarts.map { calendar.component(.month, from: $0) }

        var weeks: [HeatmapWeek] = []
        for (weekIndex, weekStart) in weekStarts.enumerated() {
            let days: [HeatmapDay] = (0..<7).compactMap { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
                let words = wordsByDay[date, default: 0]
                let level: ActivityLevel = date > today ? .future : Self.level(for: words, thresholds: thresholds)
                let dateText = dayFormatter.string(from: date)
                return HeatmapDay(
                    date: date,
                    words: words,
                    level: level,
                    isInCurrentStreak: streak.isPartOfCurrentStreak(date),
                    helpText: String(
                        format: String(localized: "%@: %@ words"),
                        dateText,
                        Formatters.formattedNumber(words)
                    )
                )
            }

            let monthLabel = Self.showsMonthLabel(at: weekIndex, months: months)
                ? monthFormatter.string(from: weekStart)
                : nil

            weeks.append(HeatmapWeek(start: weekStart, monthLabel: monthLabel, days: days))
        }

        self.weeks = weeks
    }

    private static func startOfWeek(containing date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let offset = (calendar.component(.weekday, from: day) - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -offset, to: day) ?? day
    }

    /// Labels each month where it starts. A month cut off at the left edge only gets
    /// a label if it has room, so it never crowds the next month's label.
    private static func showsMonthLabel(at index: Int, months: [Int]) -> Bool {
        if index > 0 {
            return months[index] != months[index - 1]
        }
        let columnsInFirstMonth = months.prefix { $0 == months[0] }.count
        return columnsInFirstMonth >= minimumColumnsBetweenMonthLabels
    }

    /// Quartile cut points over active days, so the shading adapts to each person's typical volume.
    private static func levelThresholds(for values: [Int]) -> [Int] {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return [] }
        return [0.25, 0.5, 0.75].map { fraction in
            sorted[min(Int(Double(sorted.count) * fraction), sorted.count - 1)]
        }
    }

    private static func level(for words: Int, thresholds: [Int]) -> ActivityLevel {
        guard words > 0 else { return .none }
        guard thresholds.count == 3 else { return .highest }
        if words > thresholds[2] { return .highest }
        if words > thresholds[1] { return .high }
        if words > thresholds[0] { return .medium }
        return .low
    }
}

private struct DayCell: View {
    let day: HeatmapDay
    let size: CGFloat

    var body: some View {
        Group {
            if day.isInCurrentStreak {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(day.level.color)
                    .padding(2.5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(AppTheme.Usage.strongest, lineWidth: 1.5)
                    }
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(day.level.color)
            }
        }
        .frame(width: size, height: size)
        .help(day.level == .future ? Text(verbatim: "") : Text(verbatim: day.helpText))
    }
}
