// Run with ./test.sh (compiles this together with CorrectionGuard.swift; no Xcode needed).
import Foundation

var failures = 0
func check(_ name: String, _ condition: Bool) {
    print((condition ? "ok   " : "FAIL ") + name)
    if !condition { failures += 1 }
}

let notes = "hey sam, can you pls confrim if teh deploy is ready\nthe new dashbord looks good to me\nlets ship it tommorow if nothing breaks"
let notesFixed = "Hey Sam, can you please confirm if the deploy is ready?\nThe new dashboard looks good to me.\nLet's ship it tomorrow if nothing breaks."

// Normal fixes pass
check("simple typo fix passes",
      CorrectionGuard.problem(original: "i has a apple and she dont like it", corrected: "I have an apple and she doesn't like it.") == nil)
check("short text passes", CorrectionGuard.problem(original: "hi helllo", corrected: "hi hello") == nil)
check("tiny word passes", CorrectionGuard.problem(original: "teh", corrected: "the") == nil)
check("multi-line fix passes", CorrectionGuard.problem(original: notes, corrected: notesFixed) == nil)
check("heavy typos pass",
      CorrectionGuard.problem(original: "Plese send me teh report tommorow, thx", corrected: "Please send me the report tomorrow, thank you.") == nil)

// Refusals
check("empty result refused", CorrectionGuard.problem(original: "i has a apple", corrected: "  \n ") != nil)
check("dropped lines refused",
      CorrectionGuard.problem(original: notes, corrected: "Hey Sam, can you please confirm if the deploy is ready?") != nil)
check("translation refused",
      CorrectionGuard.problem(original: "Plese send me teh report tommorow, thx", corrected: "Bitte senden Sie mir den Bericht morgen, bitte") != nil)
check("raw JSON dump refused",
      CorrectionGuard.problem(original: "i has a apple and she dont like it",
                              corrected: "```json\n{\"correctedText\": \"I have an apple\"}\n```", language: "Unknown") != nil)
check("added commentary refused",
      CorrectionGuard.problem(original: "i has a apple",
                              corrected: "Sure! Here is the corrected version of your text with all grammar mistakes fixed: I have an apple.") != nil)

// Similarity sanity
check("identical text has similarity 1", CorrectionGuard.similarity("same", "same") == 1)
check("unrelated text has low similarity", CorrectionGuard.similarity("hello there my friend", "zzzz qqqq xxxx") < 0.3)

if failures > 0 {
    print("\n\(failures) check(s) failed")
    exit(1)
}
print("\nAll checks passed")
