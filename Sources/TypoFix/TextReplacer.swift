import AppKit
import Carbon.HIToolbox

/// Replaces the current selection in the frontmost app by pasting over it.
/// The corrected text is also left on the clipboard, so a failed paste can be redone with ⌘V.
enum TextReplacer {
    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    static func replaceSelection(with text: String) {
        copyToClipboard(text)
        pasteFromClipboard()
    }

    /// Posts a synthetic ⌘V. Requires the same Accessibility permission the app already needs.
    private static func pasteFromClipboard() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let key = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
