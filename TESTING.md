# Testing the Entrig iOS SDK

This guide explains how to test the iOS SDK using the example app.

## Quick Start

### 1. Setup Example App

```bash
cd entrig-ios/Example
pod install
open EntrigExample.xcworkspace
```

### 2. Configure API Key

Edit `EntrigExample.xcconfig`:
```
ENTRIG_API_KEY = your-actual-api-key
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.EntrigExample
```

### 3. Run on Device

1. Connect iOS device (iOS 12.0+)
2. Select your device in Xcode
3. Enable Push Notifications capability
4. Run (⌘R)

## Testing Checklist

### ✅ SDK Initialization
- [ ] App launches successfully
- [ ] Console shows: "✅ Entrig SDK initialized successfully"

### ✅ User Registration
- [ ] Enter a user ID or use the generated one
- [ ] Tap "Register User"
- [ ] Grant notification permission
- [ ] See "Registration successful" alert
- [ ] Status changes to "Registered ✓"
- [ ] Console shows registration success

### ✅ Foreground Notifications
- [ ] Keep app in foreground
- [ ] Send test notification from Entrig dashboard
- [ ] Notification banner appears
- [ ] Log shows "🔔 Foreground Notification"
- [ ] Notification details logged (title, body, type, data)

### ✅ Background/Click Notifications
- [ ] Put app in background (Home button)
- [ ] Send test notification
- [ ] Tap notification in notification center
- [ ] App opens
- [ ] Log shows "👆 Notification Clicked"
- [ ] Alert dialog shows notification details

### ✅ Cold Start Notifications
- [ ] Force quit the app completely
- [ ] Send test notification
- [ ] Tap notification to launch app
- [ ] Log shows "🚀 Initial Notification (Cold Start)"
- [ ] Notification details logged

### ✅ User Unregistration
- [ ] Tap "Unregister User"
- [ ] See "Unregistration successful" alert
- [ ] Status changes to "Not Registered"
- [ ] Send notification - should NOT be received

### ✅ Manual Permission Request
- [ ] Tap "Request Permission"
- [ ] Permission dialog appears (if not already granted)
- [ ] Log shows permission result

## Common Test Scenarios

### Test with Custom Data

Send a notification with custom type and data:
```json
{
  "title": "New Message",
  "body": "You have a new message in Chat Room",
  "type": "new_message",
  "data": {
    "chat_id": "123",
    "sender": "John Doe"
  }
}
```

Verify the data is logged correctly in the app.

### Test Multiple Users

1. Register with `user-1`
2. Send notification - should receive
3. Unregister
4. Register with `user-2`
5. Send to `user-1` - should NOT receive
6. Send to `user-2` - should receive

## Debugging Tips

### Check Console Logs

Look for these prefixes in Xcode console:
- `[EntrigExample]` - App logs
- `[EntrigSDK]` - SDK logs

### Common Issues

**"Registration failed"**
- Check API key is correct
- Verify internet connection
- Check Entrig dashboard for errors

**"No notifications received"**
- Verify using physical device (not simulator)
- Check notification permission is granted
- Ensure user is registered
- Verify APNs certificate is uploaded to Entrig

**"Initial notification not captured"**
- Make sure app is completely force quit before testing
- Check `checkLaunchNotification()` is called in `didFinishLaunchingWithOptions`

## Performance Testing

### Token Registration Time
- Typical: < 2 seconds
- Check logs for timing

### Notification Latency
- Foreground: Near instant
- Background: < 1 second

### Memory Usage
- Check Xcode Instruments
- SDK should have minimal memory footprint

## Manual Testing with APNs

You can also test directly with APNs using tools like:
- [Knuff](https://github.com/KnuffApp/Knuff) (macOS)
- [Pusher](https://github.com/noodlewerk/NWPusher) (macOS)
- [Houston](https://github.com/nomad/houston) (CLI)

Use the device token logged in console.

## Automated Testing

For CI/CD, you can:
1. Mock the SDK calls
2. Test notification parsing logic
3. Verify listener callbacks
4. Test configuration validation

## Next Steps

After successful testing:
- Review implementation in `AppDelegate.swift` and `HomeViewController.swift`
- Integrate SDK into your production app
- Set up production APNs certificates
- Test in your app's context
