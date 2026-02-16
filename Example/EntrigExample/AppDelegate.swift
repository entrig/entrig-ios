import UIKit
import UserNotifications
import Entrig

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize Supabase
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

        SupabaseService.shared.initialize(url: supabaseURL, anonKey: supabaseAnonKey)
        print("[EntrigExample] ✅ Supabase initialized")

        // Initialize Entrig SDK
        let entrigApiKey = ProcessInfo.processInfo.environment["ENTRIG_API_KEY"] ?? ""

        let config = EntrigConfig(
            apiKey: entrigApiKey,
            handlePermission: true,
            showForegroundNotification: false
        )

        Entrig.configure(config: config) { success, error in
            if success {
                print("[EntrigExample] ✅ Entrig SDK configured successfully")
            } else {
                print("[EntrigExample] ❌ Entrig SDK configuration failed: \(error ?? "Unknown error")")
            }
        }

        // Check for launch notification (cold start)
        Entrig.checkLaunchNotification(launchOptions)

        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Set up window and root view controller
        window = UIWindow(frame: UIScreen.main.bounds)

        // Check if user is already signed in
        let rootVC: UIViewController
        if AuthService.shared.isSignedIn {
            rootVC = UINavigationController(rootViewController: GroupsViewController())
        } else {
            rootVC = UINavigationController(rootViewController: AuthViewController())
        }

        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()

        return true
    }

    // MARK: - APNs Callbacks

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("[EntrigExample] 📱 APNs device token received")
        Entrig.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[EntrigExample] ❌ Failed to register for APNs: \(error.localizedDescription)")
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
        print("[EntrigExample] 🔔 Notification received in foreground")
        Entrig.willPresentNotification(notification)

        // Use SDK config to determine if notification should be shown
        completionHandler(Entrig.getPresentationOptions())
    }

    // Handle notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("[EntrigExample] 👆 Notification tapped")
        Entrig.didReceiveNotification(response)
        completionHandler()
    }
}
