import SwiftUI
import AppKit

@main
struct TypoFixApp: App {
    @StateObject private var appState = AppState()
    @State var observer: NSKeyValueObservation?

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentUI(appState: appState)
                .onAppear {
                    observer = NSApplication.shared.observe(\.keyWindow) { x, y in
                        if NSApplication.shared.keyWindow != nil {
                            appState.checkPreconditions()
                        }
                    }
                }
        } label: {
            Image(systemName: appState.menuBarSymbol)
        }.menuBarExtraStyle(.window)
    }
}
