import SwiftUI
import BookCore

/// The "Select World" screen, for notes.
struct SelectNoteView: View {
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var router: Router
    @StateObject private var query = Local("")

    private var results: [Note] { store.search(query.value) }
    private var hasSelection: Bool { router.selected.flatMap(store.note(id:)) != nil }

    var body: some View {
        VStack(spacing: 12) {
            MCText("Select Note").padding(.top, 18)
            MCTextField(text: $query.value, placeholder: "Search...", width: 440)

            list

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    MCButton("Open Selected Note", width: 300, enabled: hasSelection, shortcut: .defaultAction) { open() }
                    MCButton("Create New Note", width: 300) { router.screen = .create }
                }
                HStack(spacing: 8) {
                    MCButton("Rename", width: 146, enabled: hasSelection) {
                        if let id = router.selected { router.screen = .rename(id) }
                    }
                    MCButton("Delete", width: 146, enabled: hasSelection) {
                        if let id = router.selected { router.screen = .confirmDelete(id) }
                    }
                    MCButton("Re-Create", width: 146, enabled: hasSelection) {
                        if let id = router.selected, let copy = store.duplicate(id: id) {
                            router.selected = copy.id
                        }
                    }
                    MCButton("Cancel", width: 146) { NSApp.terminate(nil) }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private var list: some View {
        ZStack {
            Color.black.opacity(0.45)
            if results.isEmpty {
                MCText(store.notes.isEmpty ? "No notes yet" : "No matching notes", color: MC.textGrey)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(results) { note in
                            NoteRow(note: note, selected: note.id == router.selected)
                                .onTapGesture(count: 2) {
                                    router.selected = note.id
                                    open()
                                }
                                .simultaneousGesture(TapGesture().onEnded { router.selected = note.id })
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.never)
            }
        }
        .overlay(alignment: .top) { edgeShadow(.top) }
        .overlay(alignment: .bottom) { edgeShadow(.bottom) }
    }

    private func edgeShadow(_ edge: VerticalEdge) -> some View {
        LinearGradient(colors: [.black.opacity(0.8), .clear],
                       startPoint: edge == .top ? .top : .bottom,
                       endPoint: edge == .top ? .bottom : .top)
            .frame(height: 8)
            .allowsHitTesting(false)
    }

    private func open() {
        guard let id = router.selected, store.note(id: id) != nil else { return }
        router.screen = .book(id)
    }
}

private struct NoteRow: View {
    let note: Note
    let selected: Bool

    private static let dateFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(nsImage: Sprites.bookIcon)
                .pixelated()
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                MCText(note.title)
                Text(subtitle).font(MC.font(14)).foregroundStyle(Color(hex: 0x808080))
                Text(note.preview.isEmpty ? "Empty note" : note.preview)
                    .font(MC.font(14)).foregroundStyle(Color(hex: 0x808080))
            }
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(width: 540, alignment: .leading)
        .background(selected ? Color.black : Color.clear)
        .overlay(Rectangle().strokeBorder(selected ? MC.textGrey : .clear, lineWidth: 2))
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        let date = Self.dateFormat.string(from: note.modified)
        return note.author.map { "\(date)  by \($0)" } ?? date
    }
}
