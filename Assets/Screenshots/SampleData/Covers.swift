// Draws the album covers for the sample library.
// Usage: swift Covers.swift library.json <output folder>

import AppKit

struct Library: Decodable {
    struct Folder: Decodable { var albums: [Album] }
    struct Album: Decodable {
        var title: String
        var albumArtist: String
        var cover: Cover
    }
    struct Cover: Decodable {
        var style: String
        var colors: [String]
        var kicker: String
        var font: String
        var dark: Bool?
    }
    var folders: [Folder]
}

extension NSColor {
    convenience init(hex: String) {
        let value = Int(hex.dropFirst(), radix: 16) ?? 0
        self.init(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
}

let size: CGFloat = 1200

/// A repeatable random sequence, so the covers come out the same every run.
struct Seeded {
    var state: UInt64
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}

func drawCover(_ album: Library.Album, to url: URL) {
    let cover = album.cover
    let colors = cover.colors.map(NSColor.init(hex:))
    let isDark = cover.dark ?? true
    let ink = isDark ? NSColor.white : colors[2].blended(withFraction: 0.55, of: .black)!
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        let context = NSGraphicsContext.current!.cgContext
        var random = Seeded(state: album.title.unicodeScalars.reduce(7) { $0 &* 31 &+ UInt64($1.value) })

        // Background
        let background = NSGradient(colors: [colors[0], colors[1]])!
        background.draw(in: rect, angle: -70)

        let center = CGPoint(x: size / 2, y: size * 0.56)
        switch cover.style {
        case "horns":
            // Two swept horns over a glowing core
            NSGradient(colors: [colors[2].withAlphaComponent(0.85), colors[2].withAlphaComponent(0)])!
                .draw(fromCenter: center, radius: 0, toCenter: center, radius: 420, options: [])
            for side in [-1.0, 1.0] as [CGFloat] {
                let horn = NSBezierPath()
                horn.move(to: CGPoint(x: center.x + side * 40, y: center.y - 120))
                horn.curve(to: CGPoint(x: center.x + side * 300, y: center.y + 400),
                           controlPoint1: CGPoint(x: center.x + side * 380, y: center.y - 100),
                           controlPoint2: CGPoint(x: center.x + side * 420, y: center.y + 250))
                horn.curve(to: CGPoint(x: center.x + side * 190, y: center.y - 20),
                           controlPoint1: CGPoint(x: center.x + side * 300, y: center.y + 220),
                           controlPoint2: CGPoint(x: center.x + side * 280, y: center.y + 40))
                horn.close()
                NSGradient(colors: [NSColor.black, colors[1]])!.draw(in: horn, angle: 90)
                horn.fill()
                colors[2].setStroke()
                horn.lineWidth = 8
                horn.stroke()
            }
            for _ in 0..<70 {
                let x = random.next() * size, y = random.next() * size
                let r = 2 + random.next() * 6
                colors[2].withAlphaComponent(0.3 + random.next() * 0.6).setFill()
                NSBezierPath(ovalIn: CGRect(x: x, y: y, width: r, height: r)).fill()
            }
        case "neon":
            // A neon sign frame with a crescent
            for i in 0..<14 {
                let y = CGFloat(i) * 90
                colors[2].withAlphaComponent(0.06).setFill()
                CGRect(x: 0, y: y, width: size, height: 40).fill()
            }
            context.setShadow(offset: .zero, blur: 40, color: colors[2].cgColor)
            let frame = NSBezierPath(roundedRect: CGRect(x: 180, y: 380, width: 840, height: 560),
                                     xRadius: 60, yRadius: 60)
            colors[2].setStroke()
            frame.lineWidth = 14
            frame.stroke()
            let moon = NSBezierPath(ovalIn: CGRect(x: 470, y: 560, width: 260, height: 260))
            moon.lineWidth = 14
            moon.stroke()
            colors[0].setFill()
            NSBezierPath(ovalIn: CGRect(x: 540, y: 610, width: 230, height: 230)).fill()
            context.setShadow(offset: .zero, blur: 0, color: nil)
        case "embers":
            // A starburst of sparks
            for i in 0..<48 {
                let angle = CGFloat(i) / 48 * .pi * 2
                let length = 220 + random.next() * 360
                let path = NSBezierPath()
                path.move(to: center)
                path.line(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                colors[2].withAlphaComponent(0.25 + random.next() * 0.5).setStroke()
                path.lineWidth = 4 + random.next() * 10
                path.lineCapStyle = .round
                path.stroke()
            }
            NSGradient(colors: [NSColor.white, colors[2], colors[2].withAlphaComponent(0)])!
                .draw(fromCenter: center, radius: 0, toCenter: center, radius: 220, options: [])
        case "stripes":
            // Diagonal hazard stripes behind a star emblem
            context.saveGState()
            context.rotate(by: -.pi / 6)
            for i in -12..<20 {
                colors[2].withAlphaComponent(i % 2 == 0 ? 0.16 : 0.04).setFill()
                CGRect(x: CGFloat(i) * 110, y: -800, width: 55, height: 3000).fill()
            }
            context.restoreGState()
            let star = NSBezierPath()
            for i in 0..<10 {
                let angle = CGFloat(i) / 10 * .pi * 2 + .pi / 2
                let radius: CGFloat = i % 2 == 0 ? 300 : 125
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                i == 0 ? star.move(to: point) : star.line(to: point)
            }
            star.close()
            colors[2].setFill()
            star.fill()
            colors[0].setStroke()
            star.lineWidth = 12
            star.stroke()
        case "halo":
            // A golden halo with soft rays
            for i in 0..<36 {
                let angle = CGFloat(i) / 36 * .pi * 2
                let path = NSBezierPath()
                path.move(to: center)
                path.line(to: CGPoint(x: center.x + cos(angle - 0.03) * 900, y: center.y + sin(angle - 0.03) * 900))
                path.line(to: CGPoint(x: center.x + cos(angle + 0.03) * 900, y: center.y + sin(angle + 0.03) * 900))
                path.close()
                NSColor.white.withAlphaComponent(0.35).setFill()
                path.fill()
            }
            context.setShadow(offset: .zero, blur: 50, color: colors[2].withAlphaComponent(0.8).cgColor)
            for (index, radius) in [300, 250].enumerated() {
                let ring = NSBezierPath(ovalIn: CGRect(x: center.x - CGFloat(radius), y: center.y - CGFloat(radius) * 0.36,
                                                       width: CGFloat(radius) * 2, height: CGFloat(radius) * 0.72))
                ring.lineWidth = index == 0 ? 22 : 8
                colors[2].setStroke()
                ring.stroke()
            }
            context.setShadow(offset: .zero, blur: 0, color: nil)
            for _ in 0..<40 {
                let x = random.next() * size, y = 300 + random.next() * 800
                let r = 4 + random.next() * 10
                NSColor.white.withAlphaComponent(0.8).setFill()
                NSBezierPath(ovalIn: CGRect(x: x, y: y, width: r, height: r)).fill()
            }
        case "wings":
            // A pair of feathered wings
            for side in [-1.0, 1.0] as [CGFloat] {
                for i in 0..<7 {
                    let feather = NSBezierPath()
                    let base = CGPoint(x: center.x + side * 40, y: center.y - 20)
                    let angle = (CGFloat(i) * 11 + 5) * .pi / 180
                    let length = 470 - CGFloat(i) * 42
                    let tip = CGPoint(x: base.x + side * cos(angle) * length, y: base.y + sin(angle) * length - 80)
                    feather.move(to: base)
                    feather.curve(to: tip, controlPoint1: CGPoint(x: base.x + side * length * 0.4, y: base.y + 200),
                                  controlPoint2: CGPoint(x: tip.x - side * 40, y: tip.y + 40))
                    feather.curve(to: base, controlPoint1: CGPoint(x: tip.x - side * 60, y: tip.y - 60),
                                  controlPoint2: CGPoint(x: base.x + side * length * 0.3, y: base.y + 40))
                    NSColor.white.withAlphaComponent(0.55 + CGFloat(i) * 0.05).setFill()
                    feather.fill()
                    colors[2].withAlphaComponent(0.5).setStroke()
                    feather.lineWidth = 3
                    feather.stroke()
                }
            }
            let ring = NSBezierPath(ovalIn: CGRect(x: center.x - 120, y: center.y + 230, width: 240, height: 70))
            ring.lineWidth = 12
            colors[2].setStroke()
            ring.stroke()
        case "cross":
            // A crosshair over a shield of light
            NSGradient(colors: [colors[1].withAlphaComponent(0.9), colors[0].withAlphaComponent(0)])!
                .draw(fromCenter: center, radius: 0, toCenter: center, radius: 520, options: [])
            colors[2].setStroke()
            for radius in [320, 210, 90] as [CGFloat] {
                let circle = NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                         width: radius * 2, height: radius * 2))
                circle.lineWidth = radius == 320 ? 10 : 5
                circle.stroke()
            }
            let lines = NSBezierPath()
            lines.move(to: CGPoint(x: center.x - 420, y: center.y))
            lines.line(to: CGPoint(x: center.x + 420, y: center.y))
            lines.move(to: CGPoint(x: center.x, y: center.y - 420))
            lines.line(to: CGPoint(x: center.x, y: center.y + 420))
            lines.lineWidth = 6
            lines.stroke()
        default:
            // A rose window of overlapping petals
            for i in 0..<12 {
                let angle = CGFloat(i) / 12 * .pi * 2
                let petal = NSBezierPath(ovalIn: CGRect(x: -70, y: 0, width: 140, height: 330))
                var transform = AffineTransform(translationByX: center.x, byY: center.y)
                transform.rotate(byRadians: angle)
                petal.transform(using: transform)
                colors[2].withAlphaComponent(0.22).setFill()
                petal.fill()
                colors[2].withAlphaComponent(0.8).setStroke()
                petal.lineWidth = 3
                petal.stroke()
            }
            let core = NSBezierPath(ovalIn: CGRect(x: center.x - 70, y: center.y - 70, width: 140, height: 140))
            colors[2].setFill()
            core.fill()
        }

        // Darken or lighten the bottom so the title reads
        let shade = isDark ? NSColor.black : NSColor.white
        NSGradient(colors: [shade.withAlphaComponent(0.85), shade.withAlphaComponent(0)])!
            .draw(in: CGRect(x: 0, y: 0, width: size, height: 420), angle: 90)

        // Title and kicker
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        // Shrink the title until it fits on two lines
        let text = cover.font.hasPrefix("Futura") ? album.title.uppercased() : album.title
        var fontSize: CGFloat = 112
        var title = NSAttributedString()
        var bounds = CGRect.zero
        repeat {
            let font = NSFont(name: cover.font, size: fontSize) ?? .boldSystemFont(ofSize: fontSize)
            title = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: ink,
                                                                  .paragraphStyle: paragraph])
            bounds = title.boundingRect(with: CGSize(width: size - 140, height: 1000), options: [.usesLineFragmentOrigin])
            fontSize -= 4
        } while bounds.height > fontSize * 2.6
        title.draw(in: CGRect(x: 70, y: 90, width: size - 140, height: ceil(bounds.height) + 4))
        let kicker = NSAttributedString(string: cover.kicker, attributes: [
            .font: NSFont(name: "Futura-Medium", size: 34)!, .kern: 10, .foregroundColor: ink.withAlphaComponent(0.85),
            .paragraphStyle: paragraph
        ])
        kicker.draw(in: CGRect(x: 0, y: size - 110, width: size, height: 60))
        return true
    }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!
    try! data.write(to: url)
}

let arguments = CommandLine.arguments
let library = try! JSONDecoder().decode(Library.self, from: Data(contentsOf: URL(filePath: arguments[1])))
let output = URL(filePath: arguments[2])
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for album in library.folders.flatMap(\.albums) {
    drawCover(album, to: output.appending(path: "\(album.title).jpg"))
    print("Drew \(album.title)")
}
