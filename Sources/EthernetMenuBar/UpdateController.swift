import Sparkle

@MainActor
final class UpdateController {
    private let settings: SettingsStore
    private let controller: SPUStandardUpdaterController

    init(settings: SettingsStore) {
        self.settings = settings
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        applySettings()
    }

    func applySettings() {
        controller.updater.automaticallyChecksForUpdates = settings.checksForUpdates
        controller.updater.automaticallyDownloadsUpdates = settings.checksForUpdates
    }

    func checkForUpdates(interactive: Bool) {
        if interactive {
            controller.checkForUpdates(nil)
        } else if settings.checksForUpdates {
            controller.updater.checkForUpdatesInBackground()
        }
    }
}
