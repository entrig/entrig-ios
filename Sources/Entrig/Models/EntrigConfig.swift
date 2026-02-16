import Foundation

/// Configuration for the Entrig SDK
public struct EntrigConfig {
    /// Your Entrig API key
    public let apiKey: String

    /// If true, SDK will automatically request notification permission on registration
    public let handlePermission: Bool

    /// If true, notifications will be displayed when app is in foreground (default: true)
    public let showForegroundNotification: Bool

    public init(
        apiKey: String,
        handlePermission: Bool = true,
        showForegroundNotification: Bool = true
    ) {
        precondition(!apiKey.isEmpty, "API key cannot be empty")
        self.apiKey = apiKey
        self.handlePermission = handlePermission
        self.showForegroundNotification = showForegroundNotification
    }
}
