import SwiftUI
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // Configure Google Sign-In with Firebase client ID
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        // FCM delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // Forward APNS token to Firebase
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Receive FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenRefreshed"),
            object: token
        )
    }

    // Show notifications in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap — deep link to Community tab
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String, type == "new_shared_plant" {
            NotificationCenter.default.post(name: Notification.Name("OpenCommunityTab"), object: nil)
        }
        completionHandler()
    }
}

@main
struct HealthyPlantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FCMTokenRefreshed"))) { note in
                    guard let token = note.object as? String else { return }
                    Task {
                        try? await GardenerService().registerFCMToken(token)
                    }
                }
        }
    }
}
