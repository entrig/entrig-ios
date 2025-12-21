# Entrig iOS SDK Example App

This example app demonstrates all features of the Entrig iOS SDK including:
- SDK initialization
- User registration/unregistration
- Notification permission handling
- Foreground notification handling
- Notification click handling
- Initial notification (cold start)

## Prerequisites

- Xcode 13.0 or later
- iOS 14.0+ device (push notifications don't work on simulator)
- CocoaPods installed
- Entrig API key from your [Entrig Dashboard](https://entrig.com)
- Apple Developer account with APNs certificate/key

## Setup Instructions

### 1. Clone the Repository

```bash
cd entrig-ios/Example
```

### 2. Install Dependencies

```bash
pod install
```

### 3. Configure Your API Key

Open `EntrigExample.xcconfig` and replace the placeholder with your actual API key:

```
ENTRIG_API_KEY = your-actual-entrig-api-key-here
```

### 4. Configure Bundle Identifier

In `EntrigExample.xcconfig`, update the bundle identifier to match your provisioning profile:

```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.EntrigExample
```

### 5. Open the Xcode Workspace

```bash
open EntrigExample.xcworkspace
```

**Important:** Always open the `.xcworkspace` file, not the `.xcodeproj` file, since we're using CocoaPods.

### 6. Configure Signing

1. In Xcode, select the `EntrigExample` project
2. Select the `EntrigExample` target
3. Go to "Signing & Capabilities"
4. Select your development team
5. Xcode will automatically manage provisioning

### 7. Enable Push Notifications Capability

1. In "Signing & Capabilities", click "+ Capability"
2. Add "Push Notifications"
3. Ensure "Remote notifications" is checked under "Background Modes"

### 8. Upload APNs Certificate to Entrig

1. Generate an APNs certificate or key in your Apple Developer account
2. Upload it to your [Entrig Dashboard](https://entrig.com)

### 9. Run on Physical Device

1. Connect your iOS device
2. Select your device in Xcode
3. Click Run (⌘R)

**Note:** Push notifications do NOT work on the iOS Simulator. You must test on a physical device.

## Testing the App

### 1. Register a User

1. Launch the app
2. You'll see a pre-filled User ID (or enter your own)
3. Tap "Register User"
4. Grant notification permission when prompted
5. Wait for the "Registration successful" message

### 2. Send a Test Notification

From your Entrig Dashboard:
1. Navigate to "Send Notification"
2. Select the registered user
3. Enter a title, body, and optional type/data
4. Send the notification

### 3. Test Different Scenarios

#### Foreground Notification
- Keep the app open and in the foreground
- Send a notification
- You'll see the notification banner and the log will update

#### Background/Click Notification
- Put the app in the background (press Home)
- Send a notification
- Tap the notification
- App will open and show the notification details

#### Cold Start Notification
- Force quit the app completely
- Send a notification
- Tap the notification to launch the app
- The "Initial Notification" will be logged

### 4. Check the Log

All notification events are logged in the "Notification Log" section:
- ✅ Registration success/failure
- 🔔 Foreground notifications
- 👆 Notification clicks
- 🚀 Initial notifications (cold start)

### 5. Unregister

Tap "Unregister User" to remove the device from receiving notifications.

## Features Demonstrated

### SDK Initialization
See `AppDelegate.swift`:
```swift
let config = EntrigConfig(apiKey: apiKey)
Entrig.initialize(config: config) { success, error in
    // Handle initialization
}
```

### User Registration
See `HomeViewController.swift`:
```swift
Entrig.register(userId: userId) { success, error in
    // Handle registration
}
```

### Permission Request
```swift
Entrig.requestPermission { granted, error in
    // Handle permission result
}
```

### Notification Listeners
```swift
extension HomeViewController: OnNotificationReceivedListener {
    func onNotificationReceived(_ notification: NotificationEvent) {
        // Handle foreground notification
    }
}

extension HomeViewController: OnNotificationClickListener {
    func onNotificationClick(_ notification: NotificationEvent) {
        // Handle notification click
    }
}
```

### Initial Notification
```swift
if let notification = Entrig.getInitialNotification() {
    // Handle cold start notification
}
```

## Project Structure

```
EntrigExample/
├── AppDelegate.swift           # App lifecycle & SDK initialization
├── HomeViewController.swift    # Main UI with all SDK features
├── Info.plist                 # App configuration
└── EntrigExample.xcconfig     # API keys and bundle ID

Podfile                        # CocoaPods dependencies
```

## Troubleshooting

### Notifications not received

1. **Check device**: Ensure you're using a physical device, not simulator
2. **Check permission**: Verify notification permission is granted in Settings
3. **Check APNs**: Ensure your APNs certificate is uploaded to Entrig
4. **Check registration**: Verify the user is registered (green status)
5. **Check logs**: Look at Xcode console for any error messages

### Registration fails

1. **Check API key**: Verify `ENTRIG_API_KEY` in `EntrigExample.xcconfig`
2. **Check network**: Ensure device has internet connectivity
3. **Check logs**: Review Xcode console for detailed error messages

### Build errors

1. **Run pod install**: Ensure CocoaPods dependencies are installed
2. **Open workspace**: Open `.xcworkspace`, not `.xcodeproj`
3. **Clean build**: Product > Clean Build Folder (⌘⇧K)

## Next Steps

Once you've tested the example app:

1. Review the source code to understand SDK integration
2. Integrate the SDK into your own app
3. Customize notification handling for your use case
4. Implement Supabase auto-registration if needed

## Support

For issues and questions:
- SDK Documentation: See main [README.md](../README.md)
- GitHub Issues: https://github.com/entrig/entrig-ios/issues
- Email: team@entrig.com
