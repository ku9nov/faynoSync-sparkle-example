import Foundation
import Sparkle

final class UpdaterManager: NSObject {
    enum State {
        case checking
        case upToDate
        case available(SUAppcastItem)
        case error(String)
    }

    private(set) var controller: SPUStandardUpdaterController!
    var onState: ((State) -> Void)?

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil)
    }

    func checkForUpdates() {
        onState?(.checking)
        controller.checkForUpdates(nil)
    }
}

extension UpdaterManager: SPUUpdaterDelegate {
    // Overrides SUFeedURL so the feed is composed from Config (owner/app/platform/arch/channel)
    // per build, instead of a single hardcoded channel+arch URL in Info.plist.
    func feedURLString(for updater: SPUUpdater) -> String? {
        Config.appcastURL
    }

    // The faynoSync glue: deviceId + localVersion (and the rest) are appended to the
    // SUFeedURL as query params. Against a static appcast they are ignored; against the
    // dynamic faynoSync sparkle route they drive intermediate/rollout selection.
    func feedParameters(for updater: SPUUpdater, sendingSystemProfile sendingProfile: Bool) -> [[String: String]] {
        func param(_ key: String, _ value: String) -> [String: String] {
            ["key": key, "value": value, "displayKey": key, "displayValue": value]
        }
        return [
            param("deviceId", DeviceID.current),
            param("localVersion", Config.version),
            param("id", Config.appName),
            param("channel", Config.channel),
            param("platform", Config.platform),
            param("arch", Config.arch),
        ]
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        onState?(.available(item))
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        onState?(.upToDate)
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        onState?(.error(error.localizedDescription))
    }
}
