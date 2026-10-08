import SwiftUI

struct MiniRecorderView<S: RecorderStateProvider & ObservableObject>: View {
    @ObservedObject var stateProvider: S
    @ObservedObject var recorder: Recorder
    @ObservedObject var assistantSession: AssistantSession
    let onRecordButtonTapped: () -> Void
    let onCancelTapped: () -> Void
    let onAssistantFollowUp: (String) -> Void
    @AppStorage(RecorderDisplaySettingsKeys.showLiveTranscript) private var showLiveTranscript = true
    @AppStorage(RecorderDisplaySettingsKeys.liveTranscriptOnlyOnHover) private var liveTranscriptOnlyOnHover = true
    @ObservedObject private var modeManager = ModeManager.shared
    @State private var isHovering = false
    @State private var hoverExitTask: Task<Void, Never>?

    // MARK: - Layout Constants

    private var compactWidth: CGFloat {
        (RecorderPillMetrics.edgeInset + RecorderPillMetrics.buttonDiameter + RecorderPillMetrics.waveformGap) * 2
            + RecorderPillWaveform.width
    }
    private let expandedWidth: CGFloat = 300
    private let assistantWidth: CGFloat = 520
    private let compactCornerRadius: CGFloat = RecorderPillMetrics.height / 2
    private let expandedCornerRadius: CGFloat = 14

    // true when live transcript is streaming in during recording and should be on screen
    private var hasLiveTranscript: Bool {
        showLiveTranscript
            && (isHovering || !liveTranscriptOnlyOnHover)
            && stateProvider.recordingState == .recording
            && !stateProvider.partialTranscript.isEmpty
    }

    private var showsModeStrip: Bool {
        isHovering && !modeManager.enabledConfigurations.isEmpty
    }

    private var isExpanded: Bool {
        hasLiveTranscript || showsModeStrip
    }

    private var hasAssistantResponse: Bool {
        assistantSession.isVisible
    }

    private var liveAssistantFollowUpText: String {
        guard showLiveTranscript, stateProvider.recordingState == .recording else { return "" }
        return stateProvider.partialTranscript
    }

    private var isCapturingOrProcessing: Bool {
        switch stateProvider.recordingState {
        case .starting, .recording, .transcribing, .enhancing:
            return true
        case .idle, .busy:
            return false
        }
    }

    private var waveformMode: RecorderPillWaveform.Mode {
        switch stateProvider.recordingState {
        case .recording:
            return .listening
        case .transcribing, .enhancing, .busy:
            return .processing
        case .starting:
            return .idle
        case .idle:
            return assistantSession.isBusy ? .processing : .idle
        }
    }

    private var confirmKind: RecorderPillConfirmButton.Kind {
        switch stateProvider.recordingState {
        case .starting, .recording:
            return .confirm
        case .transcribing, .enhancing, .busy:
            return .processing
        case .idle:
            if assistantSession.isBusy { return .processing }
            return hasAssistantResponse && assistantSession.canSendFollowUp ? .followUp : .confirm
        }
    }

    private var isConfirmEnabled: Bool {
        switch confirmKind {
        case .confirm: return stateProvider.recordingState == .recording
        case .followUp: return true
        case .processing: return false
        }
    }

    private var controlBar: some View {
        HStack(spacing: 0) {
            RecorderPillCancelButton(
                label: isCapturingOrProcessing ? "Cancel recording" : "Close",
                action: onCancelTapped
            )

            Spacer(minLength: RecorderPillMetrics.waveformGap)

            RecorderPillWaveform(
                mode: waveformMode,
                audioMeterProvider: recorder.audioMeterSnapshot
            )

            Spacer(minLength: RecorderPillMetrics.waveformGap)

            RecorderPillConfirmButton(
                kind: confirmKind,
                isEnabled: isConfirmEnabled,
                action: onRecordButtonTapped
            )
        }
        .padding(.horizontal, RecorderPillMetrics.edgeInset)
        .frame(height: RecorderPillMetrics.height)
        .contentShape(Rectangle())
        .contextMenu { RecorderModeMenu() }
    }

    private var expandedSection: some View {
        VStack(spacing: 0) {
            if hasLiveTranscript {
                LiveTranscriptView(text: stateProvider.partialTranscript)
                Divider().background(Color.white.opacity(0.15))
            }
            if showsModeStrip {
                RecorderModeStrip()
                    .transition(.opacity)
                Divider().background(Color.white.opacity(0.15))
            }
        }
    }

    private func updateHover(_ hovering: Bool) {
        hoverExitTask?.cancel()
        if hovering {
            isHovering = true
            return
        }

        // A short grace period stops the pill from collapsing when the pointer
        // brushes the edge while the frame is still animating.
        hoverExitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            isHovering = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasAssistantResponse {
                AssistantPanelView(
                    session: assistantSession,
                    liveFollowUpText: liveAssistantFollowUpText,
                    onSend: onAssistantFollowUp
                )
                Divider().background(Color.white.opacity(0.15))
            } else {
                expandedSection
            }
            controlBar
        }
        .frame(width: hasAssistantResponse ? assistantWidth : (isExpanded ? expandedWidth : compactWidth))
        .background(Color.black)
        .clipShape(
            RoundedRectangle(
                cornerRadius: isExpanded || hasAssistantResponse ? expandedCornerRadius : compactCornerRadius,
                style: .continuous)
        )
        .onHover(perform: updateHover)
        .onDisappear { hoverExitTask?.cancel() }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .animation(.easeInOut(duration: 0.25), value: hasLiveTranscript)
        .animation(.easeInOut(duration: 0.3), value: hasAssistantResponse)
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}
