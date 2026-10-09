import SwiftUI

struct MenuBarContentUI: View {
    @StateObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("TypoFix")
                Text("\(getAppVersion())")
                    .foregroundColor(.gray)
            }
            Divider().padding([.bottom], 10)

            PreconditionsUI(appState: appState)

            if let error = appState.lastError {
                Text(error)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding([.bottom], 10)
            }

            SettingsUI(appState: appState)

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }.padding()
        .onAppear { appState.checkPreconditions() }
    }

    func getAppVersion() -> String {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return "Unknown"
    }
}
