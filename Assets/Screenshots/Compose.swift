// Composes App Store screenshots from raw captures: a gradient background, a caption, a device frame
// around the capture, and optional callouts that point at parts of the screen.
//
// Usage: swift Compose.swift [Screenshots.json] [platform...]
// Paths in the layout file are relative to it. Output goes to Output/<platform>/<scene>.png.

import AppKit

// MARK: - Layout file

struct Layout: Decodable {
    var background: [String]
    var titleFont: String
    var subtitleFont: String
    var platforms: [String: Platform]
}

struct Platform: Decodable {
    var canvas: [CGFloat]
    var device: Device
    /// Where the device sits, as fractions of the canvas: its width, and the top of its frame.
    var deviceWidth: CGFloat
    var deviceTop: CGFloat
    var titleTop: CGFloat
    var titleSize: CGFloat
    var subtitleSize: CGFloat
    /// Fades the bottom of the canvas to black from this fraction of its height down, for devices cut off there.
    var fadeFrom: CGFloat?
    var scenes: [Scene]
}

struct Device: Decodable {
    /// "iPhone", "iPad", or "window" for a Mac window, which is drawn as captured with a shadow.
    var kind: String
    var screenCornerRadius: CGFloat
    var bezel: CGFloat
}

struct Scene: Decodable {
    var name: String
    var capture: String
    var title: String
    var subtitle: String
    var deviceWidth: CGFloat?
    var deviceTop: CGFloat?
    var fadeFrom: CGFloat?
    var callout: Callout?
}

/// A file name in a box, with parts of it highlighted, and arrows from those parts to points on the screen.
struct Callout: Decodable {
    struct Segment: Decodable {
        var text: String
        var color: String?
    }
    struct Arrow: Decodable {
        /// The highlighted segment the arrow leaves from.
        var segment: Int
        /// "bottom", "left", or "right" of the segment.
        var edge: String
        /// Bends and the end point, in capture pixels. A bend that leaves out x or y keeps the previous one,
        /// so arrows run straight across and down.
        var points: [Point]
    }
    struct Point: Decodable {
        var x: CGFloat?
        var y: CGFloat?
    }
    var segments: [Segment]
    /// The box's center, as fractions of the canvas.
    var center: [CGFloat]
    var fontSize: CGFloat
    var arrows: [Arrow]
}

// MARK: - Drawing helpers

extension NSColor {
    convenience init(hex: String) {
        var string = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if string.count == 6 { string += "FF" }
        let value = UInt64(string, radix: 16) ?? 0
        self.init(srgbRed: CGFloat((value >> 24) & 0xFF) / 255, green: CGFloat((value >> 16) & 0xFF) / 255,
                  blue: CGFloat((value >> 8) & 0xFF) / 255, alpha: CGFloat(value & 0xFF) / 255)
    }
}

func roundedRect(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: min(radius, rect.width / 2), cornerHeight: min(radius, rect.height / 2),
           transform: nil)
}

/// Draws text centered on a line, with its top at y, and returns its height.
@discardableResult
func drawCentered(_ text: String, font: NSFont, color: NSColor, centerX: CGFloat, top: CGFloat,
                  maxWidth: CGFloat) -> CGFloat {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color,
                                                               .paragraphStyle: paragraph])
    let bounds = string.boundingRect(with: CGSize(width: maxWidth, height: 10_000), options: [.usesLineFragmentOrigin])
    string.draw(with: CGRect(x: centerX - maxWidth / 2, y: top, width: maxWidth, height: ceil(bounds.height)),
                options: [.usesLineFragmentOrigin])
    return ceil(bounds.height)
}

// MARK: - Devices

/// The frame of a device around a screen of a given size, in the same units.
struct Frame {
    var device: Device
    var screen: CGSize

    var outer: CGSize {
        CGSize(width: screen.width + device.bezel * 2, height: screen.height + device.bezel * 2)
    }

    var outerRadius: CGFloat {
        device.screenCornerRadius + device.bezel
    }

