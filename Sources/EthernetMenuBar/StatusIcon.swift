import AppKit

enum StatusIcon {
    static func make(style: MenuBarIconStyle, isConnected: Bool) -> NSImage? {
        let description = isConnected ? "Ethernet connecté" : "Ethernet déconnecté"

        if style == .windowsEthernet {
            return makeWindowsEthernetIcon(accessibilityDescription: description)
        }

        let symbol = NSImage(systemSymbolName: style.symbolName, accessibilityDescription: description)
        let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let image = symbol?.withSymbolConfiguration(configuration) ?? symbol
        image?.isTemplate = true
        return image
    }

    /// A compact monitor-and-plug glyph based on the wired-network indicator
    /// used by Windows. Drawing it locally keeps it sharp at menu-bar scale.
    private static func makeWindowsEthernetIcon(accessibilityDescription: String) -> NSImage {
        let image = NSImage(size: NSSize(width: 17, height: 14), flipped: false) { _ in
            NSColor.black.setStroke()

            let screen = NSBezierPath(roundedRect: NSRect(x: 0.75, y: 4.25, width: 9.5, height: 7.5), xRadius: 0.8, yRadius: 0.8)
            screen.lineWidth = 1.5
            screen.stroke()

            let details = NSBezierPath()
            details.lineWidth = 1.5
            details.lineCapStyle = .round
            details.lineJoinStyle = .round

            // Monitor stand, then the cable leading to an RJ45-like plug.
            details.move(to: NSPoint(x: 5.5, y: 4.25))
            details.line(to: NSPoint(x: 5.5, y: 2.25))
            details.move(to: NSPoint(x: 3.25, y: 1.75))
            details.line(to: NSPoint(x: 7.75, y: 1.75))
            details.move(to: NSPoint(x: 10.25, y: 7.5))
            details.line(to: NSPoint(x: 12.25, y: 7.5))
            details.line(to: NSPoint(x: 12.25, y: 4.75))
            details.line(to: NSPoint(x: 14.75, y: 4.75))
            details.stroke()

            let plug = NSBezierPath(roundedRect: NSRect(x: 13.25, y: 4, width: 3, height: 3), xRadius: 0.45, yRadius: 0.45)
            plug.lineWidth = 1.5
            plug.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }
}
