import AppKit

/// Developer aid: `BOOKANDQUILL_SNAPSHOT=/path/out.png` saves the window as a PNG
/// shortly after launch, then quits. Used to check the UI without screen capture.
enum DebugSnapshot {
    @MainActor
    static func scheduleIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["BOOKANDQUILL_SNAPSHOT"] else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard let view = NSApp.windows.first(where: \.isVisible)?.contentView,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { exit(1) }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            NSApp.terminate(nil)
        }
    }
}
