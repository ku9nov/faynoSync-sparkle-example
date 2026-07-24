import Foundation

// Mirrors the electron example's demo reporter: posts random telemetry events to
// faynoSync's /reports/ingest. Disabled unless FaynoSyncReportKey is set in Info.plist.
final class Reporter {
    private let types = ["crash", "startup_failure", "update_failure", "install_failure", "rollback_failure"]
    private let reasons = ["checksum_mismatch", "disk_full", "access_denied", "missing_dependency", "panic_nil_pointer", "signature_verification_failed"]
    private var timer: Timer?

    func start(intervalSeconds: TimeInterval = 60) {
        guard !Config.reportKey.isEmpty else { return }
        send()
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.send()
        }
    }

    private func send() {
        guard let url = URL(string: Config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/reports/ingest") else { return }

        let body: [String: Any] = [
            "application": ["name": Config.appName, "version": Config.version, "channel": Config.channel],
            "system": ["platform": Config.platform, "arch": Config.arch],
            "event": ["type": types.randomElement()!, "reason": reasons.randomElement()!],
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = data
        req.setValue("Bearer \(Config.reportKey)", forHTTPHeaderField: "Authorization")
        req.setValue(DeviceID.current, forHTTPHeaderField: "X-Device-ID")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: req).resume()
    }
}
