//
//  whereaboutsApp.swift
//  whereabouts
//
//  Created by Ritam Saha on 4/17/23.
//

import SwiftUI
import Firebase
import UserNotifications
import FirebaseMessaging
import NearbyInteraction


class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var isSupported: Bool
        if #available(iOS 16.0, *) {
            isSupported = NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
        } else {
            isSupported = NISession.isSupported
        }
        // Add your existing Firebase code here
        FirebaseApp.configure()
        requestNotificationAuthorization(application: application)

        Messaging.messaging().delegate = self

        return true
    }

    
    func requestNotificationAuthorization(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("Request authorization for notifications failed with error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications with error: \(error.localizedDescription)")
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Received FCM token: \(fcmToken)")
        // Store or send the FCM token to your server as needed
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        handleRemoteNotification(userInfo: userInfo)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleRemoteNotification(userInfo: userInfo)
        completionHandler()
    }
    
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("passed")
        let appViewModel = AppViewModel.shared
        appViewModel.cancelButton = true
        appViewModel.selectedTab = 1
        if let email = userInfo["email"] as? String {
            appViewModel.drawRouteToUserByEmail(email: email)
            print(email)
            // Handle the custom data here
        }
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        // Show the notification banner
        completionHandler([.banner, .sound])
    }
}


@main
struct WhereaboutsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppViewModel.shared)
        }
    }
}
