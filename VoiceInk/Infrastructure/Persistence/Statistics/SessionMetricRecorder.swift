import AppKit
import Foundation
import OSLog
import SwiftData

struct SessionTargetApp: Equatable, Sendable {
    let bundleIdentifier: String
    let name: String?

    /// The app VoiceInk will paste into. Recorder panels never take focus,
    /// so the frontmost app is still the user's target when recording stops.
    @MainActor
    static func frontmost() -> SessionTargetApp? {
        guard let app = NSWorkspace.shared.frontmostApplication,
            let bundleIdentifier = app.bundleIdentifier,
            bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return nil
        }
        return SessionTargetApp(bundleIdentifier: bundleIdentifier, name: app.localizedName)
    }
}

enum SessionMetricRecorder {
    private static let logger = Logger(subsystem: "com.karat.VoiceInkLite", category: "SessionMetricRecorder")
    private static let source = "recorder"

    @discardableResult
    static func recordRecorderSession(
        transcription: Transcription,
        model: (any TranscriptionModel)?,
        in modelContext: ModelContext,
        timestamp: Date = Date(),
        targetApp: SessionTargetApp? = nil,
        dictionaryReplacementCount: Int? = nil,
        countsEnhancementAsCorrection: Bool = true
    ) throws -> Bool {
        guard transcription.transcriptionStatus == TranscriptionStatus.completed.rawValue else {
            return false
        }

        let transcriptionId = transcription.id
        let descriptor = FetchDescriptor<SessionMetric>(
            predicate: #Predicate<SessionMetric> { metric in
                metric.transcriptionId == transcriptionId
            }
        )

        if try modelContext.fetchCount(descriptor) > 0 {
            return false
        }

        let textForCounting = finalTextForCounting(from: transcription)
        let wordCount = WordCounter.count(in: textForCounting)
        let audioDuration = max(transcription.duration, 0)
        let transcriptionDuration = transcription.transcriptionDuration.flatMap { $0 > 0 ? $0 : nil }
        let speedFactor = transcriptionDuration.flatMap { duration in
            audioDuration > 0 ? audioDuration / duration : nil
        }

        let enhancementDuration = transcription.enhancementDuration.flatMap { $0 > 0 ? $0 : nil }
        let enhancementTokenEstimate = EnhancementTokenEstimate.estimate(from: transcription)
        let correctedWordCount: Int? = {
            guard countsEnhancementAsCorrection,
                enhancementDuration != nil,
                let enhancedText = transcription.enhancedText
            else {
                return nil
            }
            return CorrectedWordCounter.count(original: transcription.text, edited: enhancedText)
        }()

        let metric = SessionMetric(
            transcriptionId: transcription.id,
            timestamp: timestamp,
            source: source,
            wordCount: wordCount,
            audioDuration: audioDuration,
            transcriptionModelName: transcription.transcriptionModelName ?? model?.displayName,
            transcriptionDuration: transcriptionDuration,
            speedFactor: speedFactor,
            modeName: transcription.modeName,
            aiEnhancementModelName: transcription.aiEnhancementModelName,
            enhancementDuration: enhancementDuration,
            enhancementEstimatedTokenCount: enhancementTokenEstimate?.tokenCount,
            targetAppBundleIdentifier: targetApp?.bundleIdentifier,
            targetAppName: targetApp?.name,
            dictionaryReplacementCount: dictionaryReplacementCount,
            correctedWordCount: correctedWordCount
        )

        modelContext.insert(metric)
        logger.notice("Recorded session metric for transcription \(transcriptionId.uuidString, privacy: .public)")
        return true
    }

    private static func finalTextForCounting(from transcription: Transcription) -> String {
        if let enhancedText = transcription.enhancedText,
            transcription.enhancementDuration != nil,
            !enhancedText.isEmpty
        {
            return enhancedText
        }

        return transcription.text
    }
}
