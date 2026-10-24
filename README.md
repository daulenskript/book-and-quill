# Book & Quill

A tiny macOS notes app where every note is a Minecraft-style **Book & Quill**,
and picking a note works like Minecraft's **Select World** screen.

- **Select Note** – search, open, create, rename, delete, re-create (copy)
- **Book** – one page at a time, `Page X of Y`, arrow buttons to turn pages,
  14 lines per page; text that doesn't fit spills onto the next page (up to 100 pages)
- **Sign** – give the book a title, signed by your macOS name (it stays editable)
- Autosaves as you type

## Build & run

Requires macOS 14+ and the Swift toolchain (Xcode or Command Line Tools).

```bash
./build.sh                # builds BookAndQuill.app
open BookAndQuill.app     # or drag it into /Applications
```

During development: `swift run BookAndQuill`, tests: `swift test`.

## Keyboard

| Key | Action |
| --- | --- |
| ⌘← / ⌘→, Page Up / Page Down | Previous / next page |
| Esc | Done (close the book) |
| Return | Open selected note / confirm dialogs |

## Where notes live

`~/Library/Application Support/BookAndQuill/notes/` – one JSON file per note.

Developer env vars: `BOOKANDQUILL_NOTES_DIR` (use another notes folder),
`BOOKANDQUILL_SCREEN` + `BOOKANDQUILL_SNAPSHOT` (open a screen and save a PNG of the window),
`BOOKANDQUILL_TYPE` (simulate typing into the book).

## Credits

- Font: [Monocraft](https://github.com/IdreesInc/Monocraft) by Idrees Hassan, SIL Open Font License 1.1
  (bundled licence: `Sources/BookAndQuill/Resources/Monocraft-OFL.txt`).
- All textures, the icon and the page-turn sound are generated in code.
- Not affiliated with Mojang or Microsoft. Minecraft is a trademark of Mojang Synergies AB.
