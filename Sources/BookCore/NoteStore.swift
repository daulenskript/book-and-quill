import Foundation
import Combine

/// Loads and saves notes as one JSON file per note in a directory.
@MainActor
public final class NoteStore: ObservableObject {
    @Published public private(set) var notes: [Note] = []
    public let directory: URL

    public nonisolated static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BookAndQuill/notes", isDirectory: true)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public init(directory: URL = NoteStore.defaultDirectory) {
        self.directory = directory
    }

    public func load() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        notes = files.filter { $0.pathExtension == "json" }.compactMap { url in
            do {
                return try decoder.decode(Note.self, from: Data(contentsOf: url))
            } catch {
                NSLog("BookAndQuill: skipping unreadable note %@: %@", url.lastPathComponent, "\(error)")
                return nil
            }
        }
        sort()
    }

    public func note(id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    @discardableResult
    public func create(title: String) -> Note {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = Note(title: trimmed.isEmpty ? "New Note" : trimmed)
        write(note)
        return note
    }

    /// Saves the note and marks it as just edited.
    public func save(_ note: Note) {
        var note = note
        note.modified = .now
        write(note)
    }

    public func rename(id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var note = note(id: id) else { return }
        note.title = trimmed
        save(note)
    }

    public func duplicate(id: UUID) -> Note? {
        guard let original = note(id: id) else { return nil }
        var copy = Note(title: original.title + " (Copy)")
        copy.author = original.author
        copy.pages = original.pages
        write(copy)
        return copy
    }

    public func delete(id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(id))
        notes.removeAll { $0.id == id }
    }

    public func search(_ query: String) -> [Note] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return notes }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(q)
                || note.pages.contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }

    private func write(_ note: Note) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try encoder.encode(note).write(to: fileURL(note.id), options: .atomic)
        } catch {
            NSLog("BookAndQuill: failed to save note %@: %@", note.id.uuidString, "\(error)")
        }
        if let i = notes.firstIndex(where: { $0.id == note.id }) {
            notes[i] = note
        } else {
            notes.append(note)
        }
        sort()
    }

    private func sort() {
        notes.sort { $0.modified > $1.modified }
    }

    private func fileURL(_ id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }
}
