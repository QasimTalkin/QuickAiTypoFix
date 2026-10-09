import Foundation

/// Safety checks for in-place replacement.
///
/// TypoFix replaces your selection without showing a preview, so a model that misbehaves
/// (drops lines, translates, adds commentary, returns raw JSON) must never overwrite your text.
/// Anything that looks wrong is refused and the original text is left untouched.
enum CorrectionGuard {
    /// Returns a human-readable reason to refuse the correction, or nil if it looks safe to paste.
    static func problem(original: String, corrected: String, language: String = "") -> String? {
        let o = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = corrected.trimmingCharacters(in: .whitespacesAndNewlines)

        if c.isEmpty {
            return "The model returned an empty correction. Nothing was changed."
        }
        // "Unknown" means the model's reply wasn't our JSON format; never paste raw markup.
        if language == "Unknown" && (c.hasPrefix("```") || c.contains("\"correctedText\"")) {
            return "The model didn't return a usable answer. Nothing was changed."
        }
        // Small models sometimes silently drop lines of multi-line text.
        if o.count >= 20 && Double(c.count) < Double(o.count) * 0.7 {
            return "The correction is much shorter than your text (the model may have dropped part of it). Nothing was changed."
        }
        if Double(c.count) > Double(o.count) * 1.6 + 20 {
            return "The correction is much longer than your text. Nothing was changed."
        }
        // A typo fix keeps most characters. A translation or rewrite does not.
        if o.count >= 12 && similarity(o, c) < 0.5 {
            return "The correction looks like a rewrite or translation of your text. Nothing was changed."
        }
        return nil
    }

    /// 1.0 = identical, 0.0 = nothing in common (case-insensitive Levenshtein ratio).
    static func similarity(_ a: String, _ b: String) -> Double {
        let x = Array(a.lowercased())
        let y = Array(b.lowercased())
        if x.isEmpty || y.isEmpty { return x.isEmpty && y.isEmpty ? 1 : 0 }
        if x.count > 4000 || y.count > 4000 { return 1 }  // too long to compare cheaply; length checks still apply

        var previous = Array(0...y.count)
        var current = [Int](repeating: 0, count: y.count + 1)
        for i in 1...x.count {
            current[0] = i
            for j in 1...y.count {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return 1 - Double(previous[y.count]) / Double(max(x.count, y.count))
    }
}
