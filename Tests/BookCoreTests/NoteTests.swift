import Testing
import Foundation
@testable import BookCore

@Test func newNoteHasOneEmptyPage() {
    let note = Note(title: "Diary")
    #expect(note.title == "Diary")
    #expect(note.pages == [""])
    #expect(note.author == nil)
}

@Test func previewTruncatesTo40AndFlattensNewlines() {
    var note = Note(title: "x")
    note.pages = ["line one\nline two", String(repeating: "a", count: 50)]
    #expect(note.preview.count == 40)
    #expect(!note.preview.contains("\n"))
    #expect(note.preview.hasPrefix("line one line two"))
}
