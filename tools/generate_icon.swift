// Generates Sources/Matiz/Resources/Matiz.icns.
//
// Run with:  swift tools/generate_icon.swift
//
// The icon is drawn with CoreGraphics rather than kept as a binary asset so it can
// be tweaked and regenerated (no Xcode / asset catalog needed). Design: three
// overlapping speech bubbles in tints of one hue — "matiz" is Spanish for shade or
// nuance, which is what the app produces.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Geometry helpers

/// Apple-style continuous rounded square ("squircle"), sampled from a superellipse.
func squirclePath(rect: CGRect, exponent: Double = 5) -> CGPath {
    let path = CGMutablePath()
    let a = rect.width / 2, b = rect.height / 2
    let cx = rect.midX, cy = rect.midY
    let steps = 720
    for i in 0...steps {
        let t = 2 * Double.pi * Double(i) / Double(steps)
        let c = cos(t), s = sin(t)
        let x = cx + a * copysign(pow(abs(c), 2 / exponent), c)
        let y = cy + b * copysign(pow(abs(s), 2 / exponent), s)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

/// A speech bubble: rounded rect with a tail at the bottom-left, rotated slightly.
func bubblePath(rect: CGRect, radius: CGFloat, tail: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)

    // Tail: a wedge hanging off the bottom-left, wide where it meets the bubble and
    // rounded at the tip so it stays solid at small sizes.
    // The base sits inside the bubble so the two shapes merge without a seam, and
    // stays clear of the rounded corner so it doesn't bulge out of the left edge.
    let tailPath = CGMutablePath()
    let base = rect.minY + tail * 0.2
    let tip = CGPoint(x: rect.minX + tail * 0.35, y: rect.minY - tail)
    tailPath.move(to: CGPoint(x: rect.minX + radius * 2.4, y: base))
    tailPath.addLine(to: CGPoint(x: rect.minX + radius * 0.5, y: base))
    tailPath.addQuadCurve(
        to: tip, control: CGPoint(x: rect.minX + tail * 0.42, y: rect.minY - tail * 0.6))
    tailPath.closeSubpath()
    path.addPath(tailPath)
    return path
}

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha)
}

// MARK: - Drawing

/// Draws the icon into a 1024×1024 coordinate space (origin bottom-left).
func drawIcon(in ctx: CGContext) {
    let space = CGColorSpaceCreateDeviceRGB()

    // macOS icons sit on a 1024 canvas with the body inset — leaves room for the
    // shadow and matches the size of stock app icons in the Dock.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = squirclePath(rect: body)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 26, color: rgb(0x000000, 0.30))
    ctx.addPath(shape)
    ctx.setFillColor(rgb(0x4B4BD8))
    ctx.fillPath()
    ctx.restoreGState()

    // Background gradient: indigo → violet, top to bottom.
    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    let bg = CGGradient(
        colorsSpace: space,
        colors: [rgb(0x5A6BFF), rgb(0x7A3FE4), rgb(0x5D24B8)] as CFArray,
        locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(
        bg, start: CGPoint(x: body.minX, y: body.maxY), end: CGPoint(x: body.maxX, y: body.minY),
        options: [])

    // Soft highlight in the top-left, the way light falls on stock icons.
    let glow = CGGradient(
        colorsSpace: space, colors: [rgb(0xFFFFFF, 0.28), rgb(0xFFFFFF, 0)] as CFArray,
        locations: [0, 1])!
    ctx.drawRadialGradient(
        glow, startCenter: CGPoint(x: body.minX + 210, y: body.maxY - 120), startRadius: 0,
        endCenter: CGPoint(x: body.minX + 210, y: body.maxY - 120), endRadius: 620, options: [])
    ctx.restoreGState()

    // Three bubbles, back to front, in increasing tints — the "shades" of a phrase.
    // Each is drawn rotated a little so they read as a stack, not a blur.
    let front = CGRect(x: 216, y: 330, width: 480, height: 296)
    let bubbles: [(rect: CGRect, angle: CGFloat, color: CGColor)] = [
        (front.offsetBy(dx: 120, dy: 128), 0.0, rgb(0xFFFFFF, 0.26)),
        (front.offsetBy(dx: 60, dy: 64), 0.0, rgb(0xFFFFFF, 0.48)),
        (front, 0.0, rgb(0xFFFFFF, 1.0)),
    ]
    for bubble in bubbles {
        ctx.saveGState()
        let center = CGPoint(x: bubble.rect.midX, y: bubble.rect.midY)
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: bubble.angle)
        ctx.translateBy(x: -center.x, y: -center.y)
        ctx.addPath(bubblePath(rect: bubble.rect, radius: 74, tail: 78))
        ctx.setFillColor(bubble.color)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // Two bars inside the front bubble suggest lines of text without becoming mush
    // at 16pt. They're tinted with the background hue so they read as a cut-out.
    ctx.saveGState()
    ctx.setFillColor(rgb(0x6A34D6, 0.92))
    for (index, width) in [CGFloat(300), CGFloat(196)].enumerated() {
        let y = front.midY + (index == 0 ? 26 : -72)
        let bar = CGRect(x: front.minX + 78, y: y, width: width, height: 46)
        ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 23, cornerHeight: 23, transform: nil))
    }
    ctx.fillPath()
    ctx.restoreGState()
}

// MARK: - Output

func renderPNG(size: Int, to url: URL) {
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    let scale = CGFloat(size) / 1024
    ctx.scaleBy(x: scale, y: scale)
    drawIcon(in: ctx)

    let image = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("failed to write \(url.path)") }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/Matiz.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

// The sizes `iconutil` expects in an .iconset.
let variants: [(name: String, size: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for variant in variants {
    renderPNG(size: variant.size, to: iconset.appendingPathComponent("\(variant.name).png"))
}

let resources = root.appendingPathComponent("Sources/Matiz/Resources")
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = [
    "-c", "icns", iconset.path, "-o", resources.appendingPathComponent("Matiz.icns").path,
]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { exit(iconutil.terminationStatus) }

print("wrote \(resources.appendingPathComponent("Matiz.icns").path)")
