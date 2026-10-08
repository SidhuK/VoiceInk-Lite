import Foundation
import SwiftData

@Model
final class SessionMetric {
    var id: UUID = UUID()
    var transcriptionId: UUID = UUID()
    var timestamp: Date = Date()
    var source: String?
    var wordCount: Int = 0
    var audioDuration: TimeInterval = 0
    var transcriptionModelName: String?
    var transcriptionDuration: TimeInterval?
    var speedFactor: Double?
    @Attribute(originalName: "powerModeName")
    var modeName: String?
    var aiEnhancementModelName: String?
    var enhancementDuration: TimeInterval?
    var enhancementEstimatedTokenCount: Int?
    var targetAppBundleIdentifier: String?
    var targetAppName: String?
    var dictionaryReplacementCount: Int?
    var correctedWordCount: Int?

    init(
        transcriptionId: UUID,
        timestamp: Date = Date(),
        source: String? = "recorder",
        wordCount: Int,
        audioDuration: TimeInterval,
        transcriptionModelName: String?,
        transcriptionDuration: TimeInterval?,
        speedFactor: Double?,
        modeName: String?,
        aiEnhancementModelName: String?,
        enhancementDuration: TimeInterval?,
        enhancementEstimatedTokenCount: Int? = nil,
        targetAppBundleIdentifier: String? = nil,
        targetAppName: String? = nil,
        dictionaryReplacementCount: Int? = nil,
        correctedWordCount: Int? = nil
    ) {
        self.id = UUID()
        self.transcriptionId = transcriptionId
        self.timestamp = timestamp
        self.source = source
        self.wordCount = wordCount
        self.audioDuration = audioDuration
        self.transcriptionModelName = transcriptionModelName
        self.transcriptionDuration = transcriptionDuration
        self.speedFactor = speedFactor
        self.modeName = modeName
        self.aiEnhancementModelName = aiEnhancementModelName
        self.enhancementDuration = enhancementDuration
        self.enhancementEstimatedTokenCount = enhancementEstimatedTokenCount
        self.targetAppBundleIdentifier = targetAppBundleIdentifier
        self.targetAppName = targetAppName
        self.dictionaryReplacementCount = dictionaryReplacementCount
        self.correctedWordCount = correctedWordCount
    }
}
