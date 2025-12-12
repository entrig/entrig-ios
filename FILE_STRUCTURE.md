# Entrig iOS SDK - File Structure

\`\`\`
entrig-ios/
├── Sources/EntrigSDK/              # SDK Source Code
│   ├── Entrig.swift                   # Main SDK class
│   ├── Models/
│   │   ├── EntrigConfig.swift         # Configuration model
│   │   └── NotificationEvent.swift    # Notification event model
│   ├── Callbacks/
│   │   └── EntrigCallbacks.swift      # Listener protocols & callbacks
│   └── Internal/
│       ├── APNsManager.swift          # APNs token & notification handling
│       └── NetworkManager.swift       # API communication
│
├── Example/                        # Example App
│   ├── EntrigExample/
│   │   ├── AppDelegate.swift          # App lifecycle & SDK setup
│   │   ├── HomeViewController.swift   # Main UI with SDK demo
│   │   └── Info.plist                 # App configuration
│   ├── EntrigExample.xcodeproj/       # Xcode project
│   ├── Podfile                        # CocoaPods dependencies
│   ├── EntrigExample.xcconfig         # Configuration (API keys)
│   ├── .gitignore                     # Git ignore rules
│   └── README.md                      # Example app setup guide
│
├── Package.swift                   # Swift Package Manager manifest
├── EntrigSDK.podspec              # CocoaPods specification
├── README.md                      # Main documentation
├── QUICKSTART.md                  # Quick start guide
├── TESTING.md                     # Testing guide
├── .gitignore                     # SDK git ignore
└── LICENSE                        # License file

Total Files:
- 6 Swift source files (SDK)
- 2 Swift source files (Example)
- 5 Documentation files
- 2 Package manager files
- 2 Configuration files
\`\`\`

## Key Files Explained

### SDK Core

**Entrig.swift**
- Main SDK public API
- Initialization, registration, listeners
- Notification handling coordination

**EntrigConfig.swift**
- Configuration for SDK initialization
- API key, permissions, auto-register settings

**NotificationEvent.swift**
- Data model for notifications
- Title, body, type, and custom data

### Internal Components

**APNsManager.swift**
- APNs device token management
- Environment detection (sandbox/production)
- Notification payload parsing
- Initial notification caching

**NetworkManager.swift**
- HTTP communication with Entrig backend
- Registration/unregistration API calls
- Error handling

**EntrigCallbacks.swift**
- Listener protocols
- Callback type definitions

### Example App

**AppDelegate.swift**
- Shows SDK initialization
- Demonstrates APNs callback forwarding
- UNUserNotificationCenterDelegate implementation

**HomeViewController.swift**
- Interactive UI for testing all SDK features
- Registration/unregistration controls
- Notification log display
- Listener implementations

## Next Steps

1. **Read**: [README.md](README.md) for full documentation
2. **Quick Start**: [QUICKSTART.md](QUICKSTART.md) for basic integration
3. **Test**: [TESTING.md](TESTING.md) for testing guide
4. **Try**: [Example/](Example/) to run the example app
