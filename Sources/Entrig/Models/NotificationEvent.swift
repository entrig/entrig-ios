import Foundation

/// Represents a notification event
public struct NotificationEvent {
    /// Notification title
    public let title: String

    /// Notification body
    public let body: String

    /// Optional notification type
    public let type: String?

    /// UUID of the delivery record for status tracking
    public let deliveryId: String?

    /// Additional data payload
    public let data: [String: Any]

    public init(title: String, body: String, type: String?, deliveryId: String? = nil, data: [String: Any]) {
        self.title = title
        self.body = body
        self.type = type
        self.deliveryId = deliveryId
        self.data = data
    }
}
