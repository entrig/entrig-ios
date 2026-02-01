//
//  NotificationService.swift
//  NotificationService
//
//  Created by ib on 13/01/26.
//

import UserNotifications
import Entrig

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("[NotificationService] didReceive called")
        print("[NotificationService] userInfo: \(request.content.userInfo)")

        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        // Report delivered status to Entrig
        let apiKey = "sk-proj-71610b55-a385841a82d6099f2133608d0631049e3863cc3e911a6674478f8a8c59c98f45"
        Entrig.reportDelivered(request: request, apiKey: apiKey)

        if let bestAttemptContent = bestAttemptContent {
            // Add marker to confirm extension ran
            bestAttemptContent.title = "\(bestAttemptContent.title) [delivered]"
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
