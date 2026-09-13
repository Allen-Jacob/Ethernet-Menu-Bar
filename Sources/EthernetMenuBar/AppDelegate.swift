import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let detector = EthernetDetector()
    private let settings = SettingsStore()
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var settingsWindow: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.onChange = { [weak self] in
            self?.scheduleTimer()
            self?.refresh()
        }
        refresh()
        scheduleTimer()
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
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
            return
        }

        let item = statusItem ?? makeStatusItem()
        let speedLabel = connection?.speedLabel ?? "—"
        item.button?.image = StatusIcon.make(
            style: settings.iconStyle,
            speedLabel: speedLabel,
            showsSpeed: settings.showsSpeed,
            isConnected: connection != nil
        )
        item.button?.toolTip = connection.map { "Ethernet \($0.speedLabel) — \($0.interfaceName)" } ?? "Ethernet déconnecté — mode test"
        rebuildMenu(for: item, connection: connection)
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: 30)
        item.button?.imagePosition = .imageOnly
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
        let quit = NSMenuItem(title: "Quitter Ethernet Menu Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        item.menu = menu
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(settings: settings)))
            window.title = "Réglages — Ethernet Menu Bar"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = NSWindowController(window: window)
        }
        settingsWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
