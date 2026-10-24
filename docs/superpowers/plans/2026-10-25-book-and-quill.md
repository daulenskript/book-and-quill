# Book & Quill for Mac Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A native macOS notes app where each note is a Minecraft Java Book & Quill and the note list looks like Select World.

**Architecture:** SwiftPM package with a pure-logic library target (`BookCore`: Note, NoteStore, Pagination) unit-tested with Swift Testing, and an executable SwiftUI target (`BookAndQuill`) for all screens. `build.sh` wraps the release binary into `BookAndQuill.app`.

**Tech Stack:** Swift 6.4, SwiftUI, AppKit (NSTextView bridge, NSSound), Swift Testing, Command Line Tools only (no Xcode project).

**Spec:** `docs/superpowers/specs/2026-10-25-book-and-quill-design.md`

## Global Constraints
- macOS 14+ (`platforms: [.macOS(.v14)]`); no third-party Swift dependencies.
- No Mojang assets. Font: Monocraft (SIL OFL 1.1, github.com/IdreesInc/Monocraft), licence file bundled. All textures/icon/sound generated in code.
- Notes dir: `~/Library/Application Support/BookAndQuill/notes/`, one `<uuid>.json` per note, ISO8601 dates, atomic writes.
- Page capacity 14 wrapped lines; max 100 pages; sign title max 32 chars.
- Button copy exactly as spec: `Open Selected Note`, `Create New Note`, `Rename`, `Delete`, `Re-Create`, `Cancel`, `Save`, `Sign`, `Done`, `Sign and Close`.
- Delete copy: "Are you sure you want to delete this note?" / "'<title>' will be lost forever! (A long time!)".

## Review Focus
- Pasting a huge block of text into a page → must spill across pages, stop at 100 pages, never crash or lose the visible text silently (excess beyond page 100 is dropped). Test in Task 2.
- A single word longer than a page line / page with no spaces → reflow must still terminate. Test in Task 2.
- Corrupt or non-JSON file in notes dir → skipped, not deleted, other notes still load. Test in Task 3.
- Search with empty / whitespace query → returns all notes. Test in Task 3.
- Quitting app mid-typing → pending autosave flushed on `NSApplication.willTerminateNotification` (manual check in Task 7).

---

### Task 1: Package skeleton, Note model, test harness

**Files:**
- Create: `Package.swift`, `Sources/BookCore/Note.swift`, `Sources/BookAndQuill/App.swift` (placeholder window), `Tests/BookCoreTests/NoteTests.swift`

**Interfaces:**
- Produces: `public struct Note: Codable, Identifiable, Equatable { public var id: UUID; title: String; author: String?; pages: [String]; created: Date; modified: Date }`, `public init(title: String, now: Date = .now)` → one empty page; `public var preview: String` (first 40 chars of joined pages, newlines → spaces).

- [ ] Step 1: Write `NoteTests.testNewNoteHasOneEmptyPage` and `testPreviewTruncatesTo40AndFlattensNewlines` using `import Testing`.
- [ ] Step 2: `swift test` → fails to compile (no Note). If Swift Testing is unavailable under CLT, fall back to XCTest; if neither, stop and report.
- [ ] Step 3: Implement Note; Package.swift with targets `BookCore` (library), `BookAndQuill` (executable, depends on BookCore, `resources: [.process("Resources")]`), `BookCoreTests`.
- [ ] Step 4: `swift test` → PASS; `swift build` → succeeds.
- [ ] Step 5: Commit `feat: package skeleton and Note model`.

### Task 2: Pagination (pure)

**Files:** Create `Sources/BookCore/Pagination.swift`, `Tests/BookCoreTests/PaginationTests.swift`

**Interfaces:**
- Produces: `public enum Pagination { static let maxPages = 100; static func reflow(_ pages: [String], from index: Int, fits: (String) -> Bool) -> [String]; static func trimTrailingEmpty(_ pages: [String]) -> [String] }`

