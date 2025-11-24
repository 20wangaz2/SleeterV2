//
//  AppSleeterApp.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI
import UserNotifications
import UIKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let opts = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: opts)
            } else if let path = Bundle.main.path(forResource: "GoogleService-Info(1)", ofType: "plist"),
                      let opts = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: opts)
            }
        }
        #endif
        #if canImport(GoogleSignIn)
        let iosClient = "982360724962-273u0mnm55m1uebcf3ao4gnm72a7b747.apps.googleusercontent.com"
        var clientID: String? = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
        #if canImport(FirebaseCore)
        if clientID == nil { clientID = FirebaseApp.app()?.options.clientID }
        #endif
        let idToUse = clientID ?? iosClient
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: idToUse)
        #endif
        return true
    }
}

@main
struct AppSleeterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let notificationDelegate = NotificationDelegate()
    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    #if canImport(GoogleSignIn)
                    _ = GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
        }
    }
}
