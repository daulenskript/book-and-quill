import SwiftUI
import BookCore

/// "Enter Book Title" screen. Signing only sets the title and author; the note stays editable.
struct SignView: View {
    static let maxTitleLength = 32

    let id: UUID
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var router: Router
    @StateObject private var title = Local("")
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            ZStack {
                BookPageBackground()
                VStack(spacing: 14) {
                    Text("Enter Book Title:")
                        .font(MC.font(18))
                        .foregroundStyle(MC.ink)
                    TextField("", text: $title.value)
                        .textFieldStyle(.plain)
                        .font(MC.font(18))
                        .foregroundStyle(MC.ink)
                        .multilineTextAlignment(.center)
                        .frame(width: BookPage.textWidth)
                        .focused($focused)
                        .onSubmit(sign)
                    Text("by \(NSFullUserName())")
                        .font(MC.font(16))
                        .foregroundStyle(Color(hex: 0x6B6B6B))
                }
                .padding(.leading, 12)
            }
            .frame(width: BookPage.size.width, height: BookPage.size.height)

            HStack(spacing: 8) {
                MCButton("Sign and Close", width: 186, shortcut: .defaultAction, action: sign)
                MCButton("Cancel", width: 186, shortcut: .cancelAction) { router.screen = .book(id) }
            }
            Spacer(minLength: 0)
        }
        .onAppear {
            title.value = String((store.note(id: id)?.title ?? "").prefix(Self.maxTitleLength))
            DispatchQueue.main.async { focused = true }
        }
        .onChange(of: title.value) { _, new in
            if new.count > Self.maxTitleLength { title.value = String(new.prefix(Self.maxTitleLength)) }
        }
    }

    private func sign() {
        if var note = store.note(id: id) {
            let trimmed = title.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { note.title = trimmed }
            note.author = NSFullUserName()
            store.save(note)
        }
        router.screen = .book(id)
    }
}
