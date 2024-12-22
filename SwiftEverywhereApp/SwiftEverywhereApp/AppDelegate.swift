//
//  AppDelegate.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/22/24.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        
        let center = UNUserNotificationCenter.current()

        Task {
            do {
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                // Handle the error here.
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(name: Notification.Name("PUSH_NOTIFICATION_REGISTERED"), object: nil, userInfo: ["deviceToken": tokenString])
    }


    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // Try again later.
    }

}
