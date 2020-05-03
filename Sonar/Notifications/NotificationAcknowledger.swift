//
//  NotificationAcknowledger.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

import Logging

class NotificationAcknowledger {

    let persisting: Persisting
    let session: Session

    init(persisting: Persisting, session: Session) {
        self.persisting = persisting
        self.session = session
    }

    // Returns if we have already ack'ed the notification
    func ack(userInfo: [AnyHashable: Any]) -> Bool {
        guard
            let ackString = userInfo["acknowledgmentUrl"] as? String,
            let ackUrl = URL(string: ackString)
        else {
            // No ackUrl means there's nothing to ack
            logger.debug("asked to ack \(String(describing: userInfo["acknowledgmentUrl"])) but it doesn't look like a valid URL")
            return false
        }

        // Always send the ack
        let request = AcknowledgmentRequest(url: ackUrl)
        session.execute(request) { _ in
            // fire and forget - we don't care about the result of this call
        }

        if persisting.acknowledgmentUrls.contains(ackUrl) {
            logger.debug("Notification was already acknowledged")
            return true
        } else {
            logger.debug("Marking notification as acknowledged")
            persisting.acknowledgmentUrls = persisting.acknowledgmentUrls.union([ackUrl])
            return false
        }
    }
}

// MARK: - Logging
private let logger = Logger(label: "Notifications")
