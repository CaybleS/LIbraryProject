import 'package:shelfswap/notifications/notification_channel_manager.dart';

class NotificationData {
  final String title;
  final String body;
  final NotificationChannel notificationChannel;
  final String uidToSendTo;
  
  NotificationData(this.title, this.body, this.notificationChannel, this.uidToSendTo);
  
  Map<String, String> toJson() {
    String notificationChannelName = notificationChannel.name;
    return {
      "title": title,
      "body": body,
      "channelId": notificationChannelName,
      "uid": uidToSendTo,
    };
  }
}