import Foundation

/// Configuration for the Entrig SDK
public struct EntrigConfig {
    /// Your Entrig API key
    public let apiKey: String

    /// If true, SDK will automatically request notification permission on registration
    public let handlePermission: Bool

    public init(
        apiKey: String,
        handlePermission: Bool = true
    ) {
        precondition(!apiKey.isEmpty, "API key cannot be empty")
        self.apiKey = apiKey
        self.handlePermission = handlePermission
    }
}
