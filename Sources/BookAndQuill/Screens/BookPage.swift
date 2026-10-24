import SwiftUI
import AppKit

/// Geometry and drawing of the Book & Quill page.
enum BookPage {
    static let font = MC.nsFont(18)
    static let maxLines = 14
    static let textWidth: CGFloat = 300
    static let lineHeight = NSLayoutManager().defaultLineHeight(for: font)
    static let textHeight = lineHeight * CGFloat(maxLines)
    static let size = CGSize(width: textWidth + 80, height: textHeight + 130)

    /// True when the text wraps to at most `maxLines` lines at the page width.
    static let fits: (String) -> Bool = {
        let storage = NSTextStorage()
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: textWidth, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        return { text in
            storage.setAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
            layout.ensureLayout(for: container)
            let lines = Int((layout.usedRect(for: container).height / lineHeight).rounded())
            return lines <= maxLines
        }
    }()
}

/// Cream page inside a leather cover, drawn as flat pixel rectangles.
struct BookPageBackground: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Color(hex: 0x2E1C0C))
            Rectangle().fill(Color(hex: 0x6B4423)).padding(3)
            Rectangle().fill(Color(hex: 0x4E3018))
                .frame(width: 8).padding(.vertical, 3).padding(.leading, 3)
            Rectangle().fill(Color(hex: 0xD9CBA6))
                .padding(.leading, 17).padding(.top, 9).padding(.trailing, 6).padding(.bottom, 6)
            Rectangle().fill(Color(hex: 0xF4ECD6))
                .padding(.leading, 17).padding(.top, 9).padding(.trailing, 9).padding(.bottom, 9)
            Rectangle().fill(Color(hex: 0xE3D6B4))
                .frame(width: 5).padding(.vertical, 9).padding(.leading, 17)
        }
        .frame(width: BookPage.size.width, height: BookPage.size.height)
    }
}

/// Minecraft-style page turn arrow.
struct PageArrow: View {
    let right: Bool
    let action: () -> Void
    @StateObject private var hovered = Local(false)

    var body: some View {
        Button(action: action) {
            Image(nsImage: Sprites.arrow(right: right, hovered: hovered.value))
                .interpolation(.none)
        }
        .buttonStyle(.plain)
        .onHover { hovered.value = $0 }
    }
}
