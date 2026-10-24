import Foundation

/// A single Book & Quill note: a title plus a list of pages.
public struct Note: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var author: String?
    public var pages: [String]
    public var created: Date
    public var modified: Date

    public init(title: String, now: Date = .now) {
        id = UUID()
        self.title = title
        author = nil
        pages = [""]
        created = now
        modified = now
    }

    /// First 40 characters of the note's text on a single line.
    public var preview: String {
        let flat = pages.joined(separator: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        return String(flat.prefix(40))
    }
}
