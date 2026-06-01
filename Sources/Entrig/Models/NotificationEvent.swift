import Foundation

/// Represents a notification event
public struct NotificationEvent {
    /// Notification title
    public let title: String

    /// Notification body
    public let body: String

    /// Optional notification type
    public let type: String?

    /// Optional deeplink URL to open on tap
    public let deeplink: String?

    /// UUID of the delivery record for status tracking
    public let deliveryId: String?

    /// Additional data payload
    public let data: [String: Any]

    public init(title: String, body: String, type: String?, deeplink: String? = nil, deliveryId: String? = nil, data: [String: Any]) {
        self.title = title
        self.body = body
        self.type = type
        self.deeplink = deeplink
        self.deliveryId = deliveryId
        self.data = data
    }
}
