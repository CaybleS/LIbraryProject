import 'package:shelfswap/notifications/notification_channel_manager.dart';

class NotificationData {
  final String title;
  final String body;
  final NotificationChannel notificationChannel;
  final String uid;
  
  NotificationData(this.title, this.body, this.notificationChannel, this.uid);
  
  Map<String, String> toJson() {
    String notificationChannelName = notificationChannel.name;
    return {
      "title": title,
      "body": body,
      "channelId": notificationChannelName,
      "uid": uid,
    };
  }
}