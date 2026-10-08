import SwiftUI

struct DashboardAppUsageCard: View {
    private static let rowHeight: CGFloat = 26
    private static let labelReservedWidth: CGFloat = 170
    private static let minimumBarWidth: CGFloat = 40

    let usage: [DashboardAppCategoryUsage]
    let distinctAppCount: Int

    private var totalSessions: Int {
        usage.reduce(0) { $0 + $1.sessionCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if totalSessions > 0 {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(usage.enumerated()), id: \.element.id) { rank, item in
                        row(for: item, rank: rank)
                    }
                }
            } else {
                emptyState
            }
        }
        .dashboardUsageCardStyle()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("App usage")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.Text.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("Total apps used | \(Formatters.formattedNumber(distinctAppCount))")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func row(for item: DashboardAppCategoryUsage, rank: Int) -> some View {
        let share = Double(item.sessionCount) / Double(max(totalSessions, 1))
        let style = barStyle(forRank: rank)

        return HStack(spacing: 14) {
            Image(systemName: item.category.systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.Text.primary)
                .frame(width: 20)
                .accessibilityHidden(true)

            GeometryReader { geometry in
                let maximumBarWidth = max(geometry.size.width - Self.labelReservedWidth, Self.minimumBarWidth)
                let barWidth = max(maximumBarWidth * share, Self.minimumBarWidth)

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(style.fill)
                        .frame(width: barWidth)
                        .overlay {
                            Text(share.formatted(.percent.precision(.fractionLength(0))))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(style.text)
                                .monospacedDigit()
                        }

                    HStack(spacing: 5) {
                        Text(verbatim: Formatters.formattedNumber(item.sessionCount))
                            .monospacedDigit()
                        Text(item.category.title)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppTheme.Text.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                    Spacer(minLength: 0)
                }
            }
            .frame(height: Self.rowHeight)
        }
        .accessibilityElement(children: .combine)
    }

    private func barStyle(forRank rank: Int) -> (fill: Color, text: Color) {
        switch rank {
        case 0: return (AppTheme.Usage.strongest, .white)
        case 1: return (AppTheme.Usage.strong, .white)
        default: return (AppTheme.Usage.medium, AppTheme.Text.primary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No app data yet")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.Text.primary)
            Text("Your next dictation will show up here, grouped by the kind of app you dictated into. App names never leave your Mac.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
