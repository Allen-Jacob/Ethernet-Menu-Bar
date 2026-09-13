import AppKit

enum StatusIcon {
    static func make(style: MenuBarIconStyle, isConnected: Bool) -> NSImage? {
        let description = isConnected ? "Ethernet connecté" : "Ethernet déconnecté"
        let symbol = NSImage(systemSymbolName: style.symbolName, accessibilityDescription: description)
        let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let image = symbol?.withSymbolConfiguration(configuration) ?? symbol
        image?.isTemplate = true
        return image
    }
}
