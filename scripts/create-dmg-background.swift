#!/usr/bin/env swift

import AppKit

let logicalSize = NSSize(width: 660, height: 413)
let scale: CGFloat = 2
let pixelSize = NSSize(width: logicalSize.width * scale, height: logicalSize.height * scale)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(pixelSize.width),
    pixelsHigh: Int(pixelSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to create the DMG background bitmap")
}
bitmap.size = pixelSize

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to create the DMG background graphics context")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext
defer { NSGraphicsContext.restoreGraphicsState() }

NSColor(calibratedWhite: 0.965, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: pixelSize)).fill()

let heading = "Drag the app to Applications" as NSString
let headingStyle = NSMutableParagraphStyle()
headingStyle.alignment = .center
let headingAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 34, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.08, alpha: 1),
    .paragraphStyle: headingStyle
]
heading.draw(
    in: NSRect(x: 0, y: 650, width: pixelSize.width, height: 52),
    withAttributes: headingAttributes
)

let arrow = NSBezierPath()
arrow.lineWidth = 8
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: 540, y: 412))
arrow.line(to: NSPoint(x: 780, y: 412))
arrow.move(to: NSPoint(x: 738, y: 370))
arrow.line(to: NSPoint(x: 780, y: 412))
arrow.line(to: NSPoint(x: 738, y: 454))
NSColor(calibratedWhite: 0.08, alpha: 1).setStroke()
arrow.stroke()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to render the DMG background")
}

let projectDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let destination = projectDirectory.appendingPathComponent("App/DMG/background.png")
try png.write(to: destination)
print(destination.path)
