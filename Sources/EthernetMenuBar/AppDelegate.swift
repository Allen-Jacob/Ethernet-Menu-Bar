import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let detector = EthernetDetector()
    private let settings = SettingsStore()
    private lazy var updater = UpdateController(settings: settings)
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var settingsWindow: NSWindowController?
    private var onboardingWindow: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.onChange = { [weak self] in
            self?.scheduleTimer()
            self?.refresh()
        }
        refresh()
        scheduleTimer()
        let presentedOnboarding = presentOnboardingIfNeeded()
        updater.startAutomaticChecks()

        // With no Ethernet link the status item is intentionally invisible, so a
        // direct launch from Spotlight/Finder must still expose the settings.
        if !presentedOnboarding {
            DispatchQueue.main.async { [weak self] in
                self?.showSettings()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func refresh() {
        let connection = detector.activeConnection()

        guard connection != nil || settings.keepVisible else {
            statusItem?.isVisible = false
            return
        }

        let item = statusItem ?? makeStatusItem()
        item.isVisible = true
        let speedLabel = connection?.speedLabel ?? "—"
        item.button?.image = StatusIcon.make(
            style: settings.iconStyle,
            isConnected: connection != nil
        )
        item.button?.title = settings.showsSpeed ? " \(speedLabel)" : ""
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
        item.button?.imagePosition = settings.showsSpeed ? .imageLeading : .imageOnly
        item.button?.toolTip = connection.map { "Ethernet \($0.speedLabel) — \($0.interfaceName)" } ?? "Ethernet déconnecté — mode test"
        rebuildMenu(for: item, connection: connection)
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        return item
    }

    private func rebuildMenu(for item: NSStatusItem, connection: EthernetConnection?) {
        let menu = NSMenu()
        let summary = NSMenuItem(
            title: connection.map { "Ethernet connecté — \($0.speedLabel)" } ?? "Ethernet déconnecté",
            action: nil,
            keyEquivalent: ""
        )
        summary.isEnabled = false
        menu.addItem(summary)
        if let connection {
            let interface = NSMenuItem(title: "Interface : \(connection.interfaceName)", action: nil, keyEquivalent: "")
            interface.isEnabled = false
            menu.addItem(interface)
        }
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Réglages…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        let updateItem = NSMenuItem(title: "Rechercher les mises à jour…", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        let quit = NSMenuItem(title: "Quitter Ethernet Menu Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        item.menu = menu
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView(
                settings: settings,
                checkForUpdates: { [weak self] in self?.updater.checkForUpdates(interactive: true) },
                showAbout: { [weak self] in self?.showAbout() },
                uninstall: { [weak self] in self?.confirmUninstall() }
            )
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Réglages — Ethernet Menu Bar"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = NSWindowController(window: window)
        }
        settingsWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func checkForUpdates() {
        updater.checkForUpdates(interactive: true)
    }

    private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func confirmUninstall() {
        let alert = NSAlert()
        alert.messageText = "Désinstaller Ethernet Menu Bar?"
        alert.informativeText = "L’application sera déplacée dans la corbeille et ne démarrera plus avec ton Mac."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Désinstaller")
        alert.addButton(withTitle: "Annuler")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        settings.setLaunchAtLogin(false)
        do {
            try FileManager.default.trashItem(at: Bundle.main.bundleURL, resultingItemURL: nil)
            NSApp.terminate(nil)
        } catch {
            let failure = NSAlert(error: error)
            failure.messageText = "Impossible de désinstaller l’application"
            failure.runModal()
        }
    }

    @discardableResult
    private func presentOnboardingIfNeeded() -> Bool {
        let isInstalled = Bundle.main.bundleURL.path.hasPrefix("/Applications/")
        guard !settings.onboardingCompleted || !isInstalled else { return false }

        let view = OnboardingView(settings: settings, isInstalled: isInstalled) { [weak self] in
            self?.settings.completeOnboarding()
            self?.onboardingWindow?.close()
        }
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Bienvenue — Ethernet Menu Bar"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        onboardingWindow = NSWindowController(window: window)
        onboardingWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
}
