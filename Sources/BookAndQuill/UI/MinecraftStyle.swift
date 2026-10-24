import SwiftUI
import AppKit

/// Shared look: colours and the bundled Monocraft pixel font.
enum MC {
    static let fontName = "Monocraft"

    static let text = Color.white
    static let textGrey = Color(hex: 0xA0A0A0)
    static let textShadow = Color(hex: 0x3F3F3F)
    static let ink = Color(hex: 0x1E1610)

    static func font(_ size: CGFloat) -> Font {
        .custom(fontName, fixedSize: size)
    }

    static func nsFont(_ size: CGFloat) -> NSFont {
        NSFont(name: fontName, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Registers the bundled font. Inside the .app it lives in Contents/Resources;
    /// under `swift run` it comes from the SwiftPM resource bundle.
    static func registerFont() {
        let url = Bundle.main.url(forResource: "Monocraft", withExtension: "ttf")
            ?? Bundle.module.url(forResource: "Monocraft", withExtension: "ttf")
        if let url {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// White menu text with Minecraft's hard drop shadow.
struct MCText: View {
    let string: String
    var size: CGFloat = 16
    var color: Color = MC.text

    init(_ string: String, size: CGFloat = 16, color: Color = MC.text) {
        self.string = string
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(string)
            .font(MC.font(size))
            .foregroundStyle(color)
            .shadow(color: MC.textShadow, radius: 0, x: size / 8, y: size / 8)
    }
}

/// View-local state holder. The Command Line Tools ship without the SwiftUI macro
/// plugin, so `@State` does not compile; views use `@StateObject var x = Local(...)`.
final class Local<Value>: ObservableObject {
    @Published var value: Value
    init(_ value: Value) { self.value = value }
}
