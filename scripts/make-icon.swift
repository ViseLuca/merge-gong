// Draws the app icon: a golden gong with the git merge glyph, ringing on a dark teal tile.
//   swift scripts/make-icon.swift <out.png>   renders the 1024x1024 master
import AppKit

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
// Top-left origin, y growing down, like the coordinates below.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

let space = CGColorSpaceCreateDeviceRGB()
func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}
func gradient(_ colors: [CGColor], _ stops: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: stops)!
}
func circle(_ c: CGPoint, _ r: CGFloat) -> CGRect { CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r) }

// Tile: the macOS icon grid keeps a 100pt margin around an 824pt rounded square.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: rgb(0x000000, 0.35))
ctx.addPath(tilePath)
ctx.setFillColor(rgb(0x163033))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0x2A4B4B), rgb(0x10232A)], [0, 1]),
                       start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
// The faint warm glow behind the popup's text.
ctx.drawRadialGradient(gradient([rgb(0xC0563A, 0.28), rgb(0xC0563A, 0)], [0, 1]),
                       startCenter: CGPoint(x: 600, y: 640), startRadius: 0,
                       endCenter: CGPoint(x: 600, y: 640), endRadius: 420, options: [])
ctx.restoreGState()

let center = CGPoint(x: 512, y: 560)
let radius: CGFloat = 250

// Sound waves on both sides of the gong.
ctx.setLineCap(.round)
for (i, r) in [CGFloat(305), 355].enumerated() {
    ctx.setLineWidth(22)
    ctx.setStrokeColor(rgb(0xFFC93C, i == 0 ? 0.85 : 0.45))
    for mid in [CGFloat.pi, 0] {
        ctx.addArc(center: center, radius: r, startAngle: mid - 0.42, endAngle: mid + 0.42, clockwise: false)
        ctx.strokePath()
    }
}

// Crossbar and cords the gong hangs from.
ctx.setLineWidth(12)
ctx.setStrokeColor(rgb(0x3B2410))
for x in [CGFloat(430), 594] {
    ctx.move(to: CGPoint(x: x, y: 232))
    ctx.addLine(to: CGPoint(x: x + (x < 512 ? 22 : -22), y: 335))
}
ctx.strokePath()
let bar = CGPath(roundedRect: CGRect(x: 250, y: 200, width: 524, height: 44), cornerWidth: 22, cornerHeight: 22, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 6), blur: 10, color: rgb(0x000000, 0.4))
ctx.addPath(bar)
ctx.setFillColor(rgb(0x7A4A22))
ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(bar)
ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0xB0743A), rgb(0x6E3F1C)], [0, 1]),
                       start: CGPoint(x: 0, y: 200), end: CGPoint(x: 0, y: 244), options: [])
ctx.restoreGState()

// Gong disc: dark rim, golden face, a groove and a raised boss.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 30, color: rgb(0x000000, 0.5))
ctx.setFillColor(rgb(0x8A5A14))
ctx.fillEllipse(in: circle(center, radius))
ctx.restoreGState()

ctx.saveGState()
ctx.addEllipse(in: circle(center, radius))
ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0xE9B23A), rgb(0x8A5A14)], [0, 1]),
                       start: CGPoint(x: 0, y: center.y - radius), end: CGPoint(x: 0, y: center.y + radius), options: [])
ctx.restoreGState()

let face = radius - 26
ctx.saveGState()
ctx.addEllipse(in: circle(center, face))
ctx.clip()
let light = CGPoint(x: center.x - 70, y: center.y - 90)
ctx.drawRadialGradient(gradient([rgb(0xFFE89A), rgb(0xF6C445), rgb(0xD39424)], [0, 0.45, 1]),
                       startCenter: light, startRadius: 0, endCenter: center, endRadius: face, options: [.drawsAfterEndLocation])
ctx.restoreGState()

ctx.setLineWidth(6)
ctx.setStrokeColor(rgb(0xA8701A, 0.55))
ctx.strokeEllipse(in: circle(center, face - 38))

// The git merge glyph, engraved: a dark stroke with a light edge just below it.
func mergeGlyph(offset: CGFloat) -> (CGMutablePath, [CGPoint]) {
    let top = CGPoint(x: center.x - 70, y: center.y - 105 + offset)
    let bottom = CGPoint(x: center.x - 70, y: center.y + 105 + offset)
    let right = CGPoint(x: center.x + 85, y: center.y + 30 + offset)
    let path = CGMutablePath()
    path.move(to: top)
    path.addLine(to: bottom)
    path.move(to: top)
    path.addCurve(to: right, control1: CGPoint(x: top.x, y: right.y - 10), control2: CGPoint(x: right.x - 90, y: right.y))
    return (path, [top, bottom, right])
}
for (offset, color) in [(CGFloat(5), rgb(0xFFF1C2, 0.7)), (0, rgb(0x5E3A0C, 0.9))] {
    let (path, nodes) = mergeGlyph(offset: offset)
    ctx.addPath(path)
    ctx.setLineWidth(26)
    ctx.setStrokeColor(color)
    ctx.strokePath()
    for node in nodes {
        ctx.setFillColor(color)
        ctx.fillEllipse(in: circle(node, 38))
    }
}
let (_, nodes) = mergeGlyph(offset: 0)
for node in nodes {
    ctx.saveGState()
    ctx.addEllipse(in: circle(node, 22))
    ctx.clip()
    ctx.drawRadialGradient(gradient([rgb(0xFFE89A), rgb(0xF0B93C)], [0, 1]),
                           startCenter: CGPoint(x: node.x - 6, y: node.y - 6), startRadius: 0,
                           endCenter: node, endRadius: 22, options: [])
    ctx.restoreGState()
}

// Specular sweep across the upper left of the face.
ctx.saveGState()
ctx.addEllipse(in: circle(center, face))
ctx.clip()
ctx.setLineWidth(18)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.35))
ctx.addArc(center: center, radius: face - 16, startAngle: .pi * 1.08, endAngle: .pi * 1.38, clockwise: false)
ctx.strokePath()
ctx.restoreGState()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
