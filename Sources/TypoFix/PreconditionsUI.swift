import SwiftUI

struct PreconditionsUI: View {
    @StateObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading) {
            if !appState.showSettingsUI {
                if !appState.openAIKeySetUp {
                    Text("Please enter your API key in Settings")
                        .foregroundStyle(.red)
                        .padding([.bottom], 10)
                }

                if !appState.accessibilityAPIPermissionSetUp {
                    Text("Please add TypoFix access to Accessibility API")
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
