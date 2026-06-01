import Foundation

/// Configuration for the Entrig SDK
public struct EntrigConfig {
    /// Your Entrig API key
    public let apiKey: String

    /// If true, SDK will automatically request notification permission on registration
    public let handlePermission: Bool

    /// If true, notifications will be displayed when app is in foreground (default: false)
    public let showForegroundNotification: Bool

    /// If true, tapping a notification with a deeplink automatically opens it.
    /// Custom URL schemes (e.g. myapp://) open directly; http/https URLs are opened
    /// with universalLinksOnly so they route to the registered app, not Safari. (default: false)
    public let autoOpenDeeplink: Bool

    public init(
        apiKey: String,
        handlePermission: Bool = true,
        showForegroundNotification: Bool = false,
        autoOpenDeeplink: Bool = false
    ) {
        if apiKey.isEmpty {
            print("[EntrigSDK] Warning: API key is empty. SDK calls will fail.")
        }
        self.apiKey = apiKey
        self.handlePermission = handlePermission
        self.showForegroundNotification = showForegroundNotification
        self.autoOpenDeeplink = autoOpenDeeplink
    }
}
