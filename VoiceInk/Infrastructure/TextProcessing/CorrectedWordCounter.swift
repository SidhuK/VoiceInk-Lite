import Foundation
import NaturalLanguage

enum CorrectedWordCounter {
    // Myers diff cost grows with text length; long rewrites are not "corrections" anyway.
    private static let maximumWordsPerSide = 2_000

    /// Counts words the edit changed, added, or removed (filler words count),
    /// capped at the original word count so full rewrites don't inflate the total.
    static func count(original: String, edited: String) -> Int? {
        let originalWords = words(in: original)
        let editedWords = words(in: edited)

        guard !originalWords.isEmpty,
            !editedWords.isEmpty,
            originalWords.count <= maximumWordsPerSide,
            editedWords.count <= maximumWordsPerSide
        else {
            return nil
        }

        let difference = editedWords.difference(from: originalWords)
        let changedWords = max(difference.insertions.count, difference.removals.count)
        return min(changedWords, originalWords.count)
    }

    private static func words(in text: String) -> [Substring] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { text[$0] }
    }
}