    /// Draws the hardware, with the screen drawn into its hole, in a rect the size of `outer`.
    func draw(in context: CGContext, at origin: CGPoint, scale: CGFloat, screenImage: CGImage) {
        let outerRect = CGRect(origin: origin, size: CGSize(width: outer.width * scale, height: outer.height * scale))
        let bezel = device.bezel * scale
        let screenRect = outerRect.insetBy(dx: bezel, dy: bezel)
        let screenRadius = device.screenCornerRadius * scale

        // Side buttons sit just outside the frame, under it
        context.setFillColor(NSColor(hex: "#3A3A3F").cgColor)
        for button in buttons(in: outerRect, scale: scale) {
            context.addPath(roundedRect(button, 3 * scale))
            context.fillPath()
        }

        // Soft shadow, then the metal edge and the black glass around the screen
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 30 * scale), blur: 90 * scale,
                          color: NSColor.black.withAlphaComponent(0.45).cgColor)
        context.addPath(roundedRect(outerRect, outerRadius * scale))
        context.setFillColor(NSColor(hex: "#5A5A60").cgColor)
        context.fillPath()
        context.restoreGState()

        let metal = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                               colors: [NSColor(hex: "#8E8E94").cgColor, NSColor(hex: "#3C3C41").cgColor,
                                        NSColor(hex: "#77777D").cgColor] as CFArray,
                               locations: [0, 0.5, 1])!
        context.saveGState()
        context.addPath(roundedRect(outerRect, outerRadius * scale))
        context.clip()
        context.drawLinearGradient(metal, start: outerRect.origin,
                                   end: CGPoint(x: outerRect.maxX, y: outerRect.maxY), options: [])
        context.restoreGState()

        let edge = max(3, bezel * 0.16)
        let glassRect = outerRect.insetBy(dx: edge, dy: edge)
        context.addPath(roundedRect(glassRect, outerRadius * scale - edge))
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()

        // The screen
        context.saveGState()
        context.addPath(roundedRect(screenRect, screenRadius))
        context.clip()
        context.interpolationQuality = .high
        drawImage(screenImage, in: screenRect, context: context)
        context.restoreGState()

        // The Dynamic Island over the status bar
        if device.kind == "iPhone" {
            let island = CGSize(width: screenRect.width * 0.285, height: screenRect.width * 0.085)
            let islandRect = CGRect(x: screenRect.midX - island.width / 2, y: screenRect.minY + screenRect.width * 0.026,
                                    width: island.width, height: island.height)
            context.addPath(roundedRect(islandRect, island.height / 2))
            context.setFillColor(NSColor.black.cgColor)
            context.fillPath()
        }
    }

    private func buttons(in rect: CGRect, scale: CGFloat) -> [CGRect] {
        let depth = 7 * scale
        func left(_ top: CGFloat, _ length: CGFloat) -> CGRect {
            CGRect(x: rect.minX - depth, y: rect.minY + rect.height * top, width: depth * 2, height: rect.height * length)
        }
        func right(_ top: CGFloat, _ length: CGFloat) -> CGRect {
            CGRect(x: rect.maxX - depth, y: rect.minY + rect.height * top, width: depth * 2, height: rect.height * length)
        }
        func topEdge(_ left: CGFloat, _ length: CGFloat) -> CGRect {
            CGRect(x: rect.minX + rect.width * left, y: rect.minY - depth, width: rect.width * length, height: depth * 2)
        }
        switch device.kind {
        case "iPhone":
            // Action button, volume, side button, and Camera Control
            return [left(0.175, 0.045), left(0.255, 0.075), left(0.35, 0.075), right(0.28, 0.115), right(0.53, 0.07)]
        case "iPad":
            // Top button and volume, held in portrait
            return [topEdge(0.78, 0.08), right(0.09, 0.05), right(0.155, 0.05)]
        default:
            return []
        }
    }
}

/// Draws an image the right way up in a context whose y axis points down.
func drawImage(_ image: CGImage, in rect: CGRect, context: CGContext) {
    context.saveGState()
    context.translateBy(x: rect.minX, y: rect.maxY)
    context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(origin: .zero, size: rect.size))
    context.restoreGState()
}

// MARK: - Callouts

