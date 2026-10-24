import SwiftUI
import BookCore

/// Opens the note with the given id, or falls back to the list if it vanished.
struct BookScreen: View {
    let id: UUID
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var router: Router

    var body: some View {
        if let note = store.note(id: id) {
            BookView(note: note, store: store, router: router).id(id)
        } else {
            Color.clear.onAppear { router.screen = .select }
        }
    }
}

/// The Book & Quill editor: one page, "Page X of Y", arrows, Sign and Done.
struct BookView: View {
    @StateObject private var editor: BookEditor
    private let router: Router

    init(note: Note, store: NoteStore, router: Router) {
        _editor = StateObject(wrappedValue: BookEditor(note: note, store: store))
        self.router = router
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            ZStack(alignment: .topLeading) {
                BookPageBackground()
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Text("Page \(editor.page + 1) of \(editor.pageCount)")
                            .font(MC.font(16))
                            .foregroundStyle(MC.ink)
                    }
                    PageTextView(editor: editor, onDone: done)
                        .frame(width: BookPage.textWidth, height: BookPage.textHeight)
                    HStack {
                        if !editor.isFirstPage {
                            PageArrow(right: false) { editor.previousPage() }
                        }
                        Spacer()
                        if editor.canGoForward {
                            PageArrow(right: true) { editor.nextPage() }
                        }
                    }
                    .frame(height: 30)
                }
                .frame(width: BookPage.textWidth)
                .padding(.leading, 50)
                .padding(.trailing, 30)
                .padding(.top, 22)
            }
            .frame(width: BookPage.size.width, height: BookPage.size.height)

            HStack(spacing: 8) {
                MCButton("Sign", width: 186) {
                    editor.saveNow()
                    router.screen = .sign(editor.note.id)
                }
                MCButton("Done", width: 186, action: done)
            }
            Spacer(minLength: 0)
        }
    }

    private func done() {
        editor.finish()
        router.selected = editor.note.id
        router.screen = .select
    }
}
