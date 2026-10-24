import SwiftUI
import AppKit

/// Plain NSTextView sized to exactly one page, with page-turn keys.
final class PageNSTextView: NSTextView {
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}
    var onDone: () -> Void = {}

    override func keyDown(with event: NSEvent) {
        let command = event.modifierFlags.contains(.command)
        switch event.keyCode {
        case 116: onPrevious()                 // Page Up
        case 121: onNext()                     // Page Down
        case 123 where command: onPrevious()   // ⌘←
        case 124 where command: onNext()       // ⌘→
        default: super.keyDown(with: event)
        }
    }

    // Esc arrives as complete: or cancelOperation: depending on context.
    override func cancelOperation(_ sender: Any?) { onDone() }
    override func complete(_ sender: Any?) { onDone() }
}

struct PageTextView: NSViewRepresentable {
    @ObservedObject var editor: BookEditor
    let onDone: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(editor: editor) }

    func makeNSView(context: Context) -> PageNSTextView {
        let container = NSTextContainer(size: NSSize(width: BookPage.textWidth, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.widthTracksTextView = false
        let layout = NSLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)

        let view = PageNSTextView(
            frame: NSRect(x: 0, y: 0, width: BookPage.textWidth, height: BookPage.textHeight),
            textContainer: container
        )
        let ink = NSColor(hex: 0x1E1610)
        view.isRichText = false
        view.importsGraphics = false
        view.drawsBackground = false
        view.font = BookPage.font
        view.textColor = ink
        view.insertionPointColor = ink
        view.typingAttributes = [.font: BookPage.font, .foregroundColor: ink]
        view.textContainerInset = .zero
        view.isVerticallyResizable = false
        view.isHorizontallyResizable = false
        view.allowsUndo = true
        view.isAutomaticQuoteSubstitutionEnabled = false
        view.isAutomaticDashSubstitutionEnabled = false
        view.isAutomaticTextReplacementEnabled = false
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isContinuousSpellCheckingEnabled = false
        view.selectedTextAttributes = [.backgroundColor: NSColor(hex: 0x3F5FD0), .foregroundColor: NSColor.white]
        view.delegate = context.coordinator
        view.onPrevious = { editor.previousPage() }
        view.onNext = { editor.nextPage() }
        view.onDone = onDone
        return view
    }

    func updateNSView(_ view: PageNSTextView, context: Context) {
        let coordinator = context.coordinator
        if view.string != editor.text || coordinator.shownPage != editor.page {
            coordinator.shownPage = editor.page
            view.string = editor.text
            let length = (view.string as NSString).length
            view.setSelectedRange(NSRange(location: min(editor.cursor, length), length: 0))
        }
        DispatchQueue.main.async {
            if let window = view.window, window.firstResponder !== view {
                window.makeFirstResponder(view)
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        let editor: BookEditor
        var shownPage = -1

        init(editor: BookEditor) { self.editor = editor }

        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView, !view.hasMarkedText() else { return }
            editor.edit(view.string, cursor: view.selectedRange().location)
        }
    }
}
