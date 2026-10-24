# Book & Quill for Mac — Design Spec

Date: 2026-10-25

## Goal
A personal, offline macOS notes app where every note is a Minecraft Java-edition
Book & Quill, and choosing/creating notes looks like Minecraft's Select World /
Create New World screens. Simple notes only — no sync, folders, or rich text.

## Platform & Tech
- Native SwiftUI app, macOS 14+, built with Swift Package Manager (no Xcode project).
- A build script (`build.sh`) compiles a release binary and wraps it into
  `BookAndQuill.app` (Info.plist, icon, bundled font).
- No third-party Swift dependencies.

## Visual Style (all original, no Mojang assets)
- Background: tiled dark dirt texture generated in code (16×16 pixel pattern,
  scaled with nearest-neighbour).
- Buttons: Minecraft-style grey bevelled buttons (light top-left edge, dark
  bottom-right edge, black outline); hover = blue-ish highlight border;
  disabled = darker grey with grey text.
- Text fields: black fill, grey 1px border, white border when focused.
- Font: a free pixel font with a reuse-permitting licence (e.g. OFL), bundled
  in the app; text drawn with a 1px dark drop shadow on menu screens.
- Book page: cream page with brown pixel border, drawn in code.
- App icon: pixel book-and-quill drawn in code and exported at build time.

## Screens

### 1. Select Note (launch screen)
- Title "Select Note" at top, search field below it.
- Scrollable list. Each row: 32px pixel book icon, note title (white), second
  line `<last edited date>` (grey), third line first ~40 chars of content (grey).
- Single click selects (white outline around row); double-click opens.
- Sorted by last edited, newest first.
- Search filters live, case-insensitive, by title or content.
- Buttons (2 rows):
  - `[Open Selected Note]` `[Create New Note]`
  - `[Rename]` `[Delete]` `[Re-Create]` `[Cancel]`
  - Open/Rename/Delete/Re-Create disabled when nothing is selected.
  - Re-Create duplicates the note as "<title> (Copy)" and selects the copy.
  - Cancel quits the app.
- Empty state: list area shows "No notes yet" in grey.

### 2. Create New Note
- Title "Create New Note", label "Note Name", text field prefilled with
  "New Note" (focused and selected).
- `[Create New Note]` `[Cancel]`. Enter = create, Esc = cancel.
- Create makes the note with one empty page and opens the book.
- Empty name → "New Note". Duplicate names are allowed.

### 3. Rename
- Title "Rename Note", text field with current title.
- `[Save]` `[Cancel]`. Empty name keeps the old title.

### 4. Delete Confirmation
- "Are you sure you want to delete this note?"
- "'<title>' will be lost forever! (A long time!)"
- `[Delete]` `[Cancel]`. Delete removes the file and returns to the list.

### 5. Book (editor) — Java single-page layout
- Centered cream page on the dirt background.
- "Page X of Y" top-right of page.
- Editable text area for the current page. Page capacity: 14 lines at the
  page's fixed width; text that would exceed capacity is not accepted on the
  current page — instead overflow moves to the start of the next page
  (creating it if needed) and the cursor follows.
- Page turn arrows bottom of page: ◀ hidden on page 1; ▶ on the last page
  creates a new empty page (max 100 pages, as in Minecraft).
- Keyboard: ⌘← / ⌘→ and PageUp / PageDown turn pages (plain arrows stay
  for cursor movement inside text). Esc = Done.
- Short page-turn sound (synthesised/bundled original sound) on page change.
- Below the book: `[Sign]` `[Done]`.
- Done: trims trailing empty pages (always keep at least one), saves, returns
  to Select Note with this note selected.

### 6. Sign
- Same page style: "Enter Book Title" heading, title text field (prefilled with
  current title, max 32 characters), "by <macOS full user name>".
- `[Sign and Close]` `[Cancel]`.
- Sign and Close sets title + author, saves, and returns to the book editor.
  The note stays editable (signing does not lock).

## Data & Storage
- Folder: `~/Library/Application Support/BookAndQuill/notes/`
- One JSON file per note, named `<uuid>.json`:
  ```json
  { "id": "uuid", "title": "string", "author": "string|null",
    "pages": ["string", ...], "created": "ISO8601", "modified": "ISO8601" }
  ```
- Autosave: edits saved ~0.5s after typing stops, and on page turn / Done /
  app quit. Writes are atomic (write temp file, then replace).
- Unreadable/corrupt files are skipped on load (logged), never deleted.

## Code Structure
```
Package.swift
Sources/BookAndQuill/
  App.swift                 app entry, window, screen routing
  Model/Note.swift          Note struct (Codable)
  Model/NoteStore.swift     load/save/create/duplicate/delete/rename/search
  Model/Pagination.swift    page capacity + overflow reflow + trimming (pure)
  UI/MinecraftStyle.swift   colours, font, pixel textures
  UI/MCButton.swift, UI/MCTextField.swift, UI/DirtBackground.swift
  Screens/SelectNoteView.swift, CreateNoteView.swift, RenameView.swift,
          ConfirmDeleteView.swift, BookView.swift, SignView.swift
  Resources/ (font, sound)
Tests/BookAndQuillTests/
  PaginationTests, NoteStoreTests (temp directory), SearchTests
build.sh                    builds BookAndQuill.app
```
- `Pagination` and `NoteStore` contain no UI code and are unit-tested.
  `Pagination` takes a `fits: (String) -> Bool` closure deciding whether text
  fits one page; the app supplies one that measures wrapped lines with the real
  font (≤ 14 lines), tests supply a simple character/line-count rule.
- Navigation: a single `enum Screen` state in the app root.

## Testing
- Unit tests: pagination overflow/reflow, page limit, trailing-page trimming,
  store round-trip, duplicate, delete, rename, search, corrupt file skipped.
- Manual check: build the .app, launch it, create/edit/sign/rename/copy/delete
  a note, verify files on disk.

## Out of Scope
Minecraft § colour codes, sync/iCloud, folders/tags, export, multiple windows,
read-only signed books.