func drawCallout(_ callout: Callout, canvas: CGSize, screenRect: CGRect, captureSize: CGSize, context: CGContext) {
    let font = NSFont(name: "Futura-Medium", size: callout.fontSize) ?? .systemFont(ofSize: callout.fontSize)
    let padding = CGSize(width: callout.fontSize * 0.28, height: callout.fontSize * 0.08)
    let gap = callout.fontSize * 0.12

    // Lay the segments out on one line
    let sizes = callout.segments.map { segment in
        NSAttributedString(string: segment.text, attributes: [.font: font]).size()
    }
    let highlightWidth = { (index: Int) -> CGFloat in
        callout.segments[index].color == nil ? sizes[index].width : sizes[index].width + padding.width * 2
    }
    let lineWidth = callout.segments.indices.map(highlightWidth).reduce(0, +)
        + gap * CGFloat(callout.segments.count - 1)
    let lineHeight = font.ascender - font.descender + padding.height * 2
    let center = CGPoint(x: canvas.width * callout.center[0], y: canvas.height * callout.center[1])
    let box = CGRect(x: center.x - lineWidth / 2 - callout.fontSize * 0.7, y: center.y - lineHeight / 2 - callout.fontSize * 0.55,
                     width: lineWidth + callout.fontSize * 1.4, height: lineHeight + callout.fontSize * 1.1)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 8), blur: 30, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    context.addPath(roundedRect(box, callout.fontSize * 0.45))
    context.setFillColor(NSColor.black.withAlphaComponent(0.18).cgColor)
    context.fillPath()
    context.restoreGState()
    context.addPath(roundedRect(box, callout.fontSize * 0.45))
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(callout.fontSize * 0.09)
    context.strokePath()

    var x = center.x - lineWidth / 2
    var segmentRects: [CGRect] = []
    for (index, segment) in callout.segments.enumerated() {
        let width = highlightWidth(index)
        let rect = CGRect(x: x, y: center.y - lineHeight / 2, width: width, height: lineHeight)
        if let color = segment.color {
            context.addPath(roundedRect(rect, lineHeight * 0.28))
            context.setFillColor(NSColor(hex: color).cgColor)
            context.fillPath()
        }
        let textX = segment.color == nil ? x : x + padding.width
        NSAttributedString(string: segment.text, attributes: [.font: font, .foregroundColor: NSColor.white])
            .draw(at: CGPoint(x: textX, y: rect.minY + padding.height))
        segmentRects.append(rect)
        x += width + gap
    }

    // Arrows run from a segment's edge through the bends to the screen
    let toCanvas = { (point: CGPoint) -> CGPoint in
        CGPoint(x: screenRect.minX + point.x / captureSize.width * screenRect.width,
                y: screenRect.minY + point.y / captureSize.height * screenRect.height)
    }
    let lineThickness = callout.fontSize * 0.09
    for arrow in callout.arrows {
        let rect = segmentRects[arrow.segment]
        let color = NSColor(hex: callout.segments[arrow.segment].color ?? "#FFFFFF").cgColor
        var points: [CGPoint]
        switch arrow.edge {
        case "left": points = [CGPoint(x: rect.minX, y: rect.midY)]
        case "right": points = [CGPoint(x: rect.maxX, y: rect.midY)]
        default: points = [CGPoint(x: rect.midX, y: rect.maxY)]
        }
        for bend in arrow.points {
            let previous = points.last!
            let mapped = toCanvas(CGPoint(x: bend.x ?? 0, y: bend.y ?? 0))
            points.append(CGPoint(x: bend.x == nil ? previous.x : mapped.x, y: bend.y == nil ? previous.y : mapped.y))
        }
        // Stop the line short of the tip so the head stays sharp
        let tip = points[points.count - 1]
        let from = points[points.count - 2]
        let length = hypot(tip.x - from.x, tip.y - from.y)
        let direction = CGPoint(x: (tip.x - from.x) / length, y: (tip.y - from.y) / length)
        let headLength = lineThickness * 4.2
        let headBase = CGPoint(x: tip.x - direction.x * headLength, y: tip.y - direction.y * headLength)

        context.setStrokeColor(color)
        context.setLineWidth(lineThickness)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.move(to: points[0])
        for point in points.dropFirst().dropLast() { context.addLine(to: point) }
        context.addLine(to: headBase)
        context.strokePath()

        let normal = CGPoint(x: -direction.y, y: direction.x)
        let halfWidth = lineThickness * 2.4
        context.move(to: tip)
        context.addLine(to: CGPoint(x: headBase.x + normal.x * halfWidth, y: headBase.y + normal.y * halfWidth))
        context.addLine(to: CGPoint(x: headBase.x - normal.x * halfWidth, y: headBase.y - normal.y * halfWidth))
        context.closePath()
        context.setFillColor(color)
        context.fillPath()
    }
}

// MARK: - Composition

