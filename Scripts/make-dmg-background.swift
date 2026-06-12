#!/usr/bin/env swift
//
// make-dmg-background.swift
//
// Generates the background image used by the installer DMG. The image shows
// an arrow pointing from the app icon's slot toward the /Applications alias slot.
//
// Window size: 540 × 380. Icon centers (set in release.sh's AppleScript):
//   - WifiManager.app at (140, 200)
//   - Applications alias at (400, 200)
//
// Usage: ./Scripts/make-dmg-background.swift <output.png>

import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-dmg-background.swift <output.png>\n".utf8))
    exit(64)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])

let width: CGFloat = 540
let height: CGFloat = 380
let arrowYFinder: CGFloat = 200
let arrowY: CGFloat = height - arrowYFinder
let arrowStartX: CGFloat = 200
let arrowEndX: CGFloat = 340
let arrowHeadSize: CGFloat = 14
let strokeColor = NSColor(white: 0.55, alpha: 1.0)

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

NSColor.white.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

let shaft = NSBezierPath()
shaft.move(to: NSPoint(x: arrowStartX, y: arrowY))
shaft.line(to: NSPoint(x: arrowEndX - arrowHeadSize * 0.6, y: arrowY))
shaft.lineWidth = 3
shaft.lineCapStyle = .round
strokeColor.setStroke()
shaft.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: arrowEndX, y: arrowY))
head.line(to: NSPoint(x: arrowEndX - arrowHeadSize, y: arrowY - arrowHeadSize * 0.55))
head.line(to: NSPoint(x: arrowEndX - arrowHeadSize, y: arrowY + arrowHeadSize * 0.55))
head.close()
strokeColor.setFill()
head.fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to encode PNG\n".utf8))
    exit(1)
}

try png.write(to: output)
print("✓ wrote \(output.path) (\(Int(width))x\(Int(height)))")
