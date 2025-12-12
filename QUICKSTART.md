# Entrig iOS SDK - Quick Start Guide

Get started with Entrig push notifications in your iOS app in 5 minutes.

## Installation

### CocoaPods
```ruby
pod 'EntrigSDK', '~> 1.0.0'
```

### Swift Package Manager
```
https://github.com/entrig/entrig-ios.git
```

## Basic Setup

### 1. Initialize SDK (AppDelegate.swift)

```swift
import EntrigSDK

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {

    // Initialize Entrig
    let config = EntrigConfig(apiKey: "your-api-key")
    Entrig.initialize(config: config)

    // Set delegate
    UNUserNotificationCenter.current().delegate = self

    // Check launch notification
    Entrig.checkLaunchNotification(launchOptions)

    return true
}

// Forward APNs callbacks
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
```

### 2. Handle Notifications (AppDelegate.swift)

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {

    // Foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Entrig.willPresentNotification(notification)
        completionHandler([.banner, .sound, .badge])
    }

    // Click
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
// When user signs in
Entrig.register(userId: "user-123") { success, error in
    if success {
        print("Registered!")
    }
}
```

### 4. Listen for Notifications

```swift
class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Entrig.setOnNotificationReceivedListener(self)
        Entrig.setOnNotificationClickListener(self)
    }
}

extension MyViewController: OnNotificationReceivedListener {
    func onNotificationReceived(_ notification: NotificationEvent) {
        print("Foreground: \(notification.title)")
    }
}

extension MyViewController: OnNotificationClickListener {
    func onNotificationClick(_ notification: NotificationEvent) {
        print("Clicked: \(notification.title)")
        // Navigate based on notification.type or notification.data
    }
}
```

## Xcode Configuration

### Enable Push Notifications
1. Select target → Signing & Capabilities
2. Click "+ Capability"
3. Add "Push Notifications"

### Add Background Mode
In Info.plist:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## Test the Integration

1. Run app on physical device (not simulator)
2. Register a user
3. Send test notification from Entrig dashboard
4. Verify notification is received

## Advanced Features

### Manual Permission Handling
```swift
let config = EntrigConfig(
    apiKey: "your-api-key",
    handlePermissionAutomatically: false
)

// Later, request manually
Entrig.requestPermission { granted, error in
    if granted {
        Entrig.register(userId: "user-123")
    }
}
```

### Get Initial Notification
```swift
// Check if app was launched from notification
if let notification = Entrig.getInitialNotification() {
    // Handle cold start notification
}
```

### Unregister User
```swift
// When user signs out
Entrig.unregister { success, error in
    if success {
        print("Unregistered!")
    }
}
```

## Full Example

Check out the complete example app:
- [Example App](Example/) - Full working iOS app
- [Example README](Example/README.md) - Setup instructions

## Documentation

- [Full README](README.md) - Complete documentation
- [Testing Guide](TESTING.md) - How to test the SDK
- [API Reference](README.md#api-reference) - All methods and types

## Support

- Issues: https://github.com/entrig/entrig-ios/issues
- Email: team@entrig.com
- Website: https://entrig.com
