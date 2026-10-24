import SwiftUI
import BookCore

struct ConfirmDeleteView: View {
    let id: UUID
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            MCText("Are you sure you want to delete this note?")
            MCText("'\(store.note(id: id)?.title ?? "")' will be lost forever! (A long time!)", color: MC.textGrey)
            Spacer()
            HStack(spacing: 8) {
                MCButton("Delete", width: 300) {
                    store.delete(id: id)
                    router.selected = nil
                    router.screen = .select
                }
                MCButton("Cancel", width: 300, shortcut: .cancelAction) { router.screen = .select }
            }
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 24)
        .multilineTextAlignment(.center)
        .background(Color(hex: 0x3A0000).opacity(0.5))
    }
}
