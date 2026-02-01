# Entrig iOS SDK

Native iOS SDK for [Entrig](https://entrig.com) - No-code Push Notifications for Supabase.

## Installation

### Swift Package Manager

1. In Xcode: **File → Add Package Dependencies**
2. Enter: `https://github.com/entrig/entrig-ios.git`
3. Select version and add to your project

<details>
<summary>CocoaPods (click to expand)</summary>

```ruby
pod 'Entrig', '~> 0.0.6'
```

Then run:
```bash
pod install
```
</details>

## Quick Start

### 1. Enable Push Notifications

In Xcode, select your target → **Signing & Capabilities**:
- Click **+ Capability** → **Push Notifications**
- Click **+ Capability** → **Background Modes** → Enable **Remote notifications**

### 2. Configure SDK in AppDelegate

```swift
import UIKit
import UserNotifications
import Entrig

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Configure Entrig SDK
        let config = EntrigConfig(apiKey: "your-entrig-api-key")
        Entrig.configure(config: config)

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Check for launch notification
        Entrig.checkLaunchNotification(launchOptions)

        return true
    }

    // MARK: - APNs Callbacks

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Entrig.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Entrig.didFailToRegisterForRemoteNotifications(error: error)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Entrig.willPresentNotification(notification)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Entrig.didReceiveNotification(response)
        completionHandler()
    }
}
```

### 3. Register User

```swift
// After user signs in
Entrig.register(userId: "user-123") { success, error in
    if success {
        print("User registered for push notifications")
    }
}
```

### 4. Listen for Notifications

```swift
class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for foreground notifications
        Entrig.setOnForegroundNotificationListener(self)

        // Listen for notification taps
        Entrig.setOnNotificationOpenedListener(self)
    }
}

extension MyViewController: OnNotificationReceivedListener {
    func onNotificationReceived(_ notification: NotificationEvent) {
        print("Received: \(notification.title)")
        // Access: notification.body, notification.type, notification.data
    }
}

extension MyViewController: OnNotificationClickListener {
    func onNotificationClick(_ notification: NotificationEvent) {
        print("Clicked: \(notification.title)")
        // Navigate based on notification.type or notification.data
    }
}
```

---

## Delivery Status Tracking (Optional)

Track when notifications are **delivered** (even when app is killed) and **read** (when user taps).

### Setup Notification Service Extension

<details>
<summary>Click to expand setup instructions</summary>

#### Step 1: Create Extension

1. In Xcode: **File → New → Target**
2. Select **Notification Service Extension**
3. Name it `NotificationService`
4. Click **Activate** when prompted

#### Step 2: Update Deployment Target

Select **NotificationService** target → **Build Settings** → Search "iOS Deployment Target"
- Set to match your main app's deployment target (e.g., `14.0`)

#### Step 3: Add Entrig to Extension

Select **NotificationService** target → **General** → **Frameworks and Libraries**
- Click **+** → Add `Entrig` package

#### Step 4: Update NotificationService.swift

```swift
import UserNotifications
import Entrig

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        // Report delivery status
        Entrig.reportDelivered(request: request, apiKey: "your-entrig-api-key")

        if let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
```

**⚠️ Note:** The extension runs in a separate process and cannot access the main app's API key. You must provide the API key directly in the extension.

</details>

---

## API Reference

### Configuration

```swift
let config = EntrigConfig(
    apiKey: "your-api-key",
    handlePermission: true  // Auto-request permission on register (default: true)
)
Entrig.configure(config: config)
```

### User Management

<details>
<summary>Register User</summary>

```swift
Entrig.register(userId: "user-123") { success, error in
    if success {
        print("Registered successfully")
    } else {
        print("Error: \(error ?? "Unknown")")
    }
}
```

**Parameters:**
- `userId`: Unique identifier for the user (from your Supabase auth)
- `callback`: Optional completion handler

</details>

<details>
<summary>Unregister User</summary>

```swift
Entrig.unregister { success, error in
    if success {
        print("Unregistered successfully")
    }
}
```

Call this when user signs out.

</details>

<details>
<summary>Manual Permission Request</summary>

```swift
// Disable auto-permission in config
let config = EntrigConfig(apiKey: "key", handlePermission: false)
Entrig.configure(config: config)

// Request permission manually
Entrig.requestPermission { granted, error in
    if granted {
        Entrig.register(userId: "user-123")
    }
}
```

</details>

### Notification Handling

<details>
<summary>Foreground Notifications</summary>

```swift
Entrig.setOnForegroundNotificationListener(self)

extension MyViewController: OnNotificationReceivedListener {
    func onNotificationReceived(_ notification: NotificationEvent) {
        // Called when notification arrives while app is open
        print(notification.title)
        print(notification.body)
        print(notification.type)  // Optional: custom type from Entrig
        print(notification.data)  // Optional: custom data payload
    }
}
```

</details>

<details>
<summary>Notification Tap Handling</summary>

```swift
Entrig.setOnNotificationOpenedListener(self)

extension MyViewController: OnNotificationClickListener {
    func onNotificationClick(_ notification: NotificationEvent) {
        // Called when user taps notification

        // Example: Navigate based on type
        switch notification.type {
        case "new_message":
            if let chatId = notification.data["chat_id"] as? String {
                navigateToChat(chatId)
            }
        case "new_order":
            navigateToOrders()
        default:
            break
        }
    }
}
```

</details>

<details>
<summary>Initial Notification (Cold Start)</summary>

```swift
// In viewDidLoad or when app becomes active
if let notification = Entrig.getInitialNotification() {
    // App was launched by tapping a notification
    handleNotification(notification)
}
```

**Note:** This returns `nil` after being called once to prevent duplicate handling.

</details>

### NotificationEvent Properties

```swift
public struct NotificationEvent {
    public let title: String              // Notification title
    public let body: String               // Notification body
    public let type: String?              // Custom type (e.g., "new_message")
    public let deliveryId: String?        // UUID for delivery tracking
    public let data: [String: Any]        // Custom payload data
}
```

---

## Example App

See the [Example](./Example) folder for a complete chat app demonstrating:
- User authentication with Supabase
- Push notification registration
- Foreground and background notification handling
- Deep linking based on notification type
- Notification Service Extension for delivery tracking

---

## Troubleshooting

<details>
<summary>Notifications not received</summary>

1. Check APNs certificate is uploaded to Entrig dashboard
2. Verify Bundle ID matches certificate
3. Test on physical device (simulator doesn't support push)
4. Check `didRegisterForRemoteNotificationsWithDeviceToken` is called

</details>

<details>
<summary>Extension not working (no delivery status)</summary>

1. Verify extension deployment target matches main app
2. Ensure Entrig package is added to extension target
3. Check extension Bundle ID is `com.yourapp.NotificationService`
4. Delete app and reinstall
5. Verify `mutable-content: 1` is in push payload (handled by Entrig server)

</details>

<details>
<summary>Build errors</summary>

1. Clean build: `Cmd+Shift+K`
2. Reset package cache: **File → Packages → Reset Package Caches**
3. Rebuild: `Cmd+B`

</details>

---

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

---

## Support

- **Documentation:** [https://docs.entrig.com](https://docs.entrig.com)
- **Email:** team@entrig.com
- **Website:** [https://entrig.com](https://entrig.com)

---

## License

MIT License - see [LICENSE](LICENSE) file for details
