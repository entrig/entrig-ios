# Entrig iOS SDK

Native iOS SDK for Entrig - No-code Push Notifications for Supabase.

## Installation

### Swift Package Manager

In Xcode:
1. File > Add Packages
2. Enter: `https://github.com/entrig/entrig-ios.git`
3. Select version and add to your project

<details>
<summary>Using CocoaPods (click to expand)</summary>

Add to your `Podfile`:

```ruby
pod 'Entrig', '~> 0.0.2-dev'
```

Then run:
```bash
pod install
```

</details>

## Setup

### 1. Enable Push Notifications in Xcode

1. Select target → Signing & Capabilities
2. Click "+ Capability" → Push Notifications
3. Click "+ Capability" → Background Modes → Enable "Remote notifications"

### 2. Update AppDelegate.swift

```swift
import UIKit
import Entrig
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Entrig SDK
        let config = EntrigConfig(apiKey: "your-entrig-api-key")
        Entrig.configure(config: config)

        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Check for launch notification
        Entrig.checkLaunchNotification(launchOptions)

        return true
    }

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

## Usage

### Register User

```swift
Entrig.register(userId: "user-123")
```

<details>
<summary>Manual permission handling (click to expand)</summary>

By default, the SDK handles permissions automatically. To disable:

```swift
let config = EntrigConfig(
    apiKey: "your-api-key",
    handlePermission: false
)
Entrig.configure(config: config)
```

Then request permission manually before registering:

```swift
Entrig.requestPermission { granted, error in
    if granted {
        Entrig.register(userId: "user-123")
    }
}
```

</details>

### Listen for Notifications

```swift
class MyViewController: UIViewController, OnNotificationReceivedListener, OnNotificationClickListener {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Foreground notifications (when app is open)
        Entrig.setOnForegroundNotificationListener(self)

        // Notification opened (when user taps notification)
        Entrig.setOnNotificationOpenedListener(self)
    }

    func onNotificationReceived(_ notification: NotificationEvent) {
        // Access: notification.title, notification.body, notification.type, notification.data
    }

    func onNotificationClick(_ notification: NotificationEvent) {
        // Navigate based on notification.type or notification.data
    }
}
```

<details>
<summary>Get initial notification (click to expand)</summary>

Check if app was launched from a notification:

```swift
if let notification = Entrig.getInitialNotification() {
    // Handle cold start notification
}
```

</details>

### Unregister User

```swift
Entrig.unregister()
```

## Support

For issues, questions, or feature requests:
- Email: team@entrig.com
- Website: https://entrig.com
