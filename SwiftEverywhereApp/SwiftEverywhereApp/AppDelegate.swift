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
        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
    }


    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // Try again later.
    }

}
