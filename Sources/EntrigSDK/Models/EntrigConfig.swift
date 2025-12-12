import Foundation

/// Configuration for initializing the Entrig SDK
public struct EntrigConfig {
    /// Your Entrig API key
    public let apiKey: String

    /// If true, SDK will automatically request notification permission on registration
    public let handlePermissionAutomatically: Bool

    public init(
        apiKey: String,
        handlePermissionAutomatically: Bool = true
    ) {
        precondition(!apiKey.isEmpty, "API key cannot be empty")
        self.apiKey = apiKey
        self.handlePermissionAutomatically = handlePermissionAutomatically
    }
}
