import AppKit
import BookCore

/// Editing state for one open book: current page, cursor and autosave.
@MainActor
final class BookEditor: ObservableObject {
    @Published private(set) var note: Note
    @Published private(set) var page = 0
    /// UTF-16 cursor offset the text view should show after a page change or reflow.
    private(set) var cursor = 0

    private let store: NoteStore
    private let fits: (String) -> Bool
    private var saveTask: Task<Void, Never>?
    private var terminateObserver: NSObjectProtocol?

    init(note: Note, store: NoteStore, fits: @escaping (String) -> Bool = BookPage.fits) {
        self.note = note
        self.store = store
        self.fits = fits
        cursor = (note.pages[0] as NSString).length
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveNow() }
        }
    }

    deinit {
        if let terminateObserver { NotificationCenter.default.removeObserver(terminateObserver) }
    }

    var text: String { note.pages[page] }
    var pageCount: Int { note.pages.count }
    var isFirstPage: Bool { page == 0 }
    var canGoForward: Bool { page < Pagination.maxPages - 1 }

    /// Called on every keystroke. Overflow spills to the next page and the cursor follows it.
    func edit(_ newText: String, cursor newCursor: Int) {
        note.pages[page] = newText
        note.pages = Pagination.reflow(note.pages, from: page, fits: fits)
        let kept = (note.pages[page] as NSString).length
        if newCursor > kept, page + 1 < note.pages.count {
            page += 1
            cursor = min(newCursor - kept, (note.pages[page] as NSString).length)
        } else {
            cursor = min(newCursor, kept)
        }
        scheduleSave()
    }

    func nextPage() {
        guard canGoForward else { return }
        if page == note.pages.count - 1 { note.pages.append("") }
        turn(to: page + 1)
    }

    func previousPage() {
        guard page > 0 else { return }
        turn(to: page - 1)
    }

    /// Trims trailing blank pages and saves; used by Done.
    func finish() {
        note.pages = Pagination.trimTrailingEmpty(note.pages)
        page = min(page, note.pages.count - 1)
        saveNow()
    }

    func saveNow() {
        saveTask?.cancel()
        saveTask = nil
        store.save(note)
    }

    private func turn(to newPage: Int) {
        page = newPage
        cursor = (note.pages[page] as NSString).length
        PageTurnSound.play()
        saveNow()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }
}
