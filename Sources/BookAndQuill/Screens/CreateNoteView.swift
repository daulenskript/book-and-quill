import SwiftUI
import BookCore

/// "Create New World", for notes.
struct CreateNoteView: View {
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var router: Router
    @StateObject private var name = Local("New Note")

    var body: some View {
        VStack(spacing: 0) {
            MCText("Create New Note").padding(.top, 18)
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                MCText("Note Name", color: MC.textGrey)
                MCTextField(text: $name.value, onSubmit: create, autofocus: true)
            }
            Spacer()
            HStack(spacing: 8) {
                MCButton("Create New Note", width: 300, shortcut: .defaultAction, action: create)
                MCButton("Cancel", width: 300, shortcut: .cancelAction) { router.screen = .select }
            }
            .padding(.bottom, 18)
        }
    }

    private func create() {
        let note = store.create(title: name.value)
        router.selected = note.id
        router.screen = .book(note.id)
    }
}
