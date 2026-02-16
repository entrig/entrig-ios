import Foundation
import UserNotifications
import UIKit

/// Main SDK class for Entrig push notification service.
///
/// Usage:
/// ```swift
/// // Configure in AppDelegate
/// let config = EntrigConfig(apiKey: "your-api-key")
/// Entrig.configure(config: config) { success, error in
///     if success {
///         // SDK configured successfully
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
/// Entrig.setOnForegroundNotificationListener(self)
/// Entrig.setOnNotificationOpenedListener(self)
/// ```
public class Entrig: NSObject {

    /// Shared instance
    public static let shared = Entrig()

    private(set) var config: EntrigConfig?

    // Listeners
    private weak var notificationReceivedListener: OnNotificationReceivedListener?
    private weak var notificationClickListener: OnNotificationClickListener?

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Configures the Entrig SDK with the provided configuration.
    ///
    /// - Parameters:
    ///   - config: SDK configuration including API key
    ///   - callback: Optional callback for configuration result
    public static func configure(config: EntrigConfig, callback: OnInitializationCallback? = nil) {
        shared.config = config
        APNsManager.shared.configure(apiKey: config.apiKey)

        print("[EntrigSDK] SDK configured successfully")

        callback?(true, nil)
    }

    // MARK: - Registration

    /// Registers a user for push notifications.
    ///
    /// If handlePermission is enabled in config, this will automatically
    /// request notification permission before registration.
    ///
    /// - Parameters:
    ///   - userId: Unique identifier for the user
    ///   - sdk: SDK identifier (e.g., "flutter", "ios"). Defaults to "ios"
    ///   - isDebug: Whether the app is running in debug mode. Defaults to compile-time DEBUG flag
    ///   - callback: Optional callback for registration result
    public static func register(userId: String, sdk: String = "ios", isDebug: Bool? = nil, callback: OnRegistrationCallback? = nil) {
        guard let config = shared.config else {
            callback?(false, "SDK not configured. Call configure() first.")
            return
        }

        // Resolve isDebug: use parameter, fall back to compile-time DEBUG flag
        let resolvedIsDebug: Bool
        if let isDebug = isDebug {
            resolvedIsDebug = isDebug
        } else {
            #if DEBUG
            resolvedIsDebug = true
            #else
            resolvedIsDebug = false
            #endif
        }

        if config.handlePermission {
            requestPermission { granted, error in
                if let error = error {
                    callback?(false, error.localizedDescription)
                    return
                }

                if granted {
                    APNsManager.shared.registerUser(userId: userId, sdk: sdk, isDebug: resolvedIsDebug, callback: callback)
                } else {
                    callback?(false, "Notification permission not granted")
                }
            }
        } else {
            APNsManager.shared.registerUser(userId: userId, sdk: sdk, isDebug: resolvedIsDebug, callback: callback)
        }
    }

    /// Unregisters the current user from push notifications.
    ///
    /// - Parameter callback: Optional callback for unregistration result
    public static func unregister(callback: OnUnregistrationCallback? = nil) {
        guard shared.config != nil else {
            callback?(false, "SDK not configured. Call configure() first.")
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
    public static func setOnForegroundNotificationListener(_ listener: OnNotificationReceivedListener?) {
        shared.notificationReceivedListener = listener
    }

    /// Sets a listener for notification opened events.
    ///
    /// - Parameter listener: Listener to handle notification opened events
    public static func setOnNotificationOpenedListener(_ listener: OnNotificationClickListener?) {
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

        // Report "delivered" status when notification is received in foreground
        if let deliveryId = event.deliveryId {
            APNsManager.shared.reportDeliveryStatus(deliveryId: deliveryId, status: "delivered")
        }

        shared.notificationReceivedListener?.onNotificationReceived(event)
    }

    /// Returns the notification presentation options based on the SDK configuration.
    /// Use this in your UNUserNotificationCenterDelegate's willPresentNotification completion handler.
    ///
    /// - Returns: Presentation options respecting showForegroundNotification config
    public static func getPresentationOptions() -> UNNotificationPresentationOptions {
        guard let config = shared.config else {
            return []
        }

        if config.showForegroundNotification {
            return [.banner, .sound, .badge]
        } else {
            return []
        }
    }

    /// Call this from userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
    ///
    /// - Parameter response: Notification response from didReceiveNotificationResponse
    public static func didReceiveNotification(_ response: UNNotificationResponse) {
        let event = APNsManager.shared.extractNotificationEvent(from: response.notification.request.content.userInfo)

        // Report "read" status when notification is opened
        if let deliveryId = event.deliveryId {
            APNsManager.shared.reportDeliveryStatus(deliveryId: deliveryId, status: "read")
        }

        shared.notificationClickListener?.onNotificationClick(event)
    }

    // MARK: - Notification Service Extension

    /// Call this from your Notification Service Extension to report delivery status.
    /// This enables tracking when notifications are delivered even when the app is in background/killed.
    ///
    /// - Parameters:
    ///   - request: The notification request from didReceive
    ///   - apiKey: Your Entrig API key (required since extension runs in separate process)
    public static func reportDelivered(request: UNNotificationRequest, apiKey: String) {
        let userInfo = request.content.userInfo

        // Extract delivery_id from the notification payload
        guard let data = userInfo["data"] as? [String: Any],
              let deliveryId = data["delivery_id"] as? String else {
            print("[EntrigSDK] No delivery_id found in notification")
            return
        }

        // Report delivery status directly via network call
        NetworkManager.shared.reportDeliveryStatus(
            apiKey: apiKey,
            deliveryId: deliveryId,
            status: "delivered"
        ) { result in
            switch result {
            case .success:
                print("[EntrigSDK] Delivery status reported: delivered for \(deliveryId)")
            case .failure(let error):
                print("[EntrigSDK] Failed to report delivery status: \(error.localizedDescription)")
            }
        }
    }
}
