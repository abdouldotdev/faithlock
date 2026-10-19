import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 16.0, *) {
      if let registrar = self.registrar(forPlugin: "ScreenTimePlugin") {
        ScreenTimePlugin.register(with: registrar)
      }
    }

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      LiveActivityBridge.register(with: controller.binaryMessenger)
    }

    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notification tap when app is in background/killed
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    NSLog("🔔 Notification tapped in AppDelegate")

    let userInfo = response.notification.request.content.userInfo
    NSLog("Notification userInfo: \(userInfo)")

    if let navigateTo = userInfo["navigate_to"] as? String,
       navigateTo == "prayer_learning" {
      NSLog("✅ Prayer notification detected - navigating via MethodChannel")

      // Get the Flutter view controller
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(name: "faithlock/notification",
                                          binaryMessenger: controller.binaryMessenger)

        // Call Flutter to navigate to prayer screen
        channel.invokeMethod("navigateToPrayer", arguments: nil)
        NSLog("📤 Sent navigation request to Flutter via MethodChannel")
      } else {
        NSLog("❌ Could not get FlutterViewController")
      }
    }

    // Still delegate to super for other notification handling
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  // Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    NSLog("🔔 Notification received while app in foreground")

    let userInfo = notification.request.content.userInfo
    NSLog("Notification userInfo: \(userInfo)")

    if let navigateTo = userInfo["navigate_to"] as? String,
       navigateTo == "prayer_learning" {
      NSLog("✅ Prayer notification - showing banner and handling navigation")
      // Show the notification banner even when app is foreground
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .sound, .badge])
      } else {
        completionHandler([.alert, .sound, .badge])
      }
      return
    }

    // For other notifications, delegate to super
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }
}
