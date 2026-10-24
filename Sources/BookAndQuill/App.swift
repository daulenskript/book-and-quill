import SwiftUI
import AppKit
import BookCore

enum Screen: Equatable {
    case select
    case create
    case rename(UUID)
    case confirmDelete(UUID)
    case book(UUID)
    case sign(UUID)
}

@MainActor
final class Router: ObservableObject {
    @Published var screen: Screen = .select
    @Published var selected: UUID?
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed when launched as a bare binary via `swift run`.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DebugSnapshot.scheduleIfRequested()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct BookAndQuillApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    // BOOKANDQUILL_NOTES_DIR lets you point the app at a scratch folder for testing.
    @StateObject private var store = NoteStore(directory: ProcessInfo.processInfo.environment["BOOKANDQUILL_NOTES_DIR"]
        .map { URL(fileURLWithPath: $0, isDirectory: true) } ?? NoteStore.defaultDirectory)
    @StateObject private var router = Router()

    init() {
        MC.registerFont()
    }

    var body: some Scene {
        Window("Book & Quill", id: "main") {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .frame(minWidth: 900, minHeight: 680)
                .onAppear {
                    store.load()
                    DebugSnapshot.applyInitialScreen(store: store, router: router)
                }
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            DirtBackground()
            switch router.screen {
            case .select: SelectNoteView()
            case .create: CreateNoteView()
            case .rename(let id): RenameView(id: id)
            case .confirmDelete(let id): ConfirmDeleteView(id: id)
            case .book(let id): BookScreen(id: id)
            case .sign(let id): SignView(id: id)
            }
        }
        .preferredColorScheme(.dark)
    }
}
