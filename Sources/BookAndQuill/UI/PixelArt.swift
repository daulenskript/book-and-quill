import AppKit
import SwiftUI

/// Builds crisp pixel-art images from ASCII rows; '.' (or a missing key) is transparent.
enum PixelArt {
    static func image(_ rows: [String], palette: [Character: NSColor], scale: Int) -> NSImage {
        let height = rows.count
        let width = rows.map(\.count).max() ?? 0
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width * scale, pixelsHigh: height * scale,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        for (y, row) in rows.enumerated() {
            for (x, ch) in row.enumerated() {
                guard let color = palette[ch]?.usingColorSpace(.deviceRGB) else { continue }
                for dy in 0..<scale {
                    for dx in 0..<scale {
                        rep.setColor(color, atX: x * scale + dx, y: y * scale + dy)
                    }
                }
            }
        }
        let image = NSImage(size: NSSize(width: width * scale, height: height * scale))
        image.addRepresentation(rep)
        return image
    }

    /// Image from a per-pixel colour function (used for the procedural dirt tile).
    static func image(width: Int, height: Int, scale: Int, color: (Int, Int) -> NSColor) -> NSImage {
        var cache: [Character: NSColor] = [:]
        var palettedRows: [String] = []
        var next: UInt32 = 0x100
        for y in 0..<height {
            var row = ""
            for x in 0..<width {
                let c = color(x, y)
                let key = cache.first { $0.value == c }?.key ?? {
                    let k = Character(UnicodeScalar(next)!)
                    next += 1
                    cache[k] = c
                    return k
                }()
                row.append(key)
            }
            palettedRows.append(row)
        }
        return image(palettedRows, palette: cache, scale: scale)
    }
}

/// Hand-drawn original sprites.
enum Sprites {
    static let bookIcon: NSImage = PixelArt.image([
        "................",
        "............wW..",
        "...........wWW..",
        "..........wWWg..",
        ".........wWWg...",
        "..kkkkkkwWWgk...",
        ".kBBBBBwWgBBBk..",
        ".kBbbbwWgbbbBk..",
        ".kBbbbWgbbbbBk..",
        ".kBbbbqbbbbbBk..",
        ".kBbbqbbbbbbBk..",
        ".kBbbbbbbbbbBk..",
        ".kPPPPPPPPPPPk..",
        ".kpppppppppppk..",
        "..kkkkkkkkkkk...",
        "................",
    ], palette: [
        "k": NSColor(hex: 0x2B1A0E), "B": NSColor(hex: 0x6B3F1F), "b": NSColor(hex: 0x8A5530),
        "P": NSColor(hex: 0xF2EAD3), "p": NSColor(hex: 0xCFC3A3), "W": NSColor(hex: 0xFFFFFF),
        "w": NSColor(hex: 0xD8D8D8), "g": NSColor(hex: 0x9A9A9A), "q": NSColor(hex: 0x3A3A3A),
    ], scale: 4)

    private static let arrowRows = [
        "......k....",
        "......kk...",
        "......kAk..",
        "kkkkkkkAAk.",
        "kAAAAAAAAAk",
        "kkkkkkkAAk.",
        "......kAk..",
        "......kk...",
        "......k....",
    ]

    static func arrow(right: Bool, hovered: Bool) -> NSImage {
        let rows = right ? arrowRows : arrowRows.map { String($0.reversed()) }
        return PixelArt.image(rows, palette: [
            "k": NSColor(hex: 0x3B2A17),
            "A": NSColor(hex: hovered ? 0xF2D49B : 0xC9A26B),
        ], scale: 3)
    }

    /// Procedural dirt tile, darkened like a Minecraft menu background.
    static let dirtTile: NSImage = {
        let shades: [UInt32] = [0x866043, 0x6C4A30, 0x593D29, 0x9A7354, 0x4A3221, 0x79553A]
        var seed: UInt32 = 0x5EED
        func rand() -> UInt32 {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            return seed >> 16
        }
        let grid = (0..<256).map { _ in shades[Int(rand() % UInt32(shades.count))] }
        return PixelArt.image(width: 16, height: 16, scale: 4) { x, y in
            let c = NSColor(hex: grid[y * 16 + x])
            return NSColor(srgbRed: c.redComponent * 0.3, green: c.greenComponent * 0.3,
                           blue: c.blueComponent * 0.3, alpha: 1)
        }
    }()
}

extension Image {
    /// Pixel image scaled without smoothing.
    init(pixel image: NSImage) {
        self.init(nsImage: image)
    }

    func pixelated() -> some View {
        self.interpolation(.none).resizable()
    }
}
