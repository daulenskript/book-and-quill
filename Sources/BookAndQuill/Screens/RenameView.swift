import SwiftUI
import BookCore

struct RenameView: View {
    let id: UUID
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var router: Router
    @StateObject private var name = Local("")

    var body: some View {
        VStack(spacing: 0) {
            MCText("Rename Note").padding(.top, 18)
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                MCText("Note Name", color: MC.textGrey)
                MCTextField(text: $name.value, onSubmit: save, autofocus: true)
            }
            Spacer()
            HStack(spacing: 8) {
                MCButton("Save", width: 300, shortcut: .defaultAction, action: save)
                MCButton("Cancel", width: 300, shortcut: .cancelAction) { router.screen = .select }
            }
            .padding(.bottom, 18)
        }
        .onAppear { name.value = store.note(id: id)?.title ?? "" }
    }

    private func save() {
        store.rename(id: id, to: name.value)
        router.screen = .select
    }
}