`reflow`: starting at `index`, while a page doesn't fit, move the shortest possible suffix (break at last whitespace/newline; if none, last character) to the front of the next page (creating it), then continue with the next page. Stop at `maxPages`; overflow past the last page is dropped. Pages before `index` untouched.

- [ ] Step 1: Tests with `fits = { $0.count <= 10 }`:
  - `reflow(["hello world foo"], from: 0)` == `["hello ", "world foo"]`
  - text of 25 non-space chars → `["aaaaaaaaaa","aaaaaaaaaa","aaaaa"]` (terminates)
  - overflow pushes into existing next page: `["abcdefghij k", "xy"]` → `["abcdefghij ", "kxy"]`
  - 2000 chars → `count == 100`, every page fits
  - `trimTrailingEmpty(["a","",""])` == `["a"]`; `trimTrailingEmpty(["",""])` == `[""]`
- [ ] Step 2: `swift test` → FAIL.
- [ ] Step 3: Implement.
- [ ] Step 4: `swift test` → PASS.
- [ ] Step 5: Commit `feat: page reflow and trimming`.

### Task 3: NoteStore

**Files:** Create `Sources/BookCore/NoteStore.swift`, `Tests/BookCoreTests/NoteStoreTests.swift`

**Interfaces:**
- Consumes: `Note`.
- Produces: `@MainActor public final class NoteStore: ObservableObject` with `@Published public private(set) var notes: [Note]` (sorted modified desc), `init(directory: URL)`, `static var defaultDirectory: URL`, `func load()`, `func create(title: String) -> Note`, `func save(_ note: Note)` (sets `modified = .now`, atomic write, re-sorts), `func rename(id: UUID, to: String)` (empty → no change), `func duplicate(id: UUID) -> Note?` (title "<t> (Copy)", new id/dates), `func delete(id: UUID)`, `func search(_ query: String) -> [Note]`.

- [ ] Step 1: Tests in a temp dir: create→new store `load()` round-trips; duplicate title + distinct id; delete removes file; rename empty keeps title; `create(title: "  ")` → "New Note"; search case-insensitive on title and content, whitespace query → all; a `junk.json` with garbage is skipped and still exists after load.
- [ ] Step 2: `swift test` → FAIL.
- [ ] Step 3: Implement (JSONEncoder `.iso8601`, `write(to:options:.atomic)`).
- [ ] Step 4: `swift test` → PASS.
- [ ] Step 5: Commit `feat: note storage`.

### Task 4: Minecraft UI kit + font

**Files:** Create `Sources/BookAndQuill/UI/MinecraftStyle.swift`, `UI/MCButton.swift`, `UI/MCTextField.swift`, `UI/DirtBackground.swift`, `UI/PixelArt.swift`, `Resources/Monocraft.ttf`, `Resources/OFL.txt`

**Interfaces:**
- Produces: `enum MC { static func font(_ size: CGFloat) -> Font; static func nsFont(_ size: CGFloat) -> NSFont; static func registerFont() }` (CTFontManagerRegisterFontsForURL from `Bundle.module`); `struct MCButton(_ title: String, width: CGFloat = 200, enabled: Bool = true, action: () -> Void)`; `struct MCTextField(_ text: Binding<String>, placeholder: String = "")`; `struct DirtBackground: View`; `enum PixelArt { static func image(_ rows: [String], palette: [Character: NSColor], scale: Int) -> NSImage }` used for dirt tile, book icon, page arrows.
- Visual values: button face #6F6F6F, top/left edge #AAAAAA, bottom/right #555555, outline black, hover outline #FFFFFF-ish / face #7E88BF, disabled face #2C2C2C text #A0A0A0; text white with #3F3F3F 2px shadow; field fill black, border #A0A0A0 / focused white; dirt base #593D29 darkened 75% with speckles.

- [ ] Step 1: Download Monocraft.ttf + licence from the GitHub release into Resources; verify `file` reports TrueType.
- [ ] Step 2: Implement the kit; temporary preview of all components in App.swift.
- [ ] Step 3: `swift build` → succeeds; `swift run` and screenshot (`screencapture -l <windowid>`) → buttons/field/dirt look Minecraft-like.
- [ ] Step 4: Commit `feat: minecraft UI kit`.

