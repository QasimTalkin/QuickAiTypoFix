import Foundation
import KeyboardShortcuts
import AppKit

final class AppState: ObservableObject {
    // preconditions
    @Published var accessibilityAPIPermissionSetUp = false
    @Published var openAIKeySetUp = false

    // UI state
    @Published var showSettingsUI = false

    // In-place correction state; drives the menu bar icon
    @Published var isWorking = false
    @Published var lastError: String?

    private let llmClient = LlmClient()
    private var errorClearTask: Task<Void, Never>?

    var menuBarSymbol: String {
        if isWorking { return "ellipsis.circle" }
        if lastError != nil { return "exclamationmark.triangle" }
        return "wand.and.stars"
    }

    init() {
        checkPreconditions()
        KeyboardShortcuts.onKeyDown(for: .improveWriting) { [weak self] in
            Task { @MainActor in
                await self?.improveSelection()
            }
        }
    }

    public func checkPreconditions() {
        let openAIToken = SettingsManager.getAIApiToken()
        openAIKeySetUp = !openAIToken.isEmpty

        accessibilityAPIPermissionSetUp = AXIsProcessTrusted()
    }

    /// Reads the selection, asks the model for a correction and pastes it over the selection.
    /// No window is shown; problems are reported with a beep, the menu bar icon and the menu.
    @MainActor
    func improveSelection() async {
        if isWorking { return }

        checkPreconditions()
        guard accessibilityAPIPermissionSetUp else {
            return fail("macOS has not allowed this build to control your Mac. In System Settings → Privacy & Security → Accessibility, select TypoFix, click − to remove it, then click + and add /Applications/TypoFix.app again, and switch it on.")
        }
        guard openAIKeySetUp else {
            return fail("API key is not set. Open the menu bar icon → Settings.")
        }

        let selection = SelectionManager().getSelectedText()
        guard selection.isSuccessful() else {
            return fail(selection.error)
        }
        let original = selection.output
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fail("No text is selected. Please select some text and try again.")
        }

        let targetApp = NSWorkspace.shared.frontmostApplication?.processIdentifier

        lastError = nil
        isWorking = true
        let result = await llmClient.correctWritting(text: original)
        isWorking = false

        guard result.isSuccessful() else {
            let details = result.errorDetails.isEmpty ? "" : " — \(result.errorDetails.prefix(200))"
            return fail("\(result.error)\(details)")
        }

        if let problem = CorrectionGuard.problem(original: original, corrected: result.output, language: result.detectedLanguage) {
            return fail(problem)
        }

        // Keep the selection's own leading/trailing whitespace; models tend to trim it.
        let lead = String(original.prefix(while: { $0.isWhitespace }))
        let trail = String(String(original.reversed().prefix(while: { $0.isWhitespace })).reversed())
        let corrected = lead + result.output.trimmingCharacters(in: .whitespacesAndNewlines) + trail

        if corrected == original { return }  // nothing to fix

        // Never paste into the wrong place: the user may have moved on while the model was working.
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != targetApp {
            TextReplacer.copyToClipboard(corrected)
            return fail("You switched apps, so nothing was replaced. The correction is on your clipboard.")
        }
        let current = SelectionManager().getSelectedText()
        if current.isSuccessful() && current.output != original {
            TextReplacer.copyToClipboard(corrected)
            return fail("The selection changed, so nothing was replaced. The correction is on your clipboard.")
        }

        TextReplacer.replaceSelection(with: corrected)
    }

    @MainActor
    private func fail(_ message: String) {
        NSLog("TypoFix: \(message)")
        NSSound.beep()
        lastError = message

        errorClearTask?.cancel()
        errorClearTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if !Task.isCancelled { self?.lastError = nil }
        }
    }
}
