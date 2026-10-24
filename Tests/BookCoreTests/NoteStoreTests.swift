import Testing
import Foundation
@testable import BookCore

// Free functions: suite structs hit a missing TestingMacros plugin under Command Line Tools.
@MainActor
private func makeStore(_ dir: URL) -> NoteStore {
let store = NoteStore(directory: dir)
store.load()
return store
}

private func tempDir() -> URL {
FileManager.default.temporaryDirectory.appendingPathComponent("BookAndQuillTests-\(UUID().uuidString)")
}

@MainActor @Test func createdNoteSurvivesReload() {
    let dir = tempDir()
    var note = makeStore(dir).create(title: "Diary")
    note.pages = ["dear diary"]
    let store = makeStore(dir)
    store.save(note)
    let reloaded = makeStore(dir)
    #expect(reloaded.notes.count == 1)
    #expect(reloaded.notes[0].pages == ["dear diary"])
    #expect(reloaded.notes[0].title == "Diary")
}

@MainActor @Test func blankTitleBecomesNewNote() {
    let dir = tempDir()
    #expect(makeStore(dir).create(title: "  ").title == "New Note")
}

@MainActor @Test func duplicateGetsCopySuffixAndNewId() throws {
    let dir = tempDir()
    let store = makeStore(dir)
    let original = store.create(title: "Ideas")
    let copy = try #require(store.duplicate(id: original.id))
    #expect(copy.title == "Ideas (Copy)")
    #expect(copy.id != original.id)
    #expect(makeStore(dir).notes.count == 2)
}

@MainActor @Test func deleteRemovesFile() {
    let dir = tempDir()
    let store = makeStore(dir)
    let note = store.create(title: "Gone")
    store.delete(id: note.id)
    #expect(store.notes.isEmpty)
    #expect(makeStore(dir).notes.isEmpty)
}

@MainActor @Test func renameIgnoresBlankName() {
    let dir = tempDir()
    let store = makeStore(dir)
    let note = store.create(title: "Keep")
    store.rename(id: note.id, to: "   ")
    #expect(store.notes[0].title == "Keep")
    store.rename(id: note.id, to: "Changed")
    #expect(makeStore(dir).notes[0].title == "Changed")
}

@MainActor @Test func searchIsCaseInsensitiveOverTitleAndContent() {
    let dir = tempDir()
    let store = makeStore(dir)
    _ = store.create(title: "Shopping")
    var other = store.create(title: "Plans")
    other.pages = ["build a CASTLE"]
    store.save(other)
    #expect(store.search("shop").map(\.title) == ["Shopping"])
    #expect(store.search("castle").map(\.title) == ["Plans"])
    #expect(store.search("   ").count == 2)
}

@MainActor @Test func corruptFileIsSkippedNotDeleted() throws {
    let dir = tempDir()
    let store = makeStore(dir)
    _ = store.create(title: "Fine")
    let junk = dir.appendingPathComponent("junk.json")
    try Data("not json".utf8).write(to: junk)
    let reloaded = makeStore(dir)
    #expect(reloaded.notes.map(\.title) == ["Fine"])
    #expect(FileManager.default.fileExists(atPath: junk.path))
}

@MainActor @Test func notesSortedNewestFirst() {
    let dir = tempDir()
    let store = makeStore(dir)
    let first = store.create(title: "First")
    _ = store.create(title: "Second")
    store.save(first)
    #expect(store.notes.map(\.title) == ["First", "Second"])
}

