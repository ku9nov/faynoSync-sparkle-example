import Foundation

enum DeviceID {
    static let current: String = load()

    private static func load() -> String {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Config.appName, isDirectory: true)
        let file = dir.appendingPathComponent("device-id")

        if let stored = try? String(contentsOf: file, encoding: .utf8) {
            let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }

        let generated = UUID().uuidString
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? generated.write(to: file, atomically: true, encoding: .utf8)
        return generated
    }
}
