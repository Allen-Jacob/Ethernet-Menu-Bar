import AppKit

enum StatusIcon {
    static func make(
        style: MenuBarIconStyle,
        speedLabel: String,
        showsSpeed: Bool,
        isConnected: Bool
    ) -> NSImage {
        let size = NSSize(width: 28, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let symbol = NSImage(
                systemSymbolName: style.symbolName,
                accessibilityDescription: isConnected ? "Ethernet connecté" : "Ethernet déconnecté"
            ) else {
                return false
            }

            let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let configured = symbol.withSymbolConfiguration(configuration) ?? symbol
            let iconY: CGFloat = showsSpeed ? 8 : 4
            configured.draw(in: NSRect(x: 7, y: iconY, width: 14, height: 14))

            if showsSpeed {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 7, weight: .semibold),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraph
                ]
                speedLabel.draw(in: NSRect(x: 0, y: 0, width: rect.width, height: 8), withAttributes: attributes)
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = isConnected ? "Ethernet connecté à \(speedLabel)" : "Ethernet déconnecté"
        return image
    }
}
