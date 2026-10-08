import SwiftUI

struct DashboardUsageOverviewSection: View {
    private static let threeColumnMinimumWidth: CGFloat = 620
    private static let twoColumnMinimumWidth: CGFloat = 900

    let overview: DashboardUsageOverview
    let totalWords: Int
    let dailyActivity: [DashboardProductivityPoint]
    let availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: DashboardLayout.columnSpacing) {
            if availableWidth >= Self.threeColumnMinimumWidth {
                HStack(alignment: .top, spacing: DashboardLayout.columnSpacing) {
                    topCards
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                topCards
            }

            if availableWidth >= Self.twoColumnMinimumWidth {
                HStack(alignment: .top, spacing: DashboardLayout.columnSpacing) {
                    appUsageCard
                        .frame(width: (availableWidth - DashboardLayout.columnSpacing) * 0.46)
                    streakCard
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                appUsageCard
                streakCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var topCards: some View {
        DashboardSpeedCard(wordsPerMinute: overview.wordsPerMinute)
        DashboardFixesCard(
            correctedWordCount: overview.correctedWordCount,
            dictionaryFixCount: overview.dictionaryFixCount
        )
        DashboardTotalWordsCard(totalWords: totalWords, modeShares: overview.modeWordShares)
    }

    private var appUsageCard: some View {
        DashboardAppUsageCard(
            usage: overview.appCategoryUsage,
            distinctAppCount: overview.distinctAppCount
        )
    }

    private var streakCard: some View {
        DashboardStreakCard(points: dailyActivity, streak: overview.streak)
    }
}

// MARK: - Shared pieces

struct DashboardUsageCaption: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(AppTheme.Text.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct DashboardUsageBigNumber: View {
    let value: String

    var body: some View {
        Text(verbatim: value)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.Text.primary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .contentTransition(.numericText())
    }
}

private struct DashboardUsageInfoTip: View {
    let message: LocalizedStringKey

    var body: some View {
        var tip = InfoTip(message)
        tip.iconSize = .small
        tip.iconColor = AppTheme.Text.secondary
        return tip.accessibilityLabel(Text(message))
    }
}

extension View {
    /// Stretches before drawing the background so cards in a row share one height.
    func dashboardUsageCardStyle() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DashboardInsightCardBackground())
    }
}

// MARK: - Words per minute

struct DashboardSpeedCard: View {
    let wordsPerMinute: Int

    private var typingMultiple: Double {
        Double(wordsPerMinute) / DashboardTimeSaving.averageTypingSpeedWordsPerMinute
    }

    // A full arc means five times average typing speed (200 WPM).
    private var gaugeProgress: Double {
        min(typingMultiple / 5, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DashboardUsageBigNumber(value: wordsPerMinute > 0 ? Formatters.formattedNumber(wordsPerMinute) : "--")

            HStack(spacing: 2) {
                DashboardUsageCaption("Words per minute")
                DashboardUsageInfoTip(
                    message: "Your average speaking speed across all dictations, based on final word count and recording length. Typing averages about 40 words per minute."
                )
            }

            DashboardSpeedGauge(progress: gaugeProgress) {
                VStack(spacing: 1) {
                    Text(wordsPerMinute > 0 ? typingMultiple.formatted(.number.precision(.fractionLength(1))) + "×" : "--")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Text.primary)
                        .monospacedDigit()
                    Text("vs. typing")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.Text.secondary)
                }
            }
            .frame(width: 150, height: 84)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .dashboardUsageCardStyle()
        .accessibilityElement(children: .combine)
    }
}

private struct DashboardSpeedGauge<Label: View>: View {
    private static var lineWidth: CGFloat { 16 }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: Double
    @ViewBuilder let label: Label

    var body: some View {
        ZStack(alignment: .bottom) {
            HalfArc()
                .stroke(AppTheme.Usage.gaugeTrack, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
            HalfArc()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.Usage.strongest, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: progress)
            label
        }
        .padding(Self.lineWidth / 2)
    }
}

private struct HalfArc: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width / 2, rect.height)
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: false
        )
        return path
    }
}

