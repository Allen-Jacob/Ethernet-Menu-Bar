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
        let image = NSImage(size: NSSize(width: 19, height: 15), flipped: false) { _ in
            NSColor.black.setStroke()

            // The reference Windows glyph has the RJ45 plug on the upper-left
            // and the display on the right. Keep the geometry on half-pixels so
            // the template remains crisp on both Retina and non-Retina screens.
            let screen = NSBezierPath(
                roundedRect: NSRect(x: 7.25, y: 4.25, width: 10.5, height: 8.5),
                xRadius: 0.9,
                yRadius: 0.9
            )
            screen.lineWidth = 1.5
            screen.stroke()

            let details = NSBezierPath()
            details.lineWidth = 1.5
            details.lineCapStyle = .round
            details.lineJoinStyle = .round

            // Plug stem and short cable, followed by the monitor stand.
            details.move(to: NSPoint(x: 3.75, y: 10.25))
            details.line(to: NSPoint(x: 3.75, y: 2.25))
            details.line(to: NSPoint(x: 7.25, y: 2.25))
            details.move(to: NSPoint(x: 12.5, y: 4.25))
            details.line(to: NSPoint(x: 12.5, y: 2.25))
            details.move(to: NSPoint(x: 9.75, y: 1.75))
            details.line(to: NSPoint(x: 15.25, y: 1.75))
            details.stroke()

            let plug = NSBezierPath(
                roundedRect: NSRect(x: 1.25, y: 10.25, width: 5, height: 4),
                xRadius: 0.45,
                yRadius: 0.45
            )
            plug.lineWidth = 1.5
            plug.stroke()

            let contacts = NSBezierPath()
            contacts.lineWidth = 1.2
            contacts.move(to: NSPoint(x: 2.75, y: 13.75))
            contacts.line(to: NSPoint(x: 2.75, y: 12.25))
            contacts.move(to: NSPoint(x: 4.75, y: 13.75))
            contacts.line(to: NSPoint(x: 4.75, y: 12.25))
            contacts.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }
}
