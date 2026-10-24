import AppKit
import BookCore

/// Developer aid: `BOOKANDQUILL_SNAPSHOT=/path/out.png` saves the window as a PNG
/// shortly after launch, then quits. Used to check the UI without screen capture.
enum DebugSnapshot {
    @MainActor
    static func scheduleIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["BOOKANDQUILL_SNAPSHOT"] else { return }
        let typed = ProcessInfo.processInfo.environment["BOOKANDQUILL_TYPE"] ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { type(Array(typed)) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 + Double(typed.count) * 0.01) {
            guard let view = NSApp.windows.first(where: \.isVisible)?.contentView,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { exit(1) }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            NSApp.terminate(nil)
        }
    }
}

extension DebugSnapshot {
    /// Types characters one per run-loop pass into the open page, like a fast typist.
    @MainActor
    private static func type(_ chars: [Character]) {
        guard let first = chars.first,
              let view = NSApp.windows.first?.firstResponder as? NSTextView else { return }
        view.insertText(String(first), replacementRange: view.selectedRange())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { type(Array(chars.dropFirst())) }
    }

    /// `BOOKANDQUILL_SCREEN=book|sign|create|delete|rename` opens that screen on the first note.
    @MainActor
    static func applyInitialScreen(store: NoteStore, router: Router) {
        guard let name = ProcessInfo.processInfo.environment["BOOKANDQUILL_SCREEN"] else { return }
        let id = store.notes.first?.id
        router.selected = id
        switch (name, id) {
        case ("create", _): router.screen = .create
        case ("book", let id?): router.screen = .book(id)
        case ("sign", let id?): router.screen = .sign(id)
        case ("delete", let id?): router.screen = .confirmDelete(id)
        case ("rename", let id?): router.screen = .rename(id)
        default: break
        }
    }
}
