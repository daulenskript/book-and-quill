import AppKit

/// `BOOKANDQUILL_EXPORT_ICON=/path/icon.png` writes the 1024px app icon and exits.
/// build.sh uses it so the icon comes from the same sprites as the app.
enum IconExport {
    static func runIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["BOOKANDQUILL_EXPORT_ICON"] else { return }
        let size = 1024
        let ctx = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.interpolationQuality = .none

        // Rounded dirt tile body on Apple's 824px icon grid.
        let body = CGRect(x: 100, y: 100, width: 824, height: 824)
        ctx.addPath(CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil))
        ctx.clip()
        let dirt = cgImage(Sprites.dirt(brightness: 0.85))
        let tile = 824 / 4
        for x in 0..<4 {
            for y in 0..<4 {
                ctx.draw(dirt, in: CGRect(x: 100 + x * tile, y: 100 + y * tile, width: tile, height: tile))
            }
        }
        let book = cgImage(Sprites.bookIcon)
        ctx.draw(book, in: CGRect(x: 192, y: 192, width: 640, height: 640))

        let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        exit(0)
    }

    private static func cgImage(_ image: NSImage) -> CGImage {
        image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }
}
