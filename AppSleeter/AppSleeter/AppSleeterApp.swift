//
//  AppSleeterApp.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct AppSleeterApp: App {
    private let notificationDelegate = NotificationDelegate()
    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
