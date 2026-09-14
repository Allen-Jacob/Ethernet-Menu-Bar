import AppKit
import Foundation

private struct GitHubRelease: Decodable, Sendable {
    struct Asset: Decodable, Sendable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let htmlURL: URL
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}

@MainActor
final class UpdateController {
    private let settings: SettingsStore
    private var timer: Timer?
    private var isChecking = false
    private let releasesURL = URL(string: "https://api.github.com/repos/Allen-Jacob/Ethernet-Menu-Bar/releases/latest")!

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func startAutomaticChecks() {
        guard settings.checksForUpdates else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            self?.checkForUpdates(interactive: false)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard self?.settings.checksForUpdates == true else { return }
                self?.checkForUpdates(interactive: false)
            }
        }
    }

    func checkForUpdates(interactive: Bool) {
        guard !isChecking else { return }
        isChecking = true

        Task { [weak self] in
            guard let self else { return }
            defer { isChecking = false }
            do {
                var request = URLRequest(url: releasesURL)
                request.setValue("EthernetMenuBar", forHTTPHeaderField: "User-Agent")
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                let localVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

                if remoteVersion.compare(localVersion, options: .numeric) == .orderedDescending {
                    presentAvailableUpdate(release, version: remoteVersion)
                } else if interactive {
                    presentUpToDate(version: localVersion)
                }
            } catch {
                if interactive { presentError(error) }
            }
        }
    }

    private func presentAvailableUpdate(_ release: GitHubRelease, version: String) {
        let alert = NSAlert()
        alert.messageText = "Ethernet Menu Bar \(version) est disponible"
        alert.informativeText = "La nouvelle version peut être téléchargée depuis GitHub."
        alert.addButton(withTitle: "Télécharger le DMG")
        alert.addButton(withTitle: "Plus tard")
        alert.addButton(withTitle: "Voir la Release")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn,
           let dmg = release.assets.first(where: { $0.name == "Ethernet-Menu-Bar.dmg" }) {
            downloadAndOpen(dmg)
        } else if response == .alertThirdButtonReturn {
            NSWorkspace.shared.open(release.htmlURL)
        }
    }

    private func downloadAndOpen(_ asset: GitHubRelease.Asset) {
        Task {
            do {
                let (temporaryURL, _) = try await URLSession.shared.download(from: asset.browserDownloadURL)
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(asset.name)
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: temporaryURL, to: destination)
                NSWorkspace.shared.open(destination)
            } catch {
                presentError(error)
            }
        }
    }

    private func presentUpToDate(version: String) {
        let alert = NSAlert()
        alert.messageText = "Ethernet Menu Bar est à jour"
        alert.informativeText = "Tu utilises actuellement la version \(version)."
        alert.runModal()
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "Impossible de vérifier les mises à jour"
        alert.informativeText = "Vérifie ta connexion Internet et réessaie."
        alert.runModal()
    }
}
