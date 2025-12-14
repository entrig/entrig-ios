import Foundation
import UserNotifications
import UIKit

/// Main SDK class for Entrig push notification service.
///
/// Usage:
/// ```swift
/// // Initialize in AppDelegate
/// let config = EntrigConfig(apiKey: "your-api-key")
/// Entrig.initialize(config: config) { success, error in
///     if success {
///         // SDK initialized successfully
///     }
/// }
///
/// // Register a user
/// Entrig.register(userId: "user-123") { success, error in
///     if success {
///         // User registered successfully
///     }
/// }
///
/// // Listen for notifications
/// Entrig.setOnNotificationReceivedListener(self)
/// Entrig.setOnNotificationClickListener(self)
/// ```
public class Entrig: NSObject {

    /// Shared instance
    public static let shared = Entrig()

    private var config: EntrigConfig?

    // Listeners
    private weak var notificationReceivedListener: OnNotificationReceivedListener?
    private weak var notificationClickListener: OnNotificationClickListener?

    private override init() {
        super.init()
    }

    // MARK: - Initialization

    /// Initializes the Entrig SDK with the provided configuration.
    ///
    /// - Parameters:
    ///   - config: SDK configuration including API key
    ///   - callback: Optional callback for initialization result
    public static func initialize(config: EntrigConfig, callback: OnInitializationCallback? = nil) {
        shared.config = config
        APNsManager.shared.configure(apiKey: config.apiKey)

        print("[EntrigSDK] SDK initialized successfully")

        callback?(true, nil)
    }

    // MARK: - Registration

    /// Registers a user for push notifications.
    ///
    /// If handlePermissionAutomatically is enabled in config, this will automatically
    /// request notification permission before registration.
    ///
    /// - Parameters:
    ///   - userId: Unique identifier for the user
    ///   - sdk: SDK identifier (e.g., "flutter", "ios"). Defaults to "ios"
    ///   - callback: Optional callback for registration result
    public static func register(userId: String, sdk: String = "ios", callback: OnRegistrationCallback? = nil) {
        guard let config = shared.config else {
            callback?(false, "SDK not initialized. Call initialize() first.")
            return
        }

        if config.handlePermissionAutomatically {
            requestPermission { granted, error in
                if let error = error {
                    callback?(false, error.localizedDescription)
                    return
                }

                if granted {
                    APNsManager.shared.registerUser(userId: userId, sdk: sdk, callback: callback)
                } else {
                    callback?(false, "Notification permission not granted")
                }
            }
        } else {
            APNsManager.shared.registerUser(userId: userId, sdk: sdk, callback: callback)
        }
    }

    /// Unregisters the current user from push notifications.
    ///
    /// - Parameter callback: Optional callback for unregistration result
    public static func unregister(callback: OnUnregistrationCallback? = nil) {
        guard shared.config != nil else {
            callback?(false, "SDK not initialized. Call initialize() first.")
            return
        }

        APNsManager.shared.unregister(callback: callback)
    }

    // MARK: - Permission

    /// Manually request notification permission.
    ///
    /// - Parameter callback: Callback with permission result
    public static func requestPermission(callback: @escaping OnPermissionCallback) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                callback(granted, error)
            }
        }
    }

    // MARK: - Listeners

    /// Sets a listener for notifications received while app is in foreground.
    ///
    /// - Parameter listener: Listener to handle foreground notifications
    public static func setOnNotificationReceivedListener(_ listener: OnNotificationReceivedListener?) {
        shared.notificationReceivedListener = listener
    }

    /// Sets a listener for notification click events.
    ///
    /// - Parameter listener: Listener to handle notification clicks
    public static func setOnNotificationClickListener(_ listener: OnNotificationClickListener?) {
        shared.notificationClickListener = listener
    }

    // MARK: - Notification Handling

    /// Gets the initial notification if app was launched from a notification.
    /// Returns nil if already consumed or no initial notification.
    ///
    /// - Returns: The initial notification event or nil
    public static func getInitialNotification() -> NotificationEvent? {
        return APNsManager.shared.getInitialNotification()
    }

    /// Call this from application:didFinishLaunchingWithOptions: to handle cold start notifications
    ///
    /// - Parameter launchOptions: Launch options from didFinishLaunchingWithOptions
    public static func checkLaunchNotification(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] else {
            return
        }
        APNsManager.shared.handleLaunchNotification(userInfo: remoteNotification)
    }

    /// Call this from application:didRegisterForRemoteNotificationsWithDeviceToken:
    ///
    /// - Parameter deviceToken: Device token from didRegisterForRemoteNotificationsWithDeviceToken
    public static func didRegisterForRemoteNotifications(deviceToken: Data) {
        APNsManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    /// Call this from application:didFailToRegisterForRemoteNotificationsWithError:
    ///
    /// - Parameter error: Error from didFailToRegisterForRemoteNotificationsWithError
    public static func didFailToRegisterForRemoteNotifications(error: Error) {
        APNsManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }

    /// Call this from userNotificationCenter:willPresentNotification:withCompletionHandler:
    ///
    /// - Parameter notification: Notification from willPresentNotification
    public static func willPresentNotification(_ notification: UNNotification) {
        let event = APNsManager.shared.extractNotificationEvent(from: notification.request.content.userInfo)
        shared.notificationReceivedListener?.onNotificationReceived(event)
    }

    /// Call this from userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
    ///
    /// - Parameter response: Notification response from didReceiveNotificationResponse
    public static func didReceiveNotification(_ response: UNNotificationResponse) {
        let event = APNsManager.shared.extractNotificationEvent(from: response.notification.request.content.userInfo)
        shared.notificationClickListener?.onNotificationClick(event)
    }
}
