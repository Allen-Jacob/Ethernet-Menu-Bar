import Foundation
import ServiceManagement

enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case network
    case cable
    case arrows

    var id: String { rawValue }

    var title: String {
        switch self {
        case .network: "Réseau"
        case .cable: "Câble"
        case .arrows: "Transfert"
        }
    }

    var symbolName: String {
        switch self {
        case .network: "network"
        case .cable: "cable.connector.horizontal"
        case .arrows: "arrow.left.arrow.right"
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let iconStyle = "iconStyle"
        static let showsSpeed = "showsSpeed"
        static let refreshInterval = "refreshInterval"
        static let keepVisible = "keepVisible"
        static let onboardingCompleted = "onboardingCompleted"
    }

    private let defaults: UserDefaults
    var onChange: (() -> Void)?

    @Published var iconStyle: MenuBarIconStyle {
        didSet { defaults.set(iconStyle.rawValue, forKey: Key.iconStyle); onChange?() }
    }
    @Published var showsSpeed: Bool {
        didSet { defaults.set(showsSpeed, forKey: Key.showsSpeed); onChange?() }
    }
    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: Key.refreshInterval); onChange?() }
    }
    @Published var keepVisible: Bool {
        didSet { defaults.set(keepVisible, forKey: Key.keepVisible); onChange?() }
    }
    @Published private(set) var launchAtLogin: Bool
    @Published var launchAtLoginError: String?

    var onboardingCompleted: Bool { defaults.bool(forKey: Key.onboardingCompleted) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        iconStyle = MenuBarIconStyle(rawValue: defaults.string(forKey: Key.iconStyle) ?? "") ?? .network
        showsSpeed = defaults.object(forKey: Key.showsSpeed) as? Bool ?? true
        refreshInterval = defaults.object(forKey: Key.refreshInterval) as? Double ?? 2
        keepVisible = defaults.bool(forKey: Key.keepVisible)
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            launchAtLoginError = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginError = "Impossible de modifier le démarrage automatique. Place d’abord l’app dans Applications."
        }
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Key.onboardingCompleted)
    }
}
