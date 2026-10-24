import SwiftUI

/// Black Minecraft text box with a grey border that turns white when focused.
struct MCTextField: View {
    @Binding var text: String
    var placeholder = ""
    var width: CGFloat = 400
    var onSubmit: () -> Void = {}
    @FocusState private var focused: Bool
    var autofocus = false

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(focused ? Color.white : MC.textGrey)
            Rectangle().fill(Color.black).padding(2)
            if text.isEmpty {
                Text(placeholder)
                    .font(MC.font(16))
                    .foregroundStyle(Color(hex: 0x707070))
                    .padding(.horizontal, 10)
            }
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(MC.font(16))
                .foregroundStyle(Color(hex: 0xE0E0E0))
                .padding(.horizontal, 10)
                .focused($focused)
                .onSubmit(onSubmit)
        }
        .frame(width: width, height: 40)
        .onAppear {
            if autofocus {
                DispatchQueue.main.async { focused = true }
            }
        }
    }
}