func compose(_ scene: Scene, platform: Platform, layout: Layout, base: URL) throws -> NSBitmapImageRep {
    let canvas = CGSize(width: platform.canvas[0], height: platform.canvas[1])
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    let context = graphics.cgContext
    // Work top-down, like the capture coordinates
    context.translateBy(x: 0, y: canvas.height)
    context.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    defer { NSGraphicsContext.restoreGraphicsState() }

    // Background
    let colors = layout.background.map { NSColor(hex: $0).cgColor }
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray,
                              locations: nil)!
    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: canvas.height), options: [])

    // Caption
    let titleFont = NSFont(name: layout.titleFont, size: platform.titleSize)!
    let subtitleFont = NSFont(name: layout.subtitleFont, size: platform.subtitleSize)!
    let titleTop = canvas.height * platform.titleTop
    let titleHeight = drawCentered(scene.title, font: titleFont, color: .white, centerX: canvas.width / 2,
                                   top: titleTop, maxWidth: canvas.width * 0.92)
    drawCentered(scene.subtitle, font: subtitleFont, color: .white, centerX: canvas.width / 2,
                 top: titleTop + titleHeight + platform.subtitleSize * 0.05, maxWidth: canvas.width * 0.92)

    // Device
    guard let image = NSImage(contentsOf: base.appending(path: scene.capture)),
          let capture = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw NSError(domain: "Compose", code: 1, userInfo: [NSLocalizedDescriptionKey: "Can't read \(scene.capture)"])
    }
    let captureSize = CGSize(width: capture.width, height: capture.height)
    let width = canvas.width * (scene.deviceWidth ?? platform.deviceWidth)
    let top = canvas.height * (scene.deviceTop ?? platform.deviceTop)
    let screenRect: CGRect
    if platform.device.kind == "window" {
        let scale = width / captureSize.width
        screenRect = CGRect(x: (canvas.width - width) / 2, y: top, width: width, height: captureSize.height * scale)
        let radius = platform.device.screenCornerRadius * scale
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 40), blur: 120, color: NSColor.black.withAlphaComponent(0.5).cgColor)
        context.addPath(roundedRect(screenRect, radius))
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(roundedRect(screenRect, radius))
        context.clip()
        context.interpolationQuality = .high
        drawImage(capture, in: screenRect, context: context)
        context.restoreGState()
    } else {
        let frame = Frame(device: platform.device, screen: captureSize)
        let scale = width / frame.outer.width
        let origin = CGPoint(x: (canvas.width - width) / 2, y: top)
        frame.draw(in: context, at: origin, scale: scale, screenImage: capture)
        let bezel = platform.device.bezel * scale
        screenRect = CGRect(x: origin.x + bezel, y: origin.y + bezel,
                            width: captureSize.width * scale, height: captureSize.height * scale)
    }

    // Fade to black where the device runs off the bottom
    if let fadeFrom = scene.fadeFrom ?? platform.fadeFrom {
        let fade = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [NSColor.black.withAlphaComponent(0).cgColor, NSColor.black.cgColor] as CFArray,
                              locations: [0, 1])!
        let start = canvas.height * fadeFrom
        context.drawLinearGradient(fade, start: CGPoint(x: 0, y: start),
                                   end: CGPoint(x: 0, y: start + (canvas.height - start) * 0.8),
                                   options: [.drawsAfterEndLocation])
    }

    if let callout = scene.callout {
        drawCallout(callout, canvas: canvas, screenRect: screenRect, captureSize: captureSize, context: context)
    }
    context.flush()
    return rep
}

// MARK: - Main

let arguments = Array(CommandLine.arguments.dropFirst())
let layoutURL = URL(filePath: arguments.first ?? "Screenshots.json",
                    relativeTo: URL(filePath: FileManager.default.currentDirectoryPath + "/")).absoluteURL
let base = layoutURL.deletingLastPathComponent()
let layout = try JSONDecoder().decode(Layout.self, from: Data(contentsOf: layoutURL))
let only = Set(arguments.dropFirst())

for (name, platform) in layout.platforms.sorted(by: { $0.key < $1.key }) where only.isEmpty || only.contains(name) {
    let folder = base.appending(path: "Output/\(name)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    for scene in platform.scenes {
        let rep = try compose(scene, platform: platform, layout: layout, base: base)
        // App Store Connect turns down images with an alpha channel
        guard let cgImage = rep.cgImage,
              let opaque = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8,
                                     bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                     bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { continue }
        opaque.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        let output = NSBitmapImageRep(cgImage: opaque.makeImage()!)
        let url = folder.appending(path: "\(scene.name).png")
        try output.representation(using: .png, properties: [:])!.write(to: url)
        print("Wrote \(name)/\(scene.name).png")
    }
}
