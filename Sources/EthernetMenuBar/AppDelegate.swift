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
    private var trafficMeter = NetworkTrafficMeter()
    private var traffic = NetworkTraffic.zero

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.onChange = { [weak self] in
            self?.scheduleTimer()
            self?.refresh()
            self?.updater.applySettings()
        }
        refresh()
        scheduleTimer()
        let presentedOnboarding = presentOnboardingIfNeeded()

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
        let item = statusItem ?? makeStatusItem()

        if let connection {
            traffic = trafficMeter.sample(interface: connection.interfaceName)
        } else {
            trafficMeter.reset()
            traffic = .zero
        }

        guard connection != nil || settings.keepVisible else {
            // Keep the exact same NSStatusItem registered so macOS and Ice retain
            // its ordering. A zero width makes it visually disappear without a
            // hide/show cycle that would reinsert it at the end of the menu bar.
            item.button?.image = nil
            item.button?.title = ""
            item.button?.toolTip = nil
            item.button?.imagePosition = .imageOnly
            item.menu = nil
            item.length = 0
            return
        }

        let speedLabel = connection?.speedLabel ?? "—"
        item.button?.image = StatusIcon.make(
            style: settings.iconStyle,
            isConnected: connection != nil
        )
        // Let macOS choose black or white for the current menu-bar appearance.
        // A forced white tint becomes invisible on a light menu bar.
        item.button?.contentTintColor = connection == nil ? .secondaryLabelColor : nil
        // A thin space keeps the speed legible without making the status item
        // noticeably wider. The lighter 9 pt label leaves the icon dominant.
        item.button?.title = settings.showsSpeed ? "\u{2009}\(speedLabel)" : ""
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)
        item.button?.imagePosition = settings.showsSpeed ? .imageLeading : .imageOnly
        item.button?.imageHugsTitle = false
        item.button?.toolTip = connection.map { "Ethernet \($0.speedLabel) — \($0.interfaceName)" } ?? "Ethernet déconnecté — affichage permanent"
        item.length = compactLength(for: item.button)
        rebuildMenu(for: item, connection: connection)
    }

    private func compactLength(for button: NSStatusBarButton?) -> CGFloat {
        guard let button else { return NSStatusItem.variableLength }
        return max(18, ceil(button.fittingSize.width) - 3)
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "ca.jacoballen.EthernetMenuBar.statusItem"
        item.isVisible = true
        statusItem = item
        return item
    }

    private func rebuildMenu(for item: NSStatusItem, connection: EthernetConnection?) {
        let menu = NSMenu()
        let summary = NSMenuItem(
            title: connection == nil ? "Ethernet : Déconnecté" : "Ethernet : Connecté",
            action: nil,
            keyEquivalent: ""
        )
        summary.isEnabled = false
        menu.addItem(summary)

        let speed = NSMenuItem(
            title: "Débit : \(TrafficFormatter.string(bytesPerSecond: traffic.downloadBytesPerSecond)) ↓  |  \(TrafficFormatter.string(bytesPerSecond: traffic.uploadBytesPerSecond)) ↑",
            action: nil,
            keyEquivalent: ""
        )
        speed.isEnabled = false
        menu.addItem(speed)

        menu.addItem(.separator())
        let networkSettingsItem = NSMenuItem(
            title: "Ouvrir les réglages réseau…",
            action: #selector(openNetworkSettings),
            keyEquivalent: "n"
        )
        networkSettingsItem.keyEquivalentModifierMask = [.command]
        networkSettingsItem.target = self
        menu.addItem(networkSettingsItem)

        let settingsItem = NSMenuItem(title: "Réglages…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quitter Ethernet Menu Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        item.menu = menu
    }

    @objc private func openNetworkSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
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
