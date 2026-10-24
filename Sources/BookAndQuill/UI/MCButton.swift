import SwiftUI

/// Grey bevelled Minecraft button.
struct MCButton: View {
    let title: String
    var width: CGFloat = 200
    var enabled: Bool = true
    var shortcut: KeyboardShortcut?
    let action: () -> Void

    init(_ title: String, width: CGFloat = 200, enabled: Bool = true,
         shortcut: KeyboardShortcut? = nil, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.enabled = enabled
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(MCButtonStyle(width: width))
            .disabled(!enabled)
            .keyboardShortcut(shortcut)
    }
}

private struct MCButtonStyle: ButtonStyle {
    let width: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        Face(label: configuration.label, pressed: configuration.isPressed, width: width)
    }

    private struct Face<Label: View>: View {
        let label: Label
        let pressed: Bool
        let width: CGFloat
        @StateObject private var hovered = Local(false)
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            let highlighted = enabled && (hovered.value || pressed)
            let face = !enabled ? Color(hex: 0x2C2C2C) : highlighted ? Color(hex: 0x7E88BF) : Color(hex: 0x6F6F6F)
            let light = !enabled ? Color(hex: 0x3A3A3A) : highlighted ? Color(hex: 0xBCC4F0) : Color(hex: 0xAAAAAA)
            let dark = !enabled ? Color(hex: 0x1C1C1C) : highlighted ? Color(hex: 0x4A5491) : Color(hex: 0x555555)

            ZStack {
                Rectangle().fill(highlighted ? Color.white : Color.black)
                Rectangle().fill(dark).padding(2)
                Rectangle().fill(light).padding(.leading, 2).padding(.top, 2).padding(.trailing, 4).padding(.bottom, 6)
                Rectangle().fill(face).padding(.leading, 4).padding(.top, 4).padding(.trailing, 4).padding(.bottom, 6)
                label
                    .font(MC.font(16))
                    .foregroundStyle(enabled ? (highlighted ? Color(hex: 0xFFFFA0) : .white) : Color(hex: 0xA0A0A0))
                    .shadow(color: enabled ? MC.textShadow : .clear, radius: 0, x: 2, y: 2)
                    .padding(.bottom, 2)
                    .lineLimit(1)
            }
            .frame(width: width, height: 40)
            .contentShape(Rectangle())
            .onHover { hovered.value = $0 }
        }
    }
}