### Task 5: Select Note, Create, Rename, Delete screens + routing

**Files:** Create `Sources/BookAndQuill/Screens/SelectNoteView.swift`, `CreateNoteView.swift`, `RenameView.swift`, `ConfirmDeleteView.swift`; modify `App.swift`.

**Interfaces:**
- Consumes: `NoteStore`, UI kit.
- Produces: `enum Screen: Equatable { case select, create, rename(UUID), confirmDelete(UUID), book(UUID), sign(UUID) }` and `final class Router: ObservableObject { @Published var screen: Screen; @Published var selected: UUID? }` in App.swift. Window min size 860×560, titled "Book & Quill".

Behaviour per spec §1–4 (sort, single-click select with white outline, double-click open, disabled buttons when nothing selected, Re-Create selects copy, Cancel → `NSApp.terminate`, empty state "No notes yet", Enter/Esc on forms).

- [ ] Step 1: Implement screens and routing; `.book` shows a placeholder until Task 6.
- [ ] Step 2: `swift build`; `swift run`; manually create, rename, re-create, search, delete → files in notes dir change accordingly; screenshot.
- [ ] Step 3: Commit `feat: note select/create/rename/delete screens`.

### Task 6: Book editor + Sign

**Files:** Create `Sources/BookAndQuill/Screens/BookView.swift`, `Screens/PageTextView.swift` (NSViewRepresentable over NSTextView), `Screens/SignView.swift`, `UI/PageTurnSound.swift`.

**Interfaces:**
- Consumes: `Pagination.reflow/trimTrailingEmpty`, `NoteStore.save`, `Router`.
- `PageTextView(text: Binding<String>, onOverflow: () -> Void)`; `fits` closure built from NSLayoutManager line-fragment count ≤ 14 at page text width using `MC.nsFont(16)`, transparent background, black-ish text #000000.
- `PageTurnSound.play()`: short paper-flick synthesized once into an in-memory WAV (filtered noise burst ~120 ms) played with NSSound.

Behaviour per spec §5–6: "Page X of Y", ◀ hidden on page 1, ▶ on last page appends page (not beyond 100), ⌘←/⌘→ & PageUp/PageDown, Esc = Done; on each edit run `reflow(from: current)` and if text moved off current page and cursor was at end, advance page; autosave debounced 0.5 s + on page turn/Done/`willTerminate`; Done trims and returns to select with note selected. Sign screen: "Enter Book Title", field (≤32 chars), "by <NSFullUserName()>", Sign and Close sets title+author → back to book; Cancel → back to book.

- [ ] Step 1: Implement.
- [ ] Step 2: `swift build`; `swift run`; manual: type past a page → spills to page 2 and cursor follows; paste long text → many pages; arrows/shortcuts; sign; Done trims empties; reopen shows content; screenshot.
- [ ] Step 3: Commit `feat: book editor and signing`.

### Task 7: App bundle, icon, push

**Files:** Create `build.sh`, `Support/Info.plist`, `Sources/IconGen/main.swift` (executable target that renders the pixel book icon to PNGs), `README.md`.

- [ ] Step 1: `build.sh`: `swift build -c release`, run IconGen → iconset → `iconutil` → `.icns`, assemble `BookAndQuill.app/Contents/{MacOS,Resources,Info.plist}`, copy SwiftPM resource bundle, ad-hoc `codesign -s -`.
- [ ] Step 2: `./build.sh && open BookAndQuill.app` → launches with icon, notes persist; quit mid-typing then reopen → text kept.
- [ ] Step 3: `swift test` → all PASS.
- [ ] Step 4: README (build/run, data location, font credit). Commit `feat: app bundle and icon`.
- [ ] Step 5: Create GitHub repo `book-and-quill` under the user's account and push `main`.
