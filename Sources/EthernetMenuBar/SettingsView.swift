import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let checkForUpdates: () -> Void
    let showAbout: () -> Void
    let uninstall: () -> Void

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
                            Label {
                                Text(style.title)
                            } icon: {
                                Image(nsImage: StatusIcon.make(style: style, isConnected: true) ?? NSImage())
                            }
                            .tag(style)
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

                    Picker("Toujours actif", selection: $settings.keepVisible) {
                        Text("Oui").tag(true)
                        Text("Non").tag(false)
                    }
                    .pickerStyle(.segmented)

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

            GroupBox("Mises à jour") {
                HStack {
                    Toggle("Rechercher automatiquement les nouvelles versions", isOn: $settings.checksForUpdates)
                    Spacer()
                    Button("Vérifier maintenant", action: checkForUpdates)
                }
                .padding(8)
            }

            HStack {
                Link(destination: URL(string: "https://jacoballen.ca")!) {
                    Label("Site web", systemImage: "globe")
                }
                Link(destination: URL(string: "https://jacoballen.ca/projects")!) {
                    Label("Page du projet", systemImage: "network")
                }
                Button("À propos d’Ethernet Menu Bar", action: showAbout)
                Spacer()
                Button("Désinstaller…", role: .destructive, action: uninstall)
                Button("Terminé") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 640)
    }
}
