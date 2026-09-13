import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ethernet Menu Bar")
                    .font(.title2.bold())
                Text("Personnalise l’indicateur de ta connexion filaire.")
                    .foregroundStyle(.secondary)
            }

            GroupBox("Apparence") {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Icône", selection: $settings.iconStyle) {
                        ForEach(MenuBarIconStyle.allCases) { style in
                            Label(style.title, systemImage: style.symbolName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Afficher la vitesse négociée sous l’icône", isOn: $settings.showsSpeed)
                }
                .padding(8)
            }

            GroupBox("Comportement") {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Vérifier la connexion", selection: $settings.refreshInterval) {
                        Text("Chaque seconde").tag(1.0)
                        Text("Toutes les 2 secondes").tag(2.0)
                        Text("Toutes les 5 secondes").tag(5.0)
                    }

                    Toggle("Toujours afficher l’icône (mode test)", isOn: $settings.keepVisible)

                    Toggle(
                        "Ouvrir automatiquement à la connexion",
                        isOn: Binding(
                            get: { settings.launchAtLogin },
                            set: { settings.setLaunchAtLogin($0) }
                        )
                    )

                    if let error = settings.launchAtLoginError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(8)
            }

            HStack {
                Label("Les réglages sont enregistrés automatiquement.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Terminé") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 500)
    }
}
