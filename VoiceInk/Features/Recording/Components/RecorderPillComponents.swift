import SwiftUI

// MARK: - Pill Metrics

enum RecorderPillMetrics {
    static let height: CGFloat = 28
    static let buttonDiameter: CGFloat = 18
    static let edgeInset: CGFloat = 5
    static let waveformGap: CGFloat = 8
}

// MARK: - Circle Button Style

private struct RecorderPillButtonStyle: ButtonStyle {
    var dimsWhenDisabled = true
    @State private var isHovering = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(isEnabled && isHovering ? 0.08 : 0)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(isEnabled || !dimsWhenDisabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Cancel Button

struct RecorderPillCancelButton: View {
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(Color(white: 0.98))
                .frame(width: RecorderPillMetrics.buttonDiameter, height: RecorderPillMetrics.buttonDiameter)
                .background(Circle().fill(Color(red: 0.26, green: 0.25, blue: 0.23)))
                .contentShape(Circle())
        }
        .buttonStyle(RecorderPillButtonStyle())
        .help(Text(label))
        .accessibilityLabel(Text(label))
    }
}

// MARK: - Confirm Button

struct RecorderPillConfirmButton: View {
    enum Kind: Equatable {
        case confirm
        case followUp
        case processing
    }

    let kind: Kind
    let isEnabled: Bool
    let action: () -> Void

    private var label: LocalizedStringKey {
        switch kind {
        case .confirm: return "Finish recording"
        case .followUp: return "Record follow-up"
        case .processing: return "Processing"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color(white: 0.96))
                glyph
            }
            .frame(width: RecorderPillMetrics.buttonDiameter, height: RecorderPillMetrics.buttonDiameter)
            .contentShape(Circle())
            .animation(.easeOut(duration: 0.16), value: kind)
        }
        .buttonStyle(RecorderPillButtonStyle(dimsWhenDisabled: kind != .processing))
        .disabled(!isEnabled || kind == .processing)
        .help(Text(label))
        .accessibilityLabel(Text(label))
    }

    @ViewBuilder
    private var glyph: some View {
        let ink = Color(white: 0.1)
        switch kind {
        case .confirm:
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(ink)
                .transition(.scale.combined(with: .opacity))
        case .followUp:
            Image(systemName: "mic.fill")
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(ink)
                .transition(.scale.combined(with: .opacity))
        case .processing:
            ProcessingIndicator(color: ink, diameter: 9)
                .transition(.opacity)
        }
    }
}

// MARK: - Waveform

struct RecorderPillWaveform: View {
    enum Mode: Equatable {
        case idle
        case listening
        case processing
    }

    let mode: Mode
    let audioMeterProvider: () -> AudioMeter

    // Uneven resting heights keep the bars from looking like a flat progress bar while quiet.
    private static let restingHeights: [CGFloat] = [5, 6, 7, 6.5, 9, 7.5, 7, 8, 7, 6]
    private static let barWidth: CGFloat = 2
    private static let barSpacing: CGFloat = 2
    private static let idleHeight: CGFloat = 2
    private static let maxHeight: CGFloat = 18

    static var width: CGFloat {
        CGFloat(restingHeights.count) * barWidth + CGFloat(restingHeights.count - 1) * barSpacing
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: mode == .idle)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let amplitude = mode == .listening ? Self.amplitude(from: audioMeterProvider()) : 0

            HStack(spacing: Self.barSpacing) {
                ForEach(Self.restingHeights.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(barOpacity))
                        .frame(width: Self.barWidth, height: height(for: index, time: time, amplitude: amplitude))
                }
            }
            .frame(width: Self.width, height: Self.maxHeight)
        }
        .animation(.easeInOut(duration: 0.25), value: mode)
        .accessibilityHidden(true)
    }

    private var barOpacity: Double {
        switch mode {
        case .idle: return 0.45
        case .listening: return 1
        case .processing: return 0.7
        }
    }

    private static func amplitude(from meter: AudioMeter) -> Double {
        max(0, min(1, pow(meter.averagePower, 0.7)))
    }

    private func height(for index: Int, time: TimeInterval, amplitude: Double) -> CGFloat {
        let resting = Self.restingHeights[index]

        switch mode {
        case .idle:
            return Self.idleHeight
        case .listening:
            let wave = sin(time * 9 + Double(index) * 0.85) * 0.5 + 0.5
            let center = Double(Self.restingHeights.count - 1) / 2
            let centerWeight = 1 - abs(Double(index) - center) / center * 0.45
            let lift = CGFloat(amplitude * (0.35 + 0.65 * wave) * centerWeight) * (Self.maxHeight - resting)
            return min(Self.maxHeight, resting + lift)
        case .processing:
            let wave = sin(time * 5 - Double(index) * 0.6) * 0.5 + 0.5
            return 3 + CGFloat(wave) * 6
        }
    }
}

// MARK: - Mode Strip

struct RecorderModeStrip: View {
    @ObservedObject private var modeManager = ModeManager.shared

    var body: some View {
        let selectedId = modeManager.currentEffectiveConfiguration?.id

        FlowLayout(spacing: 6) {
            ForEach(modeManager.enabledConfigurations) { config in
                RecorderModeChip(config: config, isSelected: config.id == selectedId) {
                    modeManager.setActiveConfiguration(config)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

private struct RecorderModeChip: View {
    let config: ModeConfig
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    private var foreground: Color {
        isSelected ? Color(white: 0.1) : .white.opacity(0.85)
    }

    private var background: Color {
        if isSelected { return Color(white: 0.96) }
        return .white.opacity(isHovering ? 0.18 : 0.10)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                ModeIconView(
                    icon: config.icon,
                    size: config.icon.kind == .emoji ? 11 : 9.5,
                    color: foreground
                )
                Text(config.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Capsule(style: .continuous).fill(background))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.16), value: isSelected)
        .help(config.name)
        .accessibilityLabel(Text(config.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Mode Menu

struct RecorderModeMenu: View {
    @ObservedObject private var modeManager = ModeManager.shared

    var body: some View {
        let configurations = modeManager.enabledConfigurations
        let selectedId = modeManager.currentEffectiveConfiguration?.id

        if configurations.isEmpty {
            Text("No Modes Available")
        } else {
            Section("Mode") {
                ForEach(configurations) { config in
                    Button {
                        modeManager.setActiveConfiguration(config)
                    } label: {
                        if config.id == selectedId {
                            Label(config.name, systemImage: "checkmark")
                        } else {
                            Text(config.name)
                        }
                    }
                }
            }
        }
    }
}
