import Foundation

extension NotificationCenter {
    struct SendableNotification: Sendable {
        let name: Notification.Name
    }
    struct ObserverReference: @unchecked Sendable {
        let reference: NSObjectProtocol
    }

    @discardableResult
    func observeNotifications(
        from notification: Foundation.Notification.Name,
        object: Any? = nil
    ) -> AsyncStream<SendableNotification> {
        AsyncStream { continuation in
            let reference = NotificationCenter.default.addObserver(
                forName: notification,
                object: object,
                queue: nil
            ) { notif in
                // userInfo の型を具体的な型にキャスト
                let sendableNotif = SendableNotification(
                    name: notif.name
                )
                continuation.yield(sendableNotif)
            }
            let observerReference = ObserverReference(reference: reference)

            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(observerReference.reference)
            }
        }
    }
}
