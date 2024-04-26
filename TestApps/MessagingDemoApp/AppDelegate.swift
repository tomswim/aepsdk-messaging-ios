//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
import AEPMessaging
import AEPSignal
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileCore.setLogLevel(.trace)

        let extensions = [
//            Consent.self,
            Lifecycle.self,
            Identity.self,
            AEPEdgeIdentity.Identity.self,
            Messaging.self,
            Edge.self,
            Signal.self,
            Assurance.self
        ]

        MobileCore.registerExtensions(extensions) {
            // only start lifecycle if the application is not in the background
            DispatchQueue.main.async {
                if application.applicationState != .background {
                    MobileCore.lifecycleStart(additionalContextData: nil)
                }
            }
            
            // configure
//            MobileCore.configureWith(appId: "ab2e6fae6a3f/945d83f20c1f/launch-0802c98aa73b-development") // AJO Ultimate CAN2 - PROD02 /AEPMessagingApp / Development
            MobileCore.configureWith(appId: "b5a106e2c3d5/8112ee96523c/launch-85f685936545-development") // GBR9 AJO Prime PAT / AEPMessagingHeraldApp / Development
//            MobileCore.configureWith(appId: "329eb41b1216/dbcaf0764bb0/launch-a4985feae364-development") // ajo-e2e-mobile-gbr9 / AEPMessagingHeraldApp / Development
            // set `messaging.useSandbox` to "true"  to test push notifications in debug environment (Apps signed with Development Certificate)
            #if DEBUG
                let debugConfig = ["messaging.useSandbox": true]
                MobileCore.updateConfigurationWith(configDict: debugConfig)
            #endif
            
//             Assurance.startSession(url: URL(string: "messagingdemo://?adb_validation_sessionid=b4a6b75e-a18c-44ca-b07a-dfbd219ca6fc")) // AJO Ultimate CAN2 - PROD02
            Assurance.startSession(url: URL(string: "aepmessagingheraldapp://?adb_validation_sessionid=8149aa07-ef1f-4c9d-a88a-29079b36becf")) // GBR9 AJO Prime PAT / AEPMessagingHeraldApp / Development
//            Assurance.startSession(url: URL(string: "aepmessageheraldapp://?adb_validation_sessionid=5a736674-0264-4a8e-8033-fb0f2f2d32b4")) // ajo-e2e-mobile-gbr9
        }
        
        registerForPushNotifications(application)
        return true
    }

    // MARK: - Push Notification registration methods
    func applicationWillEnterForeground(_: UIApplication) {
        MobileCore.lifecycleStart(additionalContextData: nil)
    }

    func applicationDidEnterBackground(_: UIApplication) {
        MobileCore.lifecyclePause()
    }
    
    // MARK: - Push Notification registration methods
    func registerForPushNotifications(_ application : UIApplication) {
        let center = UNUserNotificationCenter.current()
        // Ask for user permission
        center.requestAuthorization(options: [.badge, .sound, .alert]) { [weak self] granted, _ in
            guard granted else { return }
            
            center.delegate = self
                        
            self?.registerNotificationCategories()
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MobileCore.setPushIdentifier(deviceToken)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        MobileCore.setPushIdentifier(nil)
    }
    
    // MARK: - Handle Push Notification Reception
    // Delegate method that tells the app that a remote notification arrived that indicates there is data to be fetched.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the silent notifications received from AJO in here
        print("silent notification received")
        completionHandler(.noData)
    }
    

    // Delegate method to handle a notification that arrived while the app was running in the foreground.
//    func userNotificationCenter(_: UNUserNotificationCenter,
//                                willPresent _: UNNotification,
//                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        print("userNotificationCenter1")
//        completionHandler([.alert, .sound, .badge])
//    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("userNotificationCenter2")
        completionHandler([.alert, .sound, .badge])
    }


    
    // Delegate method is called when a notification is interacted with
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        Messaging.handleNotificationResponse(response)
        // Always call the completion handler when done.
        completionHandler()
    }
    
    // Register notification categories to enable different actions for notification
    func registerNotificationCategories() {
        // Define actions
        let action1 = UNNotificationAction(identifier: "foreground", title: "Foreground", options: [.foreground])
        let action2 = UNNotificationAction(identifier: "destructive", title: "Destructive", options: [.destructive])
        let action3 = UNNotificationAction(identifier: "default", title: "Default", options: [])
        
        // Define category with actions
        let category = UNNotificationCategory(identifier: "categoryId", actions: [action1, action2, action3], intentIdentifiers: [], options: [.customDismissAction])
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
