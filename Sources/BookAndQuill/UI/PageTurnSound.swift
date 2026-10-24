import AppKit

/// A short paper flick, synthesised once as an in-memory WAV.
@MainActor
enum PageTurnSound {
    private static let sound: NSSound? = NSSound(data: makeWAV())

    static func play() {
        sound?.stop()
        sound?.play()
    }

    private static func makeWAV() -> Data {
        let sampleRate = 22_050
        let count = sampleRate * 14 / 100
        var seed: UInt32 = 0xB00C
        var smoothed = 0.0
        var samples = [Int16]()
        samples.reserveCapacity(count)
        for i in 0..<count {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let noise = Double(seed >> 8) / Double(1 << 24) * 2 - 1
            smoothed += 0.35 * (noise - smoothed)
            let t = Double(i) / Double(count)
            // Two soft swishes: the page lifting, then landing.
            let envelope = 0.55 * exp(-pow((t - 0.18) / 0.09, 2)) + 0.9 * exp(-pow((t - 0.62) / 0.12, 2))
            samples.append(Int16(max(-1, min(1, smoothed * envelope)) * 20_000))
        }

        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        let byteCount = samples.count * 2
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36 + byteCount))
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1)); append(UInt32(sampleRate)); append(UInt32(sampleRate * 2))
        append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(UInt32(byteCount))
        samples.forEach { append($0) }
        return data
    }
}
