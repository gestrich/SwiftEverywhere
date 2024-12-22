//
//  SwiftEverywhereAppApp.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/7/24.
//

import SwiftUI

@main
struct SwiftEverywhereAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
