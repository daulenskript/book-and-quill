import Foundation

/// Pure page-splitting logic. `fits` decides whether a string fits on one page,
/// so the app can measure real wrapped lines while tests use a simple rule.
public enum Pagination {
    public static let maxPages = 100

    /// Pushes overflowing text forward page by page, starting at `index`.
    /// Text that would land past `maxPages` is dropped.
    public static func reflow(_ pages: [String], from index: Int, fits: (String) -> Bool) -> [String] {
        var pages = pages
        var i = max(0, index)
        while i < pages.count {
            let page = pages[i]
            if fits(page) { break }
            let cut = splitPoint(page, fits: fits)
            let moved = String(page[cut...])
            pages[i] = String(page[..<cut])
            if i + 1 < pages.count {
                pages[i + 1] = moved + pages[i + 1]
            } else if i + 1 < maxPages {
                pages.append(moved)
            }
            i += 1
        }
        return pages
    }

    /// Drops empty pages at the end, always keeping at least one page.
    public static func trimTrailingEmpty(_ pages: [String]) -> [String] {
        var pages = pages
        while pages.count > 1, pages.last?.isEmpty == true { pages.removeLast() }
        return pages.isEmpty ? [""] : pages
    }

    /// Index where the page should be cut: after the most whole words that fit,
    /// or after the most characters that fit when even one word is too long.
    private static func splitPoint(_ page: String, fits: (String) -> Bool) -> String.Index {
        // Word chunk boundaries: positions right after each run of whitespace.
        var ends: [String.Index] = []
        var idx = page.startIndex
        while idx < page.endIndex {
            let next = page.index(after: idx)
            if page[idx].isWhitespace, next == page.endIndex || !page[next].isWhitespace {
                ends.append(next)
            }
            idx = next
        }
        if let best = largest(ends, where: { fits(String(page[..<$0])) }) { return best }

        let chars = Array(page.indices.dropFirst()) + [page.endIndex]
        // Always move at least the overflow, and keep at least one character for progress.
        return largest(chars, where: { fits(String(page[..<$0])) }) ?? chars[0]
    }

    /// Binary search for the last element satisfying a monotonic (true…false) predicate.
    private static func largest<T>(_ items: [T], where ok: (T) -> Bool) -> T? {
        var lo = 0, hi = items.count - 1, found: T?
        while lo <= hi {
            let mid = (lo + hi) / 2
            if ok(items[mid]) { found = items[mid]; lo = mid + 1 } else { hi = mid - 1 }
        }
        return found
    }
}