// MARK: - Fixes

struct DashboardFixesCard: View {
    let correctedWordCount: Int
    let dictionaryFixCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DashboardUsageBigNumber(value: Formatters.formattedNumber(correctedWordCount + dictionaryFixCount))
            DashboardUsageCaption("Fixes made by VoiceInk")
                .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 8)

            fixRow(
                count: correctedWordCount,
                label: "words corrected",
                info: "Words your AI prompts changed when cleaning up a dictation. Assistant replies don't count. Tracking starts with this version."
            )
            fixRow(
                count: dictionaryFixCount,
                label: "dictionary fixes",
                info: "Times a Dictionary replacement rule fixed a word in your transcript. Tracking starts with this version."
            )
        }
        .dashboardUsageCardStyle()
    }

    private func fixRow(count: Int, label: LocalizedStringKey, info: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: Formatters.formattedNumber(count))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 13))
            Spacer(minLength: 4)
            DashboardUsageInfoTip(message: info)
        }
        .foregroundStyle(AppTheme.Text.primary)
        .lineLimit(1)
    }
}

// MARK: - Total words

struct DashboardTotalWordsCard: View {
    let totalWords: Int
    let modeShares: [DashboardModeWordShare]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DashboardUsageBigNumber(value: Formatters.formattedNumber(totalWords))
            DashboardUsageCaption("Total words dictated")
                .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 8)

            Text(bookMessage)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 10)

            if !modeShares.isEmpty {
                DashboardModeShareBar(shares: modeShares)
            }
        }
        .dashboardUsageCardStyle()
    }

    private var bookMessage: String {
        guard totalWords > 0 else {
            return String(localized: "Your first words will show up here.")
        }

        let books = totalWords / DashboardBookBenchmark.wordsPerBook
        switch books {
        case 0:
            let percent = max(1, totalWords * 100 / DashboardBookBenchmark.wordsPerBook)
            return String(localized: "You're \(percent)% of the way to a full novel.")
        case 1:
            return String(localized: "You've written a complete book!")
        default:
            return String(localized: "You've written \(books) complete books!")
        }
    }
}

private struct DashboardModeShareBar: View {
    private static let segmentStyles: [(fill: Color, text: Color)] = [
        (AppTheme.Usage.strongest, .white),
        (AppTheme.Usage.strong, .white),
        (AppTheme.Usage.medium, AppTheme.Text.primary),
    ]
    private static let segmentSpacing: CGFloat = 3
    private static let minimumLabeledWidth: CGFloat = 56

    let shares: [DashboardModeWordShare]

    private var totalWords: Int {
        max(shares.reduce(0) { $0 + $1.words }, 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let available = geometry.size.width - Self.segmentSpacing * CGFloat(max(shares.count - 1, 0))

            HStack(spacing: Self.segmentSpacing) {
                ForEach(Array(shares.enumerated()), id: \.element.id) { index, share in
                    let width = max(available * CGFloat(share.words) / CGFloat(totalWords), 6)
                    segment(
                        share: share,
                        style: Self.segmentStyles[min(index, Self.segmentStyles.count - 1)],
                        showsLabel: width >= Self.minimumLabeledWidth
                    )
                    .frame(width: width)
                }
            }
        }
        .frame(height: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private func segment(
        share: DashboardModeWordShare,
        style: (fill: Color, text: Color),
        showsLabel: Bool
    ) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(style.fill)
            .overlay(alignment: .leading) {
                if showsLabel {
                    Text(verbatim: share.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(style.text)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                }
            }
            .help(Text(verbatim: "\(share.name): \(Formatters.formattedNumber(share.words))"))
    }

    private var accessibilitySummary: String {
        shares
            .map { "\($0.name), \(Formatters.formattedNumber($0.words)) words" }
            .joined(separator: "; ")
    }
}
