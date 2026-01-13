import Foundation
import UserNotifications
import UIKit

internal class APNsManager: NSObject {
    static let shared = APNsManager()

    private let registrationIdKey = "entrig_registration_id"
    private let userIdKey = "entrig_user_id"

    private var pendingUserId: String?
    private var pendingSdk: String?
    private var pendingCallback: OnRegistrationCallback?
    private var apiKey: String?

    // Cached initial notification
    private var cachedInitialNotification: NotificationEvent?
    private var initialNotificationConsumed = false

    private override init() {
        super.init()
    }

    func configure(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Token Registration

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        guard let userId = pendingUserId,
              let sdk = pendingSdk,
              let apiKey = self.apiKey else {
            pendingCallback?(false, "Internal error: userId or apiKey is nil")
            clearPendingState()
            return
        }


        NetworkManager.shared.register(
            apiKey: apiKey,
            userId: userId,
            apnToken: token,
            sdk: sdk
        ) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let registrationId):
                    UserDefaults.standard.set(registrationId, forKey: self.registrationIdKey)
                    UserDefaults.standard.set(userId, forKey: self.userIdKey)
                    print("[EntrigSDK] User registered successfully. ID: \(registrationId)")
                    self.pendingCallback?(true, nil)
                case .failure(let error):
                    print("[EntrigSDK] Registration failed: \(error.localizedDescription)")
                    self.pendingCallback?(false, error.localizedDescription)
                }
                self.clearPendingState()
            }
        }
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("[EntrigSDK] Failed to register for remote notifications: \(error.localizedDescription)")
            self.pendingCallback?(false, error.localizedDescription)
            self.clearPendingState()
        }
    }

    func registerUser(userId: String, sdk: String, callback: OnRegistrationCallback?) {
        self.pendingUserId = userId
        self.pendingSdk = sdk
        self.pendingCallback = callback

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func unregister(callback: OnUnregistrationCallback?) {
        guard let registrationId = UserDefaults.standard.string(forKey: registrationIdKey),
              let apiKey = self.apiKey else {
            print("[EntrigSDK] No registration ID found")
            callback?(false, "Not registered")
            return
        }

        // Unregister from APNs
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
        }

        NetworkManager.shared.unregister(apiKey: apiKey, registrationId: registrationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    UserDefaults.standard.removeObject(forKey: self.registrationIdKey)
                    UserDefaults.standard.removeObject(forKey: self.userIdKey)
                    print("[EntrigSDK] User unregistered successfully")
                    callback?(true, nil)
                case .failure(let error):
                    print("[EntrigSDK] Unregistration failed: \(error.localizedDescription)")
                    callback?(false, error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Notification Handling

    func handleLaunchNotification(userInfo: [AnyHashable: Any]) {
        let notification = extractNotificationEvent(from: userInfo)
        cachedInitialNotification = notification
    }

    func getInitialNotification() -> NotificationEvent? {
        guard !initialNotificationConsumed, let notification = cachedInitialNotification else {
            return nil
        }

        initialNotificationConsumed = true
        cachedInitialNotification = nil
        return notification
    }

    func extractNotificationEvent(from userInfo: [AnyHashable: Any]) -> NotificationEvent {
        var title = ""
        var body = ""

        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                title = alert["title"] as? String ?? ""
                body = alert["body"] as? String ?? ""
            } else if let alertString = aps["alert"] as? String {
                body = alertString
            }
        }

        var data: [String: Any] = [:]
        var type: String?
        var deliveryId: String?

        if let dataDict = userInfo["data"] as? [String: Any] {
            data = dataDict
            type = data["type"] as? String
            deliveryId = data["delivery_id"] as? String
            data.removeValue(forKey: "type")
            data.removeValue(forKey: "delivery_id")
        }

        return NotificationEvent(title: title, body: body, type: type, deliveryId: deliveryId, data: data)
    }

    /// Reports delivery status to the server.
    ///
    /// - Parameters:
    ///   - deliveryId: UUID of the delivery record
    ///   - status: Status to report ("delivered" or "read")
    func reportDeliveryStatus(deliveryId: String, status: String) {
        guard let apiKey = self.apiKey else {
            print("[EntrigSDK] Cannot report delivery status: API key not configured")
            return
        }

        NetworkManager.shared.reportDeliveryStatus(
            apiKey: apiKey,
            deliveryId: deliveryId,
            status: status
        ) { result in
            switch result {
            case .success:
                print("[EntrigSDK] Delivery status reported: \(status) for \(deliveryId)")
            case .failure(let error):
                print("[EntrigSDK] Failed to report delivery status: \(error.localizedDescription)")
            }
        }
    }

    private func clearPendingState() {
        pendingUserId = nil
        pendingSdk = nil
        pendingCallback = nil
    }
}
