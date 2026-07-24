import Foundation

enum Config {
    private static func string(_ key: String, _ fallback: String) -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return (value?.isEmpty == false) ? value! : fallback
    }

    static var owner: String { string("FaynoSyncOwner", "admin") }
    static var appName: String { string("FaynoSyncApp", string("CFBundleName", "faynosyncSparkleExample")) }
    static var channel: String { string("FaynoSyncChannel", "nightly") }
    static var baseURL: String { string("FaynoSyncBaseURL", "http://localhost:9000") }
    static var feedBaseURL: String { string("SparkleFeedBaseURL", baseURL) }
    static var reportKey: String { string("FaynoSyncReportKey", "") }
    static var version: String { string("CFBundleShortVersionString", "0.0.0") }
    static var platform: String { "darwin" }

    static var arch: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "amd64"
        #endif
    }

    // Built at runtime so a single codebase can target different channels/arches:
    // {feedBase}/sparkle/{owner}/{app}/{platform}/{arch}/appcast.{channel}.xml
    static var appcastURL: String {
        let base = feedBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(base)/sparkle/\(owner)/\(appName)/\(platform)/\(arch)/appcast.\(channel).xml"
    }
}
