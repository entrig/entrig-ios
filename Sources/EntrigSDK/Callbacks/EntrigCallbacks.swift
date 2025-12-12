import Foundation

/// Callback for SDK initialization
public typealias OnInitializationCallback = (Bool, String?) -> Void

/// Callback for user registration
public typealias OnRegistrationCallback = (Bool, String?) -> Void

/// Callback for user unregistration
public typealias OnUnregistrationCallback = (Bool, String?) -> Void

/// Callback for permission request
public typealias OnPermissionCallback = (Bool, Error?) -> Void

/// Listener for notifications received in foreground
public protocol OnNotificationReceivedListener: AnyObject {
    func onNotificationReceived(_ notification: NotificationEvent)
}

/// Listener for notification click events
public protocol OnNotificationClickListener: AnyObject {
    func onNotificationClick(_ notification: NotificationEvent)
}
