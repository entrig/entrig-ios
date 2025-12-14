# Entrig SDK for iOS

No-code Push Notifications for Supabase on iOS.

## Features

- 🚀 Easy integration with just a few lines of code
- 🔔 APNs push notification support
- 📱 Foreground and background notification handling
- 🎯 Initial notification support (cold start)
- ⚙️ Configurable permission handling
- 📦 Swift Package Manager and CocoaPods support

## Requirements

- iOS 14.0+
- Swift 5.0+
- Xcode 13.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/entrig/entrig-ios.git", from: "0.0.1-dev")
]
```

Or in Xcode:
1. File > Add Packages
2. Enter: `https://github.com/entrig/entrig-ios.git`
3. Select version and add to your project

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'Entrig', '~> 0.0.1-dev'
```

Then run:
```bash
pod install
```

## Setup

### 1. Enable Push Notifications

In Xcode, select your target > Signing & Capabilities > + Capability > Push Notifications

### 2. Configure APNs

Upload your APNs authentication key or certificate to your Entrig dashboard.

### 3. Update Info.plist

Add the following to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## Usage

### Basic Setup

#### 1. Initialize the SDK

In your `AppDelegate.swift`:

```swift
import UIKit
import Entrig

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize Entrig SDK
        let config = EntrigConfig(apiKey: "your-entrig-api-key")
        Entrig.initialize(config: config) { success, error in
            if success {
                print("Entrig SDK initialized successfully")
            } else {
                print("Entrig SDK initialization failed: \(error ?? "Unknown error")")
            }
        }

        // Check for launch notification (cold start)
        Entrig.checkLaunchNotification(launchOptions)

        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // Forward APNs registration to Entrig
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

    // Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Entrig.willPresentNotification(notification)
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification taps
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

#### 2. Register a User

```swift
// Register user when they sign in
Entrig.register(userId: "user-123") { success, error in
    if success {
        print("User registered successfully")
    } else {
        print("Registration failed: \(error ?? "Unknown error")")
    }
}
```

#### 3. Listen for Notifications

```swift
class MyViewController: UIViewController, OnNotificationReceivedListener, OnNotificationClickListener {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set listeners
        Entrig.setOnNotificationReceivedListener(self)
        Entrig.setOnNotificationClickListener(self)

        // Check for initial notification
        if let notification = Entrig.getInitialNotification() {
            print("App launched from notification: \(notification.title)")
        }
    }

    // Called when notification received in foreground
    func onNotificationReceived(_ notification: NotificationEvent) {
        print("Foreground notification: \(notification.title)")
        print("Body: \(notification.body)")
        print("Type: \(notification.type ?? "none")")
        print("Data: \(notification.data)")
    }

    // Called when user taps notification
    func onNotificationClick(_ notification: NotificationEvent) {
        print("Notification clicked: \(notification.title)")
        // Navigate to relevant screen based on notification.type or notification.data
    }
}
```

#### 4. Unregister User

```swift
// Unregister user when they sign out
Entrig.unregister { success, error in
    if success {
        print("User unregistered successfully")
    } else {
        print("Unregistration failed: \(error ?? "Unknown error")")
    }
}
```

### Advanced Usage

#### Manual Permission Handling

If you want to handle permission requests manually:

```swift
let config = EntrigConfig(
    apiKey: "your-api-key",
    handlePermissionAutomatically: false
)

// Later, request permission manually
Entrig.requestPermission { granted, error in
    if granted {
        print("Permission granted")
        // Now register the user
        Entrig.register(userId: "user-123")
    }
}
```

## API Reference

### Entrig

#### Methods

##### `initialize(config:callback:)`
Initialize the SDK with configuration.

**Parameters:**
- `config`: `EntrigConfig` - SDK configuration
- `callback`: `OnInitializationCallback?` - Optional completion callback

##### `register(userId:callback:)`
Register a user for push notifications.

**Parameters:**
- `userId`: `String` - Unique user identifier
- `callback`: `OnRegistrationCallback?` - Optional completion callback

##### `unregister(callback:)`
Unregister the current user.

**Parameters:**
- `callback`: `OnUnregistrationCallback?` - Optional completion callback

##### `requestPermission(callback:)`
Manually request notification permission.

**Parameters:**
- `callback`: `OnPermissionCallback` - Completion callback with result

##### `setOnNotificationReceivedListener(_:)`
Set listener for foreground notifications.

**Parameters:**
- `listener`: `OnNotificationReceivedListener?` - Notification listener

##### `setOnNotificationClickListener(_:)`
Set listener for notification clicks.

**Parameters:**
- `listener`: `OnNotificationClickListener?` - Click listener

##### `getInitialNotification()`
Get the notification that launched the app (if any).

**Returns:** `NotificationEvent?`

##### `checkLaunchNotification(_:)`
Check and cache launch notification. Call in `didFinishLaunchingWithOptions`.

**Parameters:**
- `launchOptions`: `[UIApplication.LaunchOptionsKey: Any]?`

##### `didRegisterForRemoteNotifications(deviceToken:)`
Forward APNs device token. Call in `didRegisterForRemoteNotificationsWithDeviceToken`.

**Parameters:**
- `deviceToken`: `Data`

##### `didFailToRegisterForRemoteNotifications(error:)`
Forward APNs registration error. Call in `didFailToRegisterForRemoteNotificationsWithError`.

**Parameters:**
- `error`: `Error`

##### `willPresentNotification(_:)`
Handle foreground notification. Call in `willPresent` delegate method.

**Parameters:**
- `notification`: `UNNotification`

##### `didReceiveNotification(_:)`
Handle notification click. Call in `didReceive` delegate method.

**Parameters:**
- `response`: `UNNotificationResponse`

### EntrigConfig

Configuration object for SDK initialization.

**Properties:**
- `apiKey`: `String` - Your Entrig API key (required)
- `handlePermissionAutomatically`: `Bool` - Auto-request permission on register (default: `true`)

### NotificationEvent

Represents a notification event.

**Properties:**
- `title`: `String` - Notification title
- `body`: `String` - Notification body
- `type`: `String?` - Optional notification type
- `data`: `[String: Any]` - Additional data payload

### Protocols

#### `OnNotificationReceivedListener`
```swift
protocol OnNotificationReceivedListener: AnyObject {
    func onNotificationReceived(_ notification: NotificationEvent)
}
```

#### `OnNotificationClickListener`
```swift
protocol OnNotificationClickListener: AnyObject {
    func onNotificationClick(_ notification: NotificationEvent)
}
```

## Testing

### Test on Simulator
APNs doesn't work on simulators. Use a physical device for testing.

### Test Push Notifications
1. Register a user with the SDK
2. Send a test notification from your Entrig dashboard
3. Verify the notification is received

## Troubleshooting

### Notifications not received
- Verify APNs certificate/key is uploaded to Entrig dashboard
- Check that Push Notifications capability is enabled
- Ensure app has notification permission granted
- Test on a physical device (not simulator)

### Registration fails
- Verify API key is correct
- Check network connectivity
- Review console logs for error messages

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- GitHub Issues: https://github.com/entrig/entrig-ios/issues
- Email: team@entrig.com
- Website: https://entrig.com
