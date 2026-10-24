import Testing
@testable import BookCore

private let fits: (String) -> Bool = { $0.count <= 10 }

@Test func overflowBreaksAtWordBoundary() {
    #expect(Pagination.reflow(["hello world foo"], from: 0, fits: fits) == ["hello ", "world foo"])
}

@Test func longWordWithoutSpacesStillTerminates() {
    let pages = Pagination.reflow([String(repeating: "a", count: 25)], from: 0, fits: fits)
    #expect(pages == ["aaaaaaaaaa", "aaaaaaaaaa", "aaaaa"])
}

@Test func overflowPushesIntoExistingNextPage() {
    #expect(Pagination.reflow(["abcdefghi k", "xy"], from: 0, fits: fits) == ["abcdefghi ", "kxy"])
}

@Test func pagesBeforeIndexAreUntouched() {
    let pages = Pagination.reflow(["way too long text", "hello world foo"], from: 1, fits: fits)
    #expect(pages == ["way too long text", "hello ", "world foo"])
}

@Test func hugePasteStopsAtMaxPages() {
    let pages = Pagination.reflow([String(repeating: "word ", count: 400)], from: 0, fits: fits)
    #expect(pages.count == Pagination.maxPages)
    #expect(pages.allSatisfy(fits))
}

@Test func trimRemovesTrailingEmptyPagesButKeepsOne() {
    #expect(Pagination.trimTrailingEmpty(["a", "", ""]) == ["a"])
    #expect(Pagination.trimTrailingEmpty(["", ""]) == [""])
    #expect(Pagination.trimTrailingEmpty(["", "b"]) == ["", "b"])
}
