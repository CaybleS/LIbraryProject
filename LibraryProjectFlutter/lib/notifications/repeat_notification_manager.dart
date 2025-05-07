// What is this? My vision, is that this will track all sent notifications in-memory so that if someone tries to spam it,
// it only sends it once kinda thing. I don't know if this is optimal, I haven't rly done research on this I'm just using my brain.
// I think it cant hurt, at the very least. It's also not ideal since I'm not doing this for the scheduled notifications.
// It's fine, its just a little basic thing ig.
import 'package:shelfswap/models/notification.dart';

class RepeatNotificationManager {
  Map<NotificationData, DateTime>? sentNotifications;

  RepeatNotificationManager() {
    sentNotifications = {};
  }

  bool wasNotificationAlreadySent(NotificationData notificationData) {
    sentNotifications ??= {};
    bool notificationFound = false;
    sentNotifications!.forEach((sentNotification, dateSent) {
      if (sentNotification == notificationData) {
        bool itsBeenADaySinceWeSentThisExactNotification = dateSent.isBefore(DateTime.now().toUtc().subtract(const Duration(days: 1)));
        if (!itsBeenADaySinceWeSentThisExactNotification) {
          notificationFound = true;
          return;
        }
      }
    });
    return notificationFound;
  }
  
  // ensure this is protected by the wasNotificationAlreadySent function before you call it
  void addSentNotification(NotificationData notificationData) {
    sentNotifications ??= {};
    sentNotifications![notificationData] = DateTime.now().toUtc();
  }
}
