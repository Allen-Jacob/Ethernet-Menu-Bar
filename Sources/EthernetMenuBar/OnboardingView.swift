import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: SettingsStore
    let isInstalled: Bool
    let finish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: isInstalled ? "checkmark.circle.fill" : "arrow.down.app.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(isInstalled ? Color.green : Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isInstalled ? "Installation réussie" : "Installer Ethernet Menu Bar")
                        .font(.title2.bold())
                    Text(isInstalled
                         ? "L’app est au bon endroit et peut démarrer avec ton Mac."
                         : "Glisse l’app dans le dossier Applications avant de l’utiliser.")
                        .foregroundStyle(.secondary)
                }
            }

            if isInstalled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(
                            "Ouvrir automatiquement à la connexion",
                            isOn: Binding(
                                get: { settings.launchAtLogin },
                                set: { settings.setLaunchAtLogin($0) }
                            )
                        )
                        Text("Tu pourras modifier ce choix plus tard dans Réglages.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let error = settings.launchAtLoginError {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(6)
                }

                HStack {
                    Spacer()
                    Button("Commencer") { finish() }
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Label("1. Ouvre le dossier contenant Ethernet Menu Bar.", systemImage: "1.circle.fill")
                    Label("2. Glisse l’app sur le dossier Applications.", systemImage: "2.circle.fill")
                    Label("3. Ouvre ensuite la copie placée dans Applications.", systemImage: "3.circle.fill")
                }

                HStack {
                    Button("Afficher cette app") {
                        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                    }
                    Button("Ouvrir Applications") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications", isDirectory: true))
                    }
                    Spacer()
                    Button("Quitter") { NSApp.terminate(nil) }
                }
            }
        }
        .padding(24)
        .frame(width: 510)
    }
}
